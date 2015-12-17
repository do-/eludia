#############################################################################

sub wish_to_adjust_options_for_views {

	my ($options) = @_;

	$options -> {key} = ['name'];

}

#############################################################################

sub wish_to_clarify_demands_for_views {

	my ($view, $options) = @_;

	my @columns = ();

	my $is_columns_section = 0;

	foreach my $line (split /\n/, $view -> {_src}) {

		if ($line =~ /^\s*columns\s*=\>\s*\{/) {
			$is_columns_section = 1;
			next;
		}

		if ($is_columns_section && $line =~ /^\s*\},?\s*$/) {
			last;
		}

		next unless $is_columns_section;

		$line =~ /^\s*(\w+)\s*=\>/ and push @columns, $1;

	}

	$view -> {columns} = join ', ', @columns;

}

#############################################################################

sub wish_to_explore_existing_views {}

#############################################################################

sub wish_to_schedule_cleanup_for_views {}

1;