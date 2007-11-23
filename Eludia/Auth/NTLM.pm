package Eludia::Auth::NTLM;

use Apache::AuthenNTLM;
use Apache::Request;

use Data::Dumper;

@ISA = ('Apache::AuthenNTLM');

sub handler ($$) {

	my ($self, $r) = @_;
	
	our $apr = undef;
	
	return OK if $r -> method eq 'POST' && $r -> header_in ('Content-Length') > 0;

	our $apr = Apache::Request -> new ($r);

	return OK if $apr -> param ('sid');

	my $code = Apache::AuthenNTLM::handler ($self, $r);
	
	return $code;

}

1;