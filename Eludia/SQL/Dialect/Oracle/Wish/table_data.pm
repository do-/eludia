#############################################################################

sub wish_to_actually_create_table_data {	

	my ($items, $options) = @_;

	@$items > 0 or return;
	
	if (exists $items -> [0] -> {id}) {

		sql_do_insert ($options -> {table} => $_) foreach sort {$a -> {id} <=> $b -> {id}} @$items;
	
	}
	else {

		my @cols = ();
		my @prms = ();

		foreach my $col (keys %{$items -> [0]}) {

			push @cols, $col;
			push @prms, [ map {$_ -> {$col}} @$items];

		}
		
		my $sql = "INSERT INTO $options->{table} (" . (join ', ', @cols) . ") VALUES (" . (join ', ', map {'?'} @cols) . ")";

		my $sth = $db -> prepare ($sql);

		$sth -> execute_array ({}, @prms);

		$sth -> finish;

	}
	
}

1;