package Eludia::Auth::NTLM;

use Apache::AuthenNTLM;
use Apache::Request;

@ISA = ('Apache::AuthenNTLM');

sub handler ($$) {

	my ($self, $r) = @_;

	our $apr = Apache::Request -> new ($r);

	return OK if $apr -> param ('sid');

	return Apache::AuthenNTLM::handler ($self, $r);

}

1;