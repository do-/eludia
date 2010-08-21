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

	loading_log "   $filename... ";
		
	$preconf -> {_} -> {checksums} -> {$kind} = DBM::Deep -> new ($filename);

	chmod 0777, $filename;
		
	loading_log "ok.\n";

}

################################################################################

BEGIN {

	if ($preconf -> {_} -> {docroot}) {
	
		$preconf -> {_} -> {checksums} = {};
		
		loading_log "DBM::Deep, ok.\n";
	
	}

}

1;
