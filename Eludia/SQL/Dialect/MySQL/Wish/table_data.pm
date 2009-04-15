#############################################################################

sub wish_to_explore_existing_table_data {	

	my ($options) = @_;
	
	$options -> {root} or return {};
	
	my $existing = {};
	
	my $sql = "SELECT * FROM $options->{table} WHERE 1=1";
	
	my @params = ();
	
	foreach my $i (keys %{$options -> {root}}) {
		
		$sql .= " AND $i = ?";
			
		push @params, $options -> {root} -> {$i};

	}

	$sql .= " AND id IN ($options->{ids})" if $options -> {ids} ne '-1';
		
	sql_select_loop ($sql, sub { $existing -> {@$i {@{$options -> {key}}}} = $i }, @params);
	
	return $existing;

}

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

	my @cols = keys %{$items -> [0]};
	
	$statement .= ' DELAYED' if %{$options -> {root}} > 0;
	
	my $sql = "$statement $options->{table} (" . (join ',', @cols) . ")VALUES";
		
	foreach my $i (@$items) { $sql .= '(' . (join ',', map {$db -> quote ($i -> {$_})} @cols) . '),' }
	
	chop $sql;

	sql_do ($sql);
	
}

#############################################################################

sub wish_to_actually_delete_table_data {

	my ($items, $options) = @_;
	
	@$items > 0 or return;
	
	sql_do ("DELETE FROM $options->{table} WHERE id IN (" . join (',', map {$_ -> {id}} @$items) . ")");
	
}

1;