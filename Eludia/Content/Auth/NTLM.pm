#################################################################################

sub check_auth {
	
	return if $_REQUEST {sid};
	return if !$preconf -> {ldap};
	return if  $preconf -> {ldap} -> {ntlm} ne 'samba';
		
	my $authorization = $r -> headers_in -> {'Authorization'} or return _ntlm_kick ('NTLM');
			
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
	
	start_session ();
	
	sql_do ("INSERT INTO $conf->{systables}->{sessions} (ts, id, id_user) VALUES (NOW(), ?, ?)", $_REQUEST {sid}, $id_user);
		
}

#################################################################################

sub _ntlm_kick {

	$r -> status (401);
	$r -> content_type ('text/html');
	$r -> headers_out -> {'WWW-Authenticate'} = $_[0] || 'NTLM TlRMTVNTUAACAAAACAAIADgAAAAFgomiPB7NizwMPWsAAAAAAAAAACAAIABAAAAABQEoCgAAAA9MAEQAQQBQAAIACABMAEQAQQBQAAEABABEAE8AAwAEAGQAbwAAAAAA';
	$r -> send_http_header unless (MP2);
	print (' ' x 4096);
	$_REQUEST {__response_sent} = 1;

}

package Authen::NTLM::Tools;

use MIME::Base64;
use Unicode::String;
use Digest::MD5 qw (md5);
use Digest::HMAC_MD5 qw (hmac_md5);
use Digest::MD4;
use Crypt::DES;
use Math::BigInt;

no strict;

################################################################################

sub _bin_2_hex { return unpack ('H*', $_[0]) }

################################################################################

sub _hex_2_bin { return   pack ('H*', $_[0]) }

################################################################################

sub _ntlm_7_to_8 {

	my $bits = unpack ('B56', $_[0]);
	
	my $bits8 = '';
	
	foreach my $i (0 .. 7) {
	
		my $b = substr ($bits, 7 * $i, 7);
		
		$bits8 .= $b;
		
		$bits8 .= 1 - ($b =~ y/1/1/) % 2;
	
	}
	
	return pack ('B64', $bits8);

}

################################################################################

sub parse_ntlm_message {
	
	$_[0] =~ /TlRMTVNTUAA([BCD])[A-Za-z0-9\=\+\/]*/ or die "Invalid NTLM message: '$_[0]'";
	
	my $type = ord ($1) - ord ('A');
	
	return &{"parse_ntlm_message_$type"} (decode_base64 ($&));

}

################################################################################

sub parse_ntlm_message_flags {

	my ($data) = @_;

	my $mask = 1;
	
	foreach my $flag (
		'Negotiate Unicode',
		'Negotiate OEM',
		'Request Target',
		'unknown 1',
		'Negotiate Sign',
		'Negotiate Seal',
		'Negotiate Datagram Style',
		'Negotiate Lan Manager Key',
		'Negotiate Netware',
		'Negotiate NTLM',
		'unknown 2',
		'Negotiate Anonymous',
		'Negotiate Domain Supplied',
		'Negotiate Workstation Supplied',
		'Negotiate Local Call',
		'Negotiate Always Sign',
		'Target Type Domain',
		'Target Type Server',
		'Target Type Share',
		'Negotiate NTLM2 Key',
		'Request Init Response',
		'Request Accept Response',
		'Request Non-NT Session Key',
		'Negotiate Target Info',
		'unknown 3',
		'unknown 4',
		'unknown 5',
		'unknown 6',
		'unknown 7',
		'Negotiate 128',
		'Negotiate Key Exchange',
		'Negotiate 56',
	) {
	
		$data -> {flag} -> {$flag} = 1 if $data -> {flags} & $mask;		
		$mask = $mask << 1;
	
	}

}

################################################################################

sub parse_ntlm_message_buffers {

	my ($data) = @_;

	foreach my $buffer (keys %{$data -> {buffers}}) {
		
		$data -> {$buffer} -> {data} = substr ($data -> {src}, $data -> {$buffer} -> {offset}, $data -> {$buffer} -> {length}); 
		
		$data -> {$buffer} -> {data_hex} = _bin_2_hex ($data -> {$buffer} -> {data});
		
	}

	if ($data -> {flag} -> {'Negotiate Unicode'}) {

		foreach my $buffer (keys %{$data -> {buffers}}) {
		
			$data -> {buffers} -> {$buffer} or next;

			$data -> {$buffer} -> {data_oem} = Unicode::String::utf16 ($data -> {$buffer} -> {data}) -> byteswap -> as_string; 

		}
	
	}
	
	delete $data -> {buffers};
	
}	

################################################################################

sub parse_ntlm_message_1 {

	my $data = {src => $_[0], buffers => {
		domain      => 1,
		workstation => 1,
	}};

	(
		$data -> {signature}, 
		$data -> {type},
		$data -> {flags},
		$data -> {domain} -> {length},
		$data -> {domain} -> {allocated},
		$data -> {domain} -> {offset},
		$data -> {workstation} -> {length},
		$data -> {workstation} -> {allocated},
		$data -> {workstation} -> {offset},
		$data -> {os} -> {major},
		$data -> {os} -> {minor},
		$data -> {os} -> {build},
				
	) = unpack 'Z8VVvvVvvVCCS', $_[0];
	
	parse_ntlm_message_flags   ($data);
	parse_ntlm_message_buffers ($data);
	
	$data -> {src} = _bin_2_hex ($data -> {src});

	return $data;

}

################################################################################

sub parse_ntlm_message_2 {

	my $data = {src => $_[0], buffers => {
		target_name        => 1,
		target_information => 0,
	}};

	(
		$data -> {signature}, 
		$data -> {type},
		$data -> {target_name} -> {length},
		$data -> {target_name} -> {allocated},
		$data -> {target_name} -> {offset},
		$data -> {flags},
		$data -> {challenge},
		$data -> {context},
		$data -> {target_information} -> {length},
		$data -> {target_information} -> {allocated},
		$data -> {target_information} -> {offset},
				
	) = unpack 'Z8VvvVVa8a8vvV', $_[0];
	
	parse_ntlm_message_flags   ($data);
	parse_ntlm_message_buffers ($data);
	
	$data -> {src} = _bin_2_hex ($data -> {src});

	return $data;

}

################################################################################

sub parse_ntlm_message_3 {

	my $data = {src => $_[0], buffers => {
		lm          => 0,
		ntlm        => 0,
		target      => 1,
		user        => 1,
		workstation => 1,
		session     => 1,
	}};
	
	(
		$data -> {signature}, 
		$data -> {type},
		$data -> {lm} -> {length},
		$data -> {lm} -> {allocated},
		$data -> {lm} -> {offset},
		$data -> {ntlm} -> {length},
		$data -> {ntlm} -> {allocated},
		$data -> {ntlm} -> {offset},
		$data -> {target} -> {length},
		$data -> {target} -> {allocated},
		$data -> {target} -> {offset},
		$data -> {user} -> {length},
		$data -> {user} -> {allocated},
		$data -> {user} -> {offset},
		$data -> {workstation} -> {length},
		$data -> {workstation} -> {allocated},
		$data -> {workstation} -> {offset},
		$data -> {session} -> {length},
		$data -> {session} -> {allocated},
		$data -> {session} -> {offset},
		$data -> {flags},
				
	) = unpack 'Z8VvvVvvVvvVvvVvvVvvVVV', $_[0];
	
	parse_ntlm_message_flags   ($data);
	parse_ntlm_message_buffers ($data);
	
	$data -> {is_ntlm2_session_response} = $data -> {lm} -> {data} =~ /\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0$/ ? 1 : 0;

	if ($data -> {is_ntlm2_session_response}) {
	
		$data -> {lm} -> {client_nonce} = substr ($data -> {lm} -> {data}, 0, 8);
		
	}
	else {
		$data -> {ntlm} -> {md5}  = substr $data -> {ntlm} -> {data}, 0, 16;
		$data -> {ntlm} -> {blob} = substr $data -> {ntlm} -> {data}, 16;	
	}
	
	$data -> {src} = _bin_2_hex ($data -> {src});

	return $data;

}

################################################################################

sub _ntlm_hash {

	my ($password) = @_;
	
	my $md4 = new Digest::MD4;
	
	foreach (split //, $password) {
		$md4 -> add ("$_\0");
	}

	$md4 -> digest;

}

################################################################################

sub _ntlm_v2_hash {

	my ($target, $user, $ntlm_hash) = @_;
	
	my $result = '';
	
	foreach (split //, uc ($user) . $target) {
		
		$result .= "$_\0";
		
	}
	
	return hmac_md5 ($result, $ntlm_hash);

}

################################################################################

sub _ntlm_check_v2 {

	my ($challenge, $m3, $ntlm_hash) = @_;

	my $challenge_blob = $challenge . $m3 -> {ntlm} -> {blob};

	my $ntlm_v2_hash = _ntlm_v2_hash (
		$m3 -> {target} -> {data_oem}, 
		$m3 -> {user} -> {data_oem}, 
		$ntlm_hash
	);

	return $m3 -> {ntlm} -> {md5} eq hmac_md5 ($challenge_blob, $ntlm_v2_hash);

}

################################################################################

sub _ntlm_check_session2 {

	my ($challenge, $m3, $ntlm_hash) = @_;
	
	my $session_nonce = $challenge . $m3 -> {lm} -> {client_nonce};
	
	my $md5 = md5 ($session_nonce);
	
	my $ntlm_session_hash = substr $md5, 0, 8;
		
	my $response = '';
	
	foreach my $t7 (
		substr ($ntlm_hash, 0, 7),
		substr ($ntlm_hash, 7, 7),
		substr ($ntlm_hash, 14, 2) . "\0\0\0\0\0",
	) {	
		my $key = _ntlm_7_to_8 ($t7);		
		my $cipher = new Crypt::DES $key;         		
		$response .= $cipher -> encrypt ($ntlm_session_hash);	
	}
	
	return $m3 -> {ntlm} -> {data} eq $response;

}

################################################################################

sub _ntlm_check {

	my ($challenge, $src_3, $ntlm_hash) = @_;

	my $m3 = parse_ntlm_message ($src_3);

	$m3 -> {type} == 3 or die 'Not a type 3 message ' . _bin_hex ($src_3) . "\n";
	
	return $m3 -> {is_ntlm2_session_response} ? _ntlm_check_session2 ($challenge, $m3, $ntlm_hash) : _ntlm_check_v2 ($challenge, $m3, $ntlm_hash);

} 

1;