#############################################################################

sub wish_to_adjust_options_for_views {

	my ($options) = @_;
	
	$options -> {key} = ['name'];

}

#############################################################################

sub wish_to_clarify_demands_for_views {

	my ($view, $options) = @_;

	my @columns = ();

	foreach my $line (split /\n/, $view -> {_src}) {
			
		last if $line =~ /^[\#\s]*(keys|data|sql)\s*=\>/;
			
		next if $line =~ /^\s*columns\s*=\>/;
			
		$line =~ /^\s*(\w+)\s*=\>/ and push @columns, $1;

	}

	$view -> {columns} = join ', ', @columns;

}

#############################################################################

sub wish_to_explore_existing_views {}

#############################################################################

sub wish_to_schedule_cleanup_for_views {}

1;