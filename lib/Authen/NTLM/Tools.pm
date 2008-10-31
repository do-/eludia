package Authen::NTLM::Tools;

use 5.008008;
use strict;
use warnings;

use MIME::Base64;
use Unicode::String;
use Digest::MD5 qw (md5);
use Digest::HMAC_MD5 qw (hmac_md5);
use Digest::MD4;
use Crypt::DES;
use Math::BigInt;

no strict 'refs';

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	_bin_2_hex
	_hex_2_bin
	_ntlm_7_to_8
	parse_ntlm_message
	parse_ntlm_message_flags
	parse_ntlm_message_buffers
	parse_ntlm_message_1
	parse_ntlm_message_2
	parse_ntlm_message_3
	_ntlm_hash
	_ntlm_v2_hash
	_ntlm_check_v2
	_ntlm_check_session2
	_ntlm_check
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw ();

our $VERSION = '0.01';

no strict 'subs';

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
__END__

=head1 NAME

Authen::NTLM::Tools - Tools for server side NTLM calculations.

=head1 SYNOPSIS

  use Authen::NTLM::Tools ('_ntlm_hash', '_ntlm_check');
  
  ...
  
  my $eight_byte_nonce = ...
  my $plaintext_password = ...
  
  my $ntlm_hash = _ntlm_hash ($plaintext_password);
    
  if (_ntlm_check (
  	$eight_byte_nonce, 
  	$r -> header_in ('Authorization'),
  	$ntlm_hash
  ) {
  	...
  }
    

=head1 DESCRIPTION

This module contains some utility functions for dealing with intercepted NTLM 
headers. Algorithms and data structures definitions are taken from http://davenport.sourceforge.net/ntlm.html.

It may be useful for developing WEB applications featuring NTLM authentication without
proxying SMB requests to any domain server.

Say, one could check the sambaNTPassword attribute in Samba LDAP, verify plaintext passwords
etc.

=head2 EXPORT_OK

=head3 _bin_2_hex

Given a scalar, returns its hexadecimal representation.

=head3 _hex_2_bin

Given a hexadecimal number, converts it to a binary string.

=head3 _ntlm_7_to_8

Given a 7-bit DES key, returns a 8-bit DES key (with parity bit).

=head3 parse_ntlm_message

Given a raw HTTP header, returns a data structure representing it. Use Data::Dumper or details.

=head3 parse_ntlm_message_flags

Given a data structure, parses its flags field into a hash. For internal use.

=head3 parse_ntlm_message_buffers

Given a data structure, parses its security buffers into hashes. For internal use.

=head3 parse_ntlm_message_1

Given a binary NTLM message of type 1, returns a data structure representing it. Use Data::Dumper for details.

=head3 parse_ntlm_message_2

Given a binary NTLM message of type 2, returns a data structure representing it. Use Data::Dumper for details.

=head3 parse_ntlm_message_3

Given a binary NTLM message of type 3, returns a data structure representing it. Use Data::Dumper for details.

=head3 _ntlm_hash

Given a string, returns the corresponding NTLM hash (WinNT encoded password). This is the same as that Samba LDAP stores (in hexadecimal) in the sambaNTPassword attribute.

=head3 _ntlm_v2_hash

Given target name, user name and the NTLM hash, returns the corresponding NTLMv2 hash. For internal use.

=head3 _ntlm_check_v2

Given the 8 byte challenge (aka nonce), a raw HTTP Authorization header of type 3 and an NTLM hash, returns 1 iif the NTLM2 auhtentication succeeds.

=head3 _ntlm_check_session2

Given the 8 byte challenge (aka nonce), a raw HTTP Authorization header of type 3 and an NTLM hash, returns 1 iif the auhtentication with NTLM2 session response succeeds.

=head3 _ntlm_check

Given the 8 byte challenge (aka nonce), a raw HTTP Authorization header of type 3 and an NTLM hash, returns 1 iif the NTLM auhtentication of any known kind succeeds.

=head1 DISCLAIMER

The sources of this software are published for research puposes only. You can use it at your own risk.

=head1 BUGS / LIMITATIONS

Only NTLMv2 response and NTLM2 Session response are handled properly for type 3 messages.

Unicode user/target names and passwords won't work. (Please inform me if you know how to get an uppercase unicode in binary form. For now, I just insert zero bytes).

=head1 SEE ALSO

Apache::AuthenNTLM and Apache2::AuthenNTLM: great modules, but not working with NTLMv2. So, they are incompatible with Vista (by default).

Authen::NTLM, Authen::Perl::NTLM, and derivatives: these are for client, not sever side.

=head1 AUTHOR

Dmitry Ovsyanko, E<lt>do@eludia.ruE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Dmitry Ovsyanko

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
