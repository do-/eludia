#############################################################################

sub wish_to_adjust_options_for_table_data {	

	my ($options) = @_;
		
	$options -> {key} ||= 'id';
	$options -> {key}   = [grep {$_} split /\W/, $options -> {key}];
	
	$options -> {ids}   = -1;

}

#############################################################################

sub wish_to_clarify_demands_for_table_data {	

	my ($i, $options) = @_;

	foreach (keys (%{$options -> {root}})) { $i -> {$_} = $options -> {root} -> {$_} }

	$options -> {ids} .= ",$i->{id}" if defined $i -> {id};

}

#############################################################################

sub wish_to_explore_existing_table_data {	

	my ($options) = @_;
		
	my $sql = "SELECT * FROM $options->{table} WHERE 1=1";
	
	my @params = ();
	
	foreach my $i (keys %{$options -> {root}}) {
		
		$sql .= " AND $i = ?";
			
		push @params, $options -> {root} -> {$i};

	}
	
	$sql .= " AND id IN ($options->{ids})" if $options -> {ids} ne '-1';
	
	my $existing = {};

	my @key = @{$options -> {key}};

	sql_select_loop ($sql, sub { $existing -> {join '_', @$i {@key}} = $i }, @params);
	
	return $existing;

}

#############################################################################

sub wish_to_update_demands_for_table_data {

	my ($old, $new, $options) = @_;

	foreach my $k (keys %$old) {
	
		$old -> {$k} .= '' if defined $old -> {$k};
	
		next if exists $new -> {$k};
		
		$new -> {$k} = $old -> {$k};
		
	};
	
	foreach (keys %$new) {defined $new -> {$_} and $new -> {$_} .= ''};

}

#############################################################################

sub wish_to_schedule_modifications_for_table_data {	

	my ($old, $new, $todo, $options) = @_;

	push @{$todo -> {update}}, $new;

}

#############################################################################

sub wish_to_schedule_cleanup_for_table_data {	

	my ($existing, $todo, $options) = @_;
	
	%{$options -> {root}} and %$existing or return;
			
	$todo -> {'delete'} = [ values %$existing ];

}

#############################################################################

sub wish_to_actually_create_table_data {	

	my ($items, $options) = @_;

	@$items > 0 or return;

	my @cols = ();
	my @prms = ();
	
	foreach my $col (keys %{$items -> [0]}) {

		push @cols, "$model_update->{quote}$col$model_update->{quote}";
		push @prms, [ map {$_ -> {$col}} @$items];
	
	}
		
	my $sql = "INSERT INTO $options->{table} (" . (join ', ', @cols) . ") VALUES (" . (join ', ', map {'?'} @cols) . ")";

	__profile_in ('sql.prepare_execute');

	my $sth = $db -> prepare ($sql);

	my @tuple_status;
	
	$sth -> execute_array ({ArrayTupleStatus => \@tuple_status}, @prms);
	
	sql_check_seq ($options -> {table});
	
	__profile_out ('sql.prepare_execute', {label => $sql . ' ' . Dumper (\@prms) . ' ' . Dumper (\@tuple_status)});

	$sth -> finish;
	
	die $@ if $@;
	
}

#############################################################################

sub wish_to_actually_update_table_data {	

	my ($items, $options) = @_;

	@$items > 0 or return;

	my @cols = ();
	my @prms = ();
	
	foreach my $col (grep {$_ ne 'id'} keys %{$items -> [0]}) {
		
		push @cols, "$model_update->{quote}$col$model_update->{quote} = ?";
		push @prms, [ map {$_ -> {$col}} @$items];
	
	}
	
	push @prms, [ map {$_ -> {id}} @$items];
	
	my $sql = "UPDATE $options->{table} SET " . (join ', ', @cols) . " WHERE id = ?";
		
	__profile_in ('sql.prepare_execute');

	my $sth = $db -> prepare ($sql);

	$sth -> execute_array ({ArrayTupleStatus => \my @tuple_status}, @prms);
	
	__profile_out ('sql.prepare_execute', {label => $sql . ' ' . Dumper (\@prms)});

	$sth -> finish;

}

#############################################################################

sub wish_to_actually_delete_table_data {

	my ($items, $options) = @_;
	
	@$items > 0 or return;
	
	my $sql = $options -> {soft_delete} ? 

		"UPDATE $options->{table} SET fake = -1 WHERE id = ?" :
	
		"DELETE FROM $options->{table} WHERE id = ?";

	__profile_in ('sql.prepare_execute');

	my $sth = $db -> prepare ($sql);
	
	my $p = [map {$_ -> {id}} @$items];

	$sth -> execute_array ({ArrayTupleStatus => \my @tuple_status}, $p);
	
	__profile_out ('sql.prepare_execute', {label => $sql . ' ' . Dumper ($p)});

	$sth -> finish;

}

1;