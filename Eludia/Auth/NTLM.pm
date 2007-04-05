package Eludia::Auth::NTLM;

use Apache::AuthenNTLM;

use Data::Dumper;

@ISA = ('Apache::AuthenNTLM');

sub verify_user {

	my ($self, $r) = @_;

	$self -> {dummy_user} = Apache::AuthenNTLM::verify_user (@_) ? 0 : 1;
	
warn 'Eludia::Auth::NTLM::verify_user: ' . Dumper ($self);
	
	return 1;    
	
}

sub map_user {

	my ($self, $r) = @_;

warn 'Eludia::Auth::NTLM::map_user: ' . Dumper ($self);

	return '' if $self -> {dummy_user};
	return Apache::AuthenNTLM::map_user ($self, $r);
	
}
    
1;
