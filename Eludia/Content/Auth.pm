no warnings;

################################################################################

sub start_session {

	my ($id_user) = @_;

	sql_do ("DELETE FROM $conf->{systables}->{sessions} WHERE id_user = ?", $id_user);

	while (1) {

		$_REQUEST {sid} = int (rand () * time ()) . int (rand () * time ());
		
		sql_select_scalar ("SELECT id FROM $conf->{systables}->{sessions} WHERE id = ?", $_REQUEST {sid}) or last;
		
	}

	sql_do ("INSERT INTO $conf->{systables}->{sessions} (ts, id, id_user) VALUES (NOW(), ?, ?)", $_REQUEST {sid}, $id_user);
	
	session_access_logs_purge ();

}

################################################################################

sub get_user_sql {

	my ($users, $sessions, $roles) = map {$conf -> {systables} -> {$_}} qw (users sessions roles);
	
	my @session_fields = qw (ip ip_fw client_cookie);
	
	push @session_fields, 'tz_offset' if $preconf -> {core_fix_tz};
	
	my $ohter_select = '';
	my $ohter_join   = '';
	
	$ohter_select .= ", $sessions.$_" foreach @session_fields;
	
	if ($conf -> {core_delegation}) {
	
		$ohter_select .= ', users__real.id AS id__real, users__real.label AS label__real';
	
		$ohter_join   .= "LEFT JOIN $users users__real ON $sessions.id_user_real = users__real.id";
	
	}

	<<EOS;
		SELECT
			$users.*
			, $roles.name AS role
			, $roles.label AS role_label
			$ohter_select
		FROM
			$sessions
			LEFT JOIN $users ON (
				$sessions.id_user = $users.id
				AND $users.fake <> -1
			)
			LEFT JOIN $roles ON $users.id_role = $roles.id
			$ohter_join
		WHERE
			$sessions.id = ?
EOS

}

################################################################################

sub get_opened_session {

	return undef
		if $preconf -> {core_no_cookie_check} || !$_REQUEST {id};


	my $sql = "SELECT id FROM $conf->{systables}->{sessions} WHERE client_cookie = ?";
	my @params = ($_COOKIE {client_cookie});

	my $st = ($SQL_VERSION -> {_} -> {st_select_user_session} ||= $db -> prepare_cached ($sql, {}, 3));
	$st -> execute (@params);
	my @result = $st -> fetchrow_array ();
	$st -> finish;

	my $sid = $result [0];

	return $sid;
}

################################################################################

sub get_user_with_fixed_session {

	my ($peer_server) = @_;
	

#	__profile_in ('auth.get_user'); 

	unless ($_REQUEST {__suggest}) {

#		__profile_in ('auth.refresh_sessions'); 
		
		sql_do_refresh_sessions ();

#		__profile_out ('auth.refresh_sessions'); 

	}

	if (!$peer_server) {
		$_REQUEST {sid} ||= get_opened_session ();
	}

	$_REQUEST {sid} or return undef;

	my $st = ($SQL_VERSION -> {_} -> {st_select_user} ||= $db -> prepare_cached (get_user_sql (), {}, 3));
	
	$st -> execute ($_REQUEST {sid});
	
	my ($user) = $st -> fetchrow_hashref;
	
	$st -> finish;
	
	lc_hashref ($user);

#	__profile_out ('auth.get_user', {label => "$user->{id} ($user->{label})"});
	
	$user -> {id} or return undef;
	
	$user -> {peer_server} = $peer_server;
	
	if (!$preconf -> {core_no_cookie_check} && !$peer_server) {
		
		$_COOKIE {client_cookie} or return undef;

		if ($user -> {client_cookie}) {

			$user -> {client_cookie} eq $_COOKIE {client_cookie} or return undef;

		}
	
	}
	
	if ($user -> {ip} && !$preconf -> {core_no_ip_check}) {
	
		$user -> {ip}    eq $ENV {REMOTE_ADDR}          or return undef;
		$user -> {ip_fw} eq $ENV {HTTP_X_FORWARDED_FOR} or return undef;
		
	}

	return $user;

}

################################################################################

sub get_user {

	eval { foreach (@{$preconf -> {_} -> {pre_auth}}) {&$_ ()} }; warn $@ if $@;
	
	my $user = get_user_with_fixed_session (check_peer_server ());
	
	defined $user and $user -> {id} or delete $_REQUEST {sid};

	foreach (@{$preconf -> {_} -> {post_auth}}) {&$_ ()};
	
	return $user;

}

1;