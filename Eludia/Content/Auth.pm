no warnings;

################################################################################

sub start_session {

	my ($id_user) = @_;

	sql_do ("DELETE FROM $conf->{systables}->{sessions} WHERE id_user = ?", $id_user);

	while (1) {

		$_REQUEST {sid} = substr (int (rand () * time ()) . int (rand () * time ()), 0, 18);
		
		sql_select_scalar ("SELECT id FROM $conf->{systables}->{sessions} WHERE id = ?", $_REQUEST {sid}) or last;
		
	}

	sql_do ("INSERT INTO $conf->{systables}->{sessions} (ts, id, id_user) VALUES (NOW(), ?, ?)", $_REQUEST {sid}, $id_user);

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

sub get_user_with_fixed_session {
	
	$_REQUEST {sid} or return undef;

	unless ($_REQUEST {__suggest}) {
		
		sql_do_refresh_sessions ();

	}
	
	my $st = ($SQL_VERSION -> {_} -> {st_select_user} ||= $db -> prepare_cached (get_user_sql (), {}, 3));
	
	$st -> execute ($_REQUEST {sid});
	
	my ($user) = $st -> fetchrow_hashref;
	
	$st -> finish;
	
	lc_hashref ($user);
	
	$user -> {id} or return undef;
		
	if (!$preconf -> {core_no_cookie_check}) {
		
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
	
	my $user = get_user_with_fixed_session ();
	
	defined $user and $user -> {id} or delete $_REQUEST {sid};

	foreach (@{$preconf -> {_} -> {post_auth}}) {&$_ ()};
	
	return $user;

}

1;