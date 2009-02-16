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

sub get_user {

	return if $_REQUEST {type} eq '_static_files';

	if ($preconf -> {core_auth_cookie}) {

		my $c = $_COOKIES {sid};

		$_REQUEST {sid} ||= $c -> value if $c;

	}

	check_auth ();

	my $time = time;
	
	$_REQUEST {__suggest} or sql_do_refresh_sessions ();

	$time = __log_profilinig ($time, ' <refresh_sessions>');

	my $user = undef;

	if ($_REQUEST {__login}) {
		$user = sql_select_hash ("SELECT * FROM $conf->{systables}->{users} WHERE login = ? AND password = PASSWORD(?) AND fake <> -1", $_REQUEST {__login}, $_REQUEST {__password});
		$user -> {id} or undef $user;
	}
	
	my $peer_server = check_peer_server ();

	$user ||= sql_select_hash (<<EOS, $_REQUEST {sid}) if $_REQUEST {sid};
		SELECT
			$conf->{systables}->{users}.*
			, $conf->{systables}->{roles}.name AS role
			, $conf->{systables}->{roles}.label AS role_label
			, $conf->{systables}->{sessions}.id_role AS session_role
			, $conf->{systables}->{sessions}.ip
			, $conf->{systables}->{sessions}.tz_offset
			, $conf->{systables}->{sessions}.ip_fw
			, $conf->{systables}->{sessions}.id_role AS session_id_role
		FROM
			$conf->{systables}->{sessions}
			, $conf->{systables}->{users}
			, $conf->{systables}->{roles}
		WHERE
			$conf->{systables}->{sessions}.id_user = $conf->{systables}->{users}.id
			AND $conf->{systables}->{users}.id_role = $conf->{systables}->{roles}.id
			AND $conf->{systables}->{sessions}.id = ?
			AND $conf->{systables}->{users}.fake <> -1
EOS

	my $session = {
		id      => $_REQUEST {sid},
		ip      => $user -> {ip},
		ip_fw   => $user -> {ip_fw},
		id_role => $user -> {session_id_role},
	};
	
	if ($session -> {ip}) {	
		$session -> {ip}    eq $ENV {REMOTE_ADDR}          or return undef;
		$session -> {ip_fw} eq $ENV {HTTP_X_FORWARDED_FOR} or return undef;	
	}	
	elsif ($user && $user -> {id}) {
	
		sql_do (
			"UPDATE $conf->{systables}->{sessions} SET ip = ?, ip_fw = ? WHERE id = ?",
			$ENV {REMOTE_ADDR},
			$ENV {HTTP_X_FORWARDED_FOR}, $_REQUEST {sid},
		);
		
	}
	
	if ($user && $user -> {id} && $session -> {id_role}) {
		$user -> {session_role_name} = sql_select_scalar ("SELECT name FROM $conf->{systables}->{sessions}, $conf->{systables}->{roles} WHERE $conf->{systables}->{sessions}.id_role = $conf->{systables}->{roles}.id AND $conf->{systables}->{sessions}.id = ?", $_REQUEST {sid});
	}

	if ($user && $user -> {session_role}) {
		$user -> {id_role} = $user -> {session_role};
		$user -> {role} = $user -> {session_role_name};
	}

	$user -> {label} ||= $user -> {name} if $user;
	
	$user -> {peer_server} = $peer_server;
		
	return $user -> {id} ? $user : undef;

}

1;