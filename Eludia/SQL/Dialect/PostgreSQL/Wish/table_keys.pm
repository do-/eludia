#############################################################################

sub wish_to_clarify_demands_for_table_keys {	

	my ($i, $options) = @_;
	
	$i -> {global_name} = 'ix_' . $options -> {table} . '_' . $i -> {name};

	ref $i -> {parts} eq ARRAY or $i -> {parts} = [split /\,/, $i -> {parts}];
	
	foreach my $part (@{$i -> {parts}}) {
	
		$part = lc $part;
		
		$part =~ s{\s}{}gsm;
	
		$part =~ s{(\w+)\((\d+)\)}{substring($1 from 1 for $2)};

	}

}

################################################################################

sub wish_to_explore_existing_table_keys {

	my ($options) = @_;

	my $existing = {};
	
	my $len = 4 + length $options -> {table};

	sql_select_loop ("SELECT * FROM pg_indexes WHERE schemaname = current_schema () AND tablename = ? AND indexname NOT LIKE '%_pkey'", sub {

		$i -> {indexdef} =~ /\((.*)\)/;

		my $def = $1;

		$def =~ s{\s}{}g;
		
		my $global_name = lc $i -> {indexname};

		$existing -> {$global_name} = {
					
			parts       => [split /\,/, lc $def],
			
			global_name => $global_name,

			name        => substr $global_name, $len
			
		};

	}, $options -> {table});

	return $existing;

}

#############################################################################

sub wish_to_actually_create_table_keys {	

	my ($items, $options) = @_;
	
	my $concurrently = $self -> {db} -> {AutoCommit} ? 'CONCURRENTLY' : '';

	foreach my $i (@$items) {

		sql_do ("CREATE $concurrently INDEX $i->{global_name} ON $options->{table} (@{[ join ', ', @{$i -> {parts}} ]})");
	
	}

	
}

1;