no warnings;

################################################################################

sub start_session {

	my ($id_user) = @_;
	
	$id_user or die 'No user id passed to start_session';
	
	my $client_cookie = Digest::MD5::md5_hex (rand () * $id_user) . Digest::MD5::md5_hex (rand () * $$);

	if ($DB_MODEL -> {tables} -> {$conf -> {systables} -> {sessions}} -> {columns}) {

		delete_all_expired_sessions ();

		$_REQUEST {sid} = sql_do_insert ($conf -> {systables} -> {sessions} => {
			client_cookie => $client_cookie,
			id_user       => $id_user,
			fake          => 0,
			ts            => dt_iso (30 + time),
		});

	}
	else {

		$_REQUEST {sid} = $id_user;

	}
	
	if (my $mc = $preconf -> {auth} -> {sessions} -> {memcached}) {
	
		my @arg = (

			$client_cookie, 
			
			{
				id      => $_REQUEST {sid},
				id_user => $id_user,
			}, 
			
			5 + 60 * $preconf -> {auth} -> {sessions} -> {timeout}

		);

		my $r = $mc -> {connection} -> add (@arg);
				
		$r or die "Cache::Memcached::Fast::add returned: '$r' for " . Dumper (\@arg);
	
	}
	
	my $c = $preconf -> {auth} -> {sessions} -> {cookie};

	set_cookie (
		-name => $c -> {name}, 
		-value => $client_cookie, 
		-httponly => 1, 
		-path => $c -> {path},
	);

}

################################################################################

sub get_max_expired_session_dt {
	
	return dt_iso (int time - 60 * $preconf -> {auth} -> {sessions} -> {timeout});

}

################################################################################

sub delete_all_expired_sessions {
	
	sql_do ("DELETE FROM $conf->{systables}->{sessions} WHERE ts < ?", get_max_expired_session_dt ());

}

################################################################################

sub get_session {

	my $c = $_COOKIES {$preconf -> {auth} -> {sessions} -> {cookie} -> {name}} or return undef;

	my $s;

	if (my $mc = $preconf -> {auth} -> {sessions} -> {memcached}) {

		my $s = $mc -> {connection} -> get ($c -> value);

		$_REQUEST {sid} = $s -> {id} or return undef;

		if (

			$DB_MODEL -> {tables} -> {$conf -> {systables} -> {sessions}} -> {columns}
			
			&& !sql_select_scalar ("SELECT id FROM $conf->{systables}->{sessions} WHERE id = ?", $s -> {id})
			
		) {

			$mc -> {connection} -> delete ($c -> value);
			
			return undef;

		}		
		
		my @a = ($c -> value, $s, 5 + 60 * $preconf -> {auth} -> {sessions} -> {timeout});

		$mc -> {connection} -> set (@a);

		return $s;		
		
	}
	elsif ($DB_MODEL -> {tables} -> {$conf -> {systables} -> {sessions}} -> {columns}) {

		while (1) {

			$s = sql_select_hash ("SELECT * FROM $conf->{systables}->{sessions} WHERE client_cookie = ?", $c -> value);

			$s -> {id} or return undef;

			last if $s -> {ts} gt get_max_expired_session_dt ();

			delete_all_expired_sessions ();

		}

		my $now = int time;

		$s -> {ts} ge dt_iso ($now) or sql_do ("UPDATE $conf->{systables}->{sessions} SET ts = ? WHERE id = ?", dt_iso ($now + 30), $s -> {id});

		$_REQUEST {sid} = $s -> {id};

		return $s;

	}
	
	die "No session storage method defined.\n";

}

################################################################################

sub get_user {
	
	my $s = get_session () or return undef;

	my $user = sql_select_hash ("SELECT * FROM $conf->{systables}->{users} WHERE id = ?", $s -> {id_user});
	
	delete $user -> {password};

	return $user -> {id} ? $user : undef;

}

1;