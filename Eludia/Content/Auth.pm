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
	
}

################################################################################

sub refresh_sessions {

	return if $_REQUEST {__suggest};

	my $time = time;

	$_REQUEST {__suggest} or sql_do_refresh_sessions ();

	__log_profilinig ($time, ' <refresh_sessions>');
	
}

################################################################################

sub get_user_sql {

	my ($users, $sessions, $roles) = map {$conf -> {systables} -> {$_}} qw (users sessions roles);

	<<EOS;
		SELECT
			$users.*
			, $roles.name AS role
			, $roles.label AS role_label
			, $sessions.ip
			, $sessions.tz_offset
			, $sessions.ip_fw
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
				
	my $user = sql_select_hash ($preconf -> {_} -> {sql} -> {get_user} ||= get_user_sql (), $_REQUEST {sid});
	
	$user -> {id} or return undef;
	
	$user -> {peer_server} = $peer_server;

	if ($user -> {ip}) {
	
		$user -> {ip}    eq $ENV {REMOTE_ADDR}          or return undef;
		$user -> {ip_fw} eq $ENV {HTTP_X_FORWARDED_FOR} or return undef;
		
	}
	else {

		sql_do (
			"UPDATE $conf->{systables}->{sessions} SET ip = ?, ip_fw = ? WHERE id = ?",
			$ENV {REMOTE_ADDR},
			$ENV {HTTP_X_FORWARDED_FOR}, $_REQUEST {sid},
		);

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