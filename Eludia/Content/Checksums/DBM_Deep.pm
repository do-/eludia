use DBM::Deep;

################################################################################

sub checksum_lock {

	my ($kind) = @_;

	$preconf -> {_} -> {checksums} -> {$kind} -> lock ();

}

################################################################################

sub checksum_unlock {

	my ($kind) = @_;

	$preconf -> {_} -> {checksums} -> {$kind} -> unlock ();
	
}

################################################################################

sub checksum_init {

	my ($kind) = @_;

	my $filename = "$preconf->{_}->{docroot}dbm/$kind.dd";

	print STDERR "   $filename... ";
		
	$preconf -> {_} -> {checksums} -> {$kind} = DBM::Deep -> new ($filename);

	chmod 0777, $filename;
		
	print STDERR "ok.\n";

}

################################################################################

BEGIN {

	if ($preconf -> {_} -> {docroot}) {
	
		$preconf -> {_} -> {checksums} = {};
		
		print STDERR "DBM::Deep, ok.\n";
	
	}

}

1;
