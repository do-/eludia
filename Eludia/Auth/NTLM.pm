package Eludia::Auth::NTLM;

use Apache::AuthenNTLM;
use Apache::Request;

use Data::Dumper;

@ISA = ('Apache::AuthenNTLM');

sub handler ($$) {

	my ($self, $r) = @_;
	
	our $apr = undef;
	
	if ($r -> method eq 'POST') {

		if ($r -> header_in ('Content-Length') == 0) {
		
			$r -> status (401);
			$r -> header_out ('WWW-Authenticate' => 'NTLM TlRMTVNTUAACAAAAAAAAACgAAAABggAAo2hTWy/PW2AAAAAAAAAAAA==');
			$r -> send_http_header ();
						
			return 401;

		}
		else {
			return 200;
		}

	}

	our $apr = Apache::Request -> new ($r);

	return OK if $r -> uri =~ m{favicon\.ico$};

	return OK if $apr -> param ('sid');

	my $code = Apache::AuthenNTLM::handler ($self, $r);
	
	return $code;

}

1;