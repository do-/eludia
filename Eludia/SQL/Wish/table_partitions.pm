
#############################################################################

sub wish_to_adjust_options_for_table_partitions {

	my ($options) = @_;

	$options -> {key} = ['by'];
}

#############################################################################

sub wish_to_schedule_cleanup_for_table_partitions {}

1;