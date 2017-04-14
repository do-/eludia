no warnings;

################################################################################

sub start_session {

	my ($id_user) = @_;
	
	$id_user or die 'No user id passed to start_session';
	
	my $sid;
	
	while (1) {

		$sid = Digest::MD5::md5_hex (rand () * $id_user) . Digest::MD5::md5_hex (rand () * $$);
		
		sql_select_scalar ("SELECT id FROM $conf->{systables}->{sessions} WHERE client_cookie = ?", $sid) or last;
		
	}		

	delete_all_expired_sessions ($old);

	$_REQUEST {sid} = sql_do_insert ($conf -> {systables} -> {sessions} => {
		client_cookie => $sid,
		id_user       => $id_user,
		fake          => 0,
		ts            => dt_iso (30 + time),
	});
	
	set_cookie (
		-name => $preconf -> {auth} -> {cookie_name}, 
		-value => $sid, 
		-httponly => 1, 
		-path => '/_back'
	);		

}

################################################################################

sub get_max_expired_session_dt {
	
	return dt_iso (int time - 60 * $preconf -> {auth} -> {session_timeout});

}

################################################################################

sub delete_all_expired_sessions {
	
	sql_do ("DELETE FROM $conf->{systables}->{sessions} WHERE ts < ?", get_max_expired_session_dt ());

}

################################################################################

sub get_session {

	my $c = $_COOKIES {$preconf -> {auth} -> {cookie_name}} or return undef;
	
	my $s;
		
	while (1) {
	
		$s = sql_select_hash ("SELECT * FROM $conf->{systables}->{sessions} WHERE client_cookie = ?", $c -> value);
		
		$s -> {id} or return undef;
		
		last if $s -> {ts} gt get_max_expired_session_dt ();
		
		delete_all_expired_sessions ($old);

	}
	
	my $now = int time;
	
	$s -> {ts} ge dt_iso ($now) or sql_do ("UPDATE $conf->{systables}->{sessions} SET ts = ? WHERE id = ?", dt_iso ($now + 30), $s -> {id});

	$_REQUEST {sid} = $s -> {id};
	
	return $s;

}

################################################################################

sub get_user {
	
	my $s = get_session () or return undef;

	my $user = sql_select_hash ("SELECT * FROM $conf->{systables}->{users} WHERE id = ?", $s -> {id_user});
	
	delete $user -> {password};

	return $user -> {id} ? $user : undef;

}

1;