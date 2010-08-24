use SDBM_File;

################################################################################

sub checksum_lock {
	
	my $file_name = checksum_file_name (@_);
	
	open  (CHECKSUM_FILE, "$file_name.lock") || die "can't open $file_name.lock: $!";

	flock (CHECKSUM_FILE, LOCK_EX);

}

################################################################################

sub checksum_unlock {

	flock (CHECKSUM_FILE, LOCK_UN);

	close (CHECKSUM_FILE);
	
}

################################################################################

sub checksum_file_name {

	my ($kind) = @_;
	
	return "$preconf->{_}->{docroot}dbm/$kind.sdbm";

}

################################################################################

sub checksum_init {

	my ($kind) = @_;

	my $filename = "$preconf->{_}->{docroot}dbm/$kind.sdbm";

	loading_log "   $filename... ";
	
	open (LOCK, ">$filename.lock") or die "Can't write to $filename.lock: $!\n";
	print LOCK 1;
	close (LOCK);

	chmod 0777, "$filename.lock";

	my %h;
	tie (%h, 'SDBM_File', $filename, O_RDWR | O_CREAT, 0777) or die "Couldn't tie SDBM file $filename: $!\n";

	$preconf -> {_} -> {checksums} -> {$kind} = \%h;
		
	loading_log "ok.\n";

}

################################################################################

BEGIN {

	if ($preconf -> {_} -> {docroot}) {
	
		$preconf -> {_} -> {checksums} = {};
		
		loading_log "SDBM, ok.\n";
	
	}

}

1;
