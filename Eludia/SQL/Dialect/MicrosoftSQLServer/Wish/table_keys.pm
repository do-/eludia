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

	sql_select_loop ("exec sp_helpindex '$options->{table}'", sub {

		$existing -> {lc $i -> {index_name}} = [split /\,/, lc $i -> {index_keys}];

	});
	
	return $existing;

}

#############################################################################

sub wish_to_actually_create_table_keys {	

	my ($items, $options) = @_;
	
	foreach my $i (@$items) {
	
		sql_do ("CREATE INDEX $i->{global_name} ON $options->{table} (@{[ join ', ', @{$_ -> {parts}} ]})");
	
	}

	
}

#############################################################################

sub wish_to_actually_alter_table_keys {

	my ($items, $options) = @_;

	foreach my $i (@$items) {
	
		sql_do ("DROP INDEX $i->{global_name} ON $options->{table}");
	
	}
	
	wish_to_actually_create_table_keys (@_);

}

1;