#############################################################################

sub wish_to_actually_create_table_data {

	my ($items, $options) = @_;

	@$items > 0 or return;

	my $uniq_cols;
	foreach my $record (@$items) {
		foreach my $column (keys %$record) {
			$uniq_cols -> {$column} = 1;
		}
	}

	my @cols = keys %$uniq_cols;
	my @prms = ();

	my $is_set_identity_insert;
	foreach my $col (@cols) {
		if ($col eq 'id') {
			$is_set_identity_insert = 1;
		}


		push @prms, [ map {$_ -> {$col}} @$items];

	}

	my $sql = "INSERT INTO $options->{table} (" . (join ', ', @cols) . ") VALUES (" . (join ', ', map {'?'} @cols) . ")";

	$sql = "SET IDENTITY_INSERT $options->{table} ON; $sql; SET IDENTITY_INSERT $options->{table} OFF"
		if $is_set_identity_insert;

	__profile_in ('sql.prepare');

	my $sth = $db -> prepare ($sql);

	__profile_out ('sql.prepare', {label => $sql});

	__profile_in ('sql.execute');

	$sth -> execute_array ({ArrayTupleStatus => \my @tuple_status}, @prms);

	__profile_out ('sql.execute', {label => $sql . ' ' . Dumper (\@prms)});

	$sth -> finish;

}

1;