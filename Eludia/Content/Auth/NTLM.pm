#################################################################################

sub _ntlm_kick {

	$r -> status (401);
	$r -> content_type ('text/html');
	$r -> headers_out -> {'WWW-Authenticate'} = $_[0] || 'NTLM TlRMTVNTUAACAAAACAAIADgAAAAFgomiPB7NizwMPWsAAAAAAAAAACAAIABAAAAABQEoCgAAAA9MAEQAQQBQAAIACABMAEQAQQBQAAEABABEAE8AAwAEAGQAbwAAAAAA';
	$r -> send_http_header unless (MP2);
	print (' ' x 4096);
	$_REQUEST {__response_sent} = 1;

}

#################################################################################

sub _ntlm_check_auth {
	
	return if $_REQUEST {sid};
	return if !$preconf -> {ldap};
	return if  $preconf -> {ldap} -> {ntlm} ne 'samba';
		
	my $authorization = $r -> headers_in -> {'Authorization'} or return _ntlm_kick ('NTLM');
		
	require Authen::NTLM::Tools;
	
	my $m = Authen::NTLM::Tools::parse_ntlm_message ($authorization);
	
	return _ntlm_kick () if $m -> {type} == 1;
	
	$m -> {type} == 3 or die "Incorrect Authorization header: '$authorization' (type 1 or 3 message awaited)\n";

warn Dumper ($m);
	
	require Net::LDAP;
	
	my $ldap = Net::LDAP -> new ($preconf -> {ldap} -> {host}) or die "$@";

	my $mesg = $ldap -> bind ($preconf -> {ldap} -> {user}, password => $preconf -> {ldap} -> {password});

	$mesg -> code && die $mesg -> error;
	
	my $filter = "(&$preconf->{ldap}->{filter}(uid=$m->{user}->{data_oem}))";
	
	$ENV {REMOTE_USER} = $m -> {user} -> {data_oem};

warn "NTLM user is '$m->{user}->{data_oem}'\n";

	$mesg = $ldap -> search (
		base   => $preconf -> {ldap} -> {base},
		filter => $filter,
	);
	
	$mesg -> code && die $mesg -> error;
	
	require Text::Iconv;
	
	my $converter = Text::Iconv -> new ("utf-8", "windows-1251");
	
	my $id_user;
	my $sambaNTPassword;

	foreach my $entry ($mesg -> entries) {

		my $label = $converter -> convert ($entry -> get_value ('displayName') || '');
		
		$sambaNTPassword = $entry -> get_value ('sambaNTPassword');

		my ($f, $i, $o) = split /\s+/, $label;

		$f =~ /[À-ß¨]/ or next;

		$id_user ||= sql_select_id (users => {
			-fake  => 0,
			login => ($entry -> get_value ('uid') || ''),
			-label => $label,
		}, ['login']);

	}

	
	$id_user or return _ntlm_kick ();

warn "NTLM \$id_user = $id_user\n";
	
	$sambaNTPassword =~ /^[0-9A-F]{32}$/ or die "Incorrect sambaNTPassword for $m->{user}->{data_oem} ($sambaNTPassword)\n";

warn "NTLM \$sambaNTPassword = $sambaNTPassword\n";
	
	Authen::NTLM::Tools::_ntlm_check (
		Authen::NTLM::Tools::_hex_2_bin ('3c1ecd8b3c0c3d6b'),
		$authorization,
		Authen::NTLM::Tools::_hex_2_bin ($sambaNTPassword),
	) or return _ntlm_kick ('NTLM');
	
	sql_do ("DELETE FROM $conf->{systables}->{sessions} WHERE id_user = ?", $id_user);
	
	$_REQUEST {sid} = int (rand() * time ()) . int (rand() * time ());

warn Dumper ($_REQUEST {sid});
	
	sql_do ("INSERT INTO $conf->{systables}->{sessions} (ts, id, id_user) VALUES (NOW(), ?, ?)", $_REQUEST {sid}, $id_user);
		
}