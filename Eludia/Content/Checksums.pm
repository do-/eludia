################################################################################

sub checksum {

	Digest::MD5::md5_hex (Dumper ($_[0]));

}

################################################################################

sub checksum_filter {

	my ($kind, $prefix, $name2def) = @_;
	
	my $hash = $preconf -> {_} -> {checksums} -> {$kind} or return [$name2def, {}];

	my @result = ({}, {});

	checksum_lock ($kind);

	foreach my $key (keys %$name2def) {
	
		my $name     = $prefix . $key;
		my $def      = $name2def -> {$key};
		my $checksum = checksum ($def);
		
		next if $hash -> {$name} eq $checksum;
		
		$result [0] -> {$key}  = Storable::dclone ($def);
		$result [1] -> {$name} = $checksum;
	
	}

	checksum_unlock ($kind);
	
	return @result;

}

################################################################################

sub checksum_write {

	my ($kind, $name2value) = @_;
	
	my $hash = $preconf -> {_} -> {checksums} -> {$kind} or return;

	checksum_lock ($kind);

	foreach my $key (keys %$name2value) {

		$hash -> {$key} = $name2value -> {$key};

	}
	
	checksum_unlock ($kind);

}

################################################################################

sub checksum_get {

	my ($kind, $name) = @_;
	
	my $hash = $preconf -> {_} -> {checksums} -> {$kind} or return undef;
	
	checksum_lock ($kind);
	
	my $value = $hash -> {$name};

	checksum_unlock ($kind);
	
	return $value;

}

################################################################################

sub checksum_set {

	my ($kind, $name, $value) = @_;
	
	my $hash = $preconf -> {_} -> {checksums} -> {$kind} or return;

	checksum_lock ($kind);

	$hash -> {$name} = $value;

	checksum_unlock ($kind);

}

################################################################################

BEGIN {

	print STDERR " checksums.....................................";
	
	foreach ('SDBM') {
	
		eval "require Eludia::Content::Checksums::$_";
		
		last if $preconf -> {_} -> {checksums};
	
	}
	
	if ($preconf -> {_} -> {checksums}) {

		print STDERR "  checksum hashes...\n";

		foreach my $kind ('db_model') {	checksum_init ($kind) }

	}
	else {
	
		"DISABLED. ok.\n";
	
	}

}

1;
