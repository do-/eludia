#############################################################################

sub wish_to_actually_create_table_data {	

	my ($items, $options) = @_;

	@$items > 0 or return;
	
	if (exists $items -> [0] -> {id}) {

		sql_do_insert ($options -> {table} => $_) foreach sort {$a -> {id} <=> $b -> {id}} @$items;
	
	}
	else {


		my $uniq_cols;
		foreach my $record (@$items) {
			foreach my $column (keys %$record) {
				$uniq_cols -> {$column} = 1;
			}
		}

		my @prms = ();
		my @cols = keys %$uniq_cols;

		foreach my $col (@cols) {

			push @prms, [ map {$_ -> {$col}} @$items];

		}
		
		my $sql = "INSERT INTO $options->{table} (" . (join ', ', @cols) . ") VALUES (" . (join ', ', map {'?'} @cols) . ")";

		__profile_in ('sql.prepare');

		my $sth = $db -> prepare ($sql);

		__profile_out ('sql.prepare', {label => $sql});

		__profile_in ('sql.execute');

		$sth -> execute_array ({ArrayTupleStatus => \my @tuple_status}, @prms);

		__profile_out ('sql.execute', {label => $sql . ' ' . Dumper (\@prms)});

		$sth -> finish;

	}
	
}

1;