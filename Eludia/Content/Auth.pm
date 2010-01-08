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

sub refresh_sessions {

	return if $_REQUEST {__suggest};

	my $time = time;

	sql_do_refresh_sessions ();

	__log_profilinig ($time, ' <refresh_sessions>');
	
}

################################################################################

sub get_user_sql {

	my ($users, $sessions, $roles) = map {$conf -> {systables} -> {$_}} qw (users sessions roles);
	
	my @session_fields = qw (ip ip_fw client_cookie);
	
	push @session_fields, 'tz_offset' if $preconf -> {core_fix_tz};

	<<EOS;
		SELECT
			$users.*
			, $roles.name AS role
			, $roles.label AS role_label
			@{[ map {', ' . $sessions . '.' . $_} @session_fields]}
		FROM
			$sessions
			LEFT JOIN $users ON (
				$sessions.id_user = $users.id
				AND $users.fake <> -1
			)
			LEFT JOIN $roles ON $users.id_role = $roles.id
		WHERE
			$sessions.id = ?
EOS

}

################################################################################

sub get_user_with_fixed_session {

	my ($peer_server) = @_;
	
	$_REQUEST {sid} or return undef;

	my $time = time ();				

	my $user = sql_select_hash ($preconf -> {_} -> {sql} -> {get_user} ||= get_user_sql (), $_REQUEST {sid});

	__log_profilinig ($time, ' <get_user>');
	
	$user -> {id} or return undef;
	
	$user -> {peer_server} = $peer_server;
	
	if (!$preconf -> {core_no_cookie_check} && !$peer_server) {
		
		$_COOKIE {client_cookie} or return undef;

		if ($user -> {client_cookie}) {

			$user -> {client_cookie} eq $_COOKIE {client_cookie} or return undef;

		}
	
	}
	
	if ($user -> {ip}) {
	
		$user -> {ip}    eq $ENV {REMOTE_ADDR}          or return undef;
		$user -> {ip_fw} eq $ENV {HTTP_X_FORWARDED_FOR} or return undef;
		
	}

	return $user;

}

################################################################################

sub get_user {
	
	refresh_sessions ();

	foreach (@{$preconf -> {_} -> {pre_auth}}) {&$_ ()};
	
	my $user = get_user_with_fixed_session (check_peer_server ());
	
	defined $user and $user -> {id} or delete $_REQUEST {sid};

	foreach (@{$preconf -> {_} -> {post_auth}}) {&$_ ()};
	
	return $user;

}

1;