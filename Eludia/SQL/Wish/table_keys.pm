#############################################################################

sub wish_to_adjust_options_for_table_keys {

	my ($options) = @_;
	
	$options -> {key} = ['global_name'];

}

#############################################################################

sub wish_to_update_demands_for_table_keys {}

#############################################################################

sub wish_to_schedule_modifications_for_table_keys {

	my ($old, $new, $todo, $options) = @_;

	push @{$todo -> {alter}}, $new;
	
}

#############################################################################

sub wish_to_schedule_cleanup_for_table_keys {}

#############################################################################

sub wish_to_actually_create_table_keys {	

	my ($items, $options) = @_;
	
	foreach my $i (@$items) {
	
		sql_do ("CREATE INDEX $i->{global_name} ON $options->{table} (@{[ join ', ', @{$i -> {parts}} ]})");
	
	}

	
}

#############################################################################

sub wish_to_actually_alter_table_keys {

	my ($items, $options) = @_;

	foreach my $i (@$items) {
	
		sql_do ("DROP INDEX $i->{global_name}");
	
	}
	
	wish_to_actually_create_table_keys (@_);

}

1;