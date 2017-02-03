#############################################################################

sub wish_to_schedule_modifications_for_table_data {	

	my ($old, $new, $todo, $options) = @_;

	push @{$todo -> {replace}}, $new;

}

#############################################################################

sub wish_to_actually_create_table_data {	

	wish_to_actually_modify_table_data (@_, 'INSERT');

}

#############################################################################

sub wish_to_actually_replace_table_data {	

	wish_to_actually_modify_table_data (@_, 'REPLACE');

}

#############################################################################

sub wish_to_actually_modify_table_data {

	my ($items, $options, $statement) = @_;

	@$items > 0 or return;

	my $packages_by_column_set = {};

	foreach my $record (@$items) {

		my $column_set_key = join(',',sort(keys(%$record)));

		$packages_by_column_set -> {$column_set_key} ||= [];

		push (@{$packages_by_column_set -> {$column_set_key}}, $record);

	}

	$statement .= ' DELAYED' if $options -> {delayed};

	foreach my $key (keys %$packages_by_column_set) {

		my @cols = split /,/, $key;

		my @values;

		foreach my $i (@{$packages_by_column_set->{$key}}) { push @values, '(' . (join ',', map {$db -> quote ($i -> {$_})} @cols) . ')' }

		my $sql = "$statement $options->{table} (" . (join ',', @cols) . ")VALUES" . (join ',', @values);

		sql_do ($sql);

	}
	
}

#############################################################################

sub wish_to_actually_delete_table_data {

	my ($items, $options) = @_;
	
	@$items > 0 or return;
	
	my $sql = $options -> {soft_delete} ? 
	
		"UPDATE $options->{table} SET fake = -1" : 
		
		"DELETE FROM $options->{table}";
	
	sql_do ("$sql WHERE id IN (" . join (',', map {$_ -> {id}} @$items) . ")");
	
}

1;