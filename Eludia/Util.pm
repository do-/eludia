################################################################################

sub status_switch {

	my ($sql) = @_;
	
	my $status = {};
	
	foreach my $line (split /\n/, $sql) {
		$line =~ /(\d+)\s*\#\s*(.*)/;
		$status -> {$1} = $2;
	}
	
	return ($sql, $status);

}

1;