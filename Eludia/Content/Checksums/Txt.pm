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
	
	return "$preconf->{_}->{docroot}dbm/$kind.txt";

}

################################################################################

sub checksum_init {

	my ($kind) = @_;

	my $filename = checksum_file_name ($kind);

	loading_log "   $filename... ";
	
	open (LOCK, ">$filename.lock") or die "Can't write to $filename.lock: $!\n";
	print LOCK 1;
	close (LOCK);

	chmod 0777, "$filename.lock";

	open (F, ">$filename") or die "Can't write to $filename: $!\n";
	print F '';
	close (F);

	chmod 0777, $filename;

	my %h;
	tie (%h, 'Eludia::Tie::Txt_hash', $filename) or die "Couldn't tie Txt_hash file $filename: $!\n";

	$preconf -> {_} -> {checksums} -> {$kind} = \%h;
		
	loading_log "ok.\n";

}

################################################################################

BEGIN {

	if ($preconf -> {_} -> {docroot}) {
	
		$preconf -> {_} -> {checksums} = {};
		
		loading_log "Txt, ok.\n";
	
	}

}

################################################################################

package Eludia::Tie::Txt_hash;

sub TIEHASH  {

	my ($package, $filename) = @_;

	-f $filename or die "File doesn't exist: $filename\n";
	
	my $options = {
	
		filename => $filename,
	
	};

	bless $options, $package;

}

sub FETCH {

	my ($options, $key) = @_;
	
	my $value;

	open  (F, $options -> {filename}) or die "Can't open $options->{filename}: $!\n";
	
	while (<F>) {
	
		/^$key\t/ or next;
		
		$value = $';
		
		chomp $value;
		
		last;
	
	}
	
	close (F);
	
	return $value;

}

sub STORE {

	my ($options, $key, $value) = @_;
		
	my %h = ();

	open  (F, $options -> {filename}) or die "Can't open $options->{filename}: $!\n";
		
	while (<F>) {
	
		my ($k, $v) = split /[\t\n\r]+/;

		$h {$k} = $v;
	
	}
	
	close (F);

	$h {$key} = $value;

	open  (F, ">$options->{filename}") or die "Can't write to $options->{filename}: $!\n";
	
	while (my ($k, $v) = each %h) {
	
		print F "$k\t$v\n";
	
	}
	
	close (F);

}
