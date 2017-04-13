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
	
	set_cookie (-name => 'sid', -value => $sid, -httponly => 1, -path => '/_back');

}

################################################################################

sub get_auth_cookie_name {

	$preconf -> {auth_cookie_name} || $conf -> {auth_cookie_name} || 'sid';

}

################################################################################

sub get_user {

	my $c = $_COOKIES {get_auth_cookie_name ()} or return undef;
	
	my $s = sql_select_hash ('SELECT * FROM sessions WHERE client_cookie = ?', $c -> value);

	$_REQUEST {sid} = $s -> {id} or return undef;

	sql_do_refresh_sessions ();

	my $user = sql_select_hash ('SELECT * FROM users WHERE id = ?', $s -> {id_user});

	return $user -> {id} ? $user : undef;

}

1;