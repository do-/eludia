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
	
	eval {

		sql_select_loop ("exec sp_helpindex '$options->{table}'", sub {
		
			return if lc $i -> {index_keys} eq 'id';

			my $global_name = lc $i -> {index_name};

			$existing -> {$global_name} = {

				parts       => [split /\,/, lc $i -> {index_keys}],

				global_name => $global_name,

				name        => substr $global_name, $len

			};

		})
	
	};
	
	return $existing;

}

#############################################################################

sub wish_to_actually_create_table_keys {	

	my ($items, $options) = @_;
	
	foreach my $i (@$items) {
	
		sql_do ("CREATE INDEX [$i->{global_name}] ON [$options->{table}] (@{[ join ', ', @{$i -> {parts}} ]})");
	
	}

	
}

#############################################################################

sub wish_to_actually_alter_table_keys {

	my ($items, $options) = @_;

	foreach my $i (@$items) {
	
		sql_do ("DROP INDEX [$options->{table}].[$i->{global_name}]");
	
	}
	
	wish_to_actually_create_table_keys (@_);

}

1;