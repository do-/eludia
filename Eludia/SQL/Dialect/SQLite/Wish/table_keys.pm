#############################################################################

sub wish_to_clarify_demands_for_table_keys {	

	my ($i, $options) = @_;
	
	$i -> {global_name} = $options -> {table} . '_' . $i -> {name};

	ref $i -> {parts} eq ARRAY or $i -> {parts} = [split /\,/, $i -> {parts}];
	
	foreach my $part (@{$i -> {parts}}) {
	
		$part = lc $part;
		
		$part =~ s{\s}{}gsm;
	
	}

}

################################################################################

sub wish_to_explore_existing_table_keys {

	my ($options) = @_;

	my $existing = {};

	my $len = 1 + length $options -> {table};

	sql_select_loop ("SELECT * FROM sqlite_master WHERE type = 'index' and tbl_name = ?", sub {

		$i -> {sql} =~ m{\((.*)\)}gsm or return;
		
		my $def = $1;
		
		$def =~ s{\s}{}gsm;

		my $global_name = lc $i -> {name};

		$existing -> {$global_name} = {
					
			parts       => [split /\,/, lc $def],

			global_name => $global_name,

			name        => substr $global_name, $len
			
		};

	}, $options -> {table});
	
	return $existing;

}

1;