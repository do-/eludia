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

	$_REQUEST {sid} = sql_do_insert ($conf -> {systables} -> {sessions} => {
		client_cookie => $sid,
		id_user       => $id_user,
		fake          => 0,
	});
	
	set_cookie (-name => 'sid', -value => $sid, -httponly => 1, -path => '/_data');

}

################################################################################

sub get_user_sql {

	my ($users, $sessions, $roles) = map {$conf -> {systables} -> {$_}} qw (users sessions roles);
	
	my @session_fields = qw (ip ip_fw);
	
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

sub get_user {
	
	$_REQUEST {sid} or return undef;
		
	sql_do_refresh_sessions ();
	
	my $st = ($SQL_VERSION -> {_} -> {st_select_user} ||= $db -> prepare_cached (get_user_sql (), {}, 3));
	
	$st -> execute ($_REQUEST {sid});
	
	my ($user) = $st -> fetchrow_hashref;
	
	$st -> finish;
	
	lc_hashref ($user);
	
	return $user -> {id} ? $user : undef;

}

1;