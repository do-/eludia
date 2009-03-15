#############################################################################

sub wish_to_adjust_options_for_table_columns {

	my ($options) = @_;
	
	$options -> {key} = ['name'];

}

#############################################################################

sub wish_to_update_demands_for_table_columns {}

#############################################################################

sub wish_to_schedule_modifications_for_table_columns {

	my ($old, $new, $todo, $options) = @_;

	push @{$todo -> {alter}}, $new;
	
}

#############################################################################

sub wish_to_schedule_cleanup_for_table_columns {}

1;