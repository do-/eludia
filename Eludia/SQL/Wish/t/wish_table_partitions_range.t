use Test::More tests => 6;

my $table = 'test_table_partitions_range';

cleanup ();

my $table_def = {

	name    => $table,

	columns => {

		id    => {TYPE_NAME => 'int', _EXTRA => 'auto_increment', _PK => 1},
		fake  => {TYPE_NAME => 'bigint'},
		name  => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
		label => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},

	},

	partition => {
		by         => 'fake',
		kind       => 'range',
		partitions => [1, 'max'],
	}

};

wish (tables =>  Storable::dclone [$table_def], {});

wish (table_columns => [map {{name => $_, %{$table_def -> {columns} -> {$_}}}}    (keys %{$table_def -> {columns}})], {table => $table_def -> {name}, table_def => $table_def}) if exists $table_def -> {columns};

sql_do ("ALTER TABLE $table ADD UNIQUE KEY idx_label(label)");

wish (table_partitions => [$table_def -> {partition}]
	, {table => $table_def -> {name}, table_def => $table_def}) if exists $table_def -> {partition};

################################################################################

wish (table_data => [

	{id => 1, fake => -1, name => 'one',   label => 'The One'},
	{id => 2, fake => 0, name => 'two',   label => 'The Two'},
	{id => 3, fake => -1, name => 'three', label => 'The Three'},
	{id => 4, fake => 0, name => 'four',  label => 'The Four'},

], {table => $table, key => 'id'});

################################################################################

is_partitioned ({
	by         => 'fake',
	kind       => 'range',
	partitions => [1, 'MAXVALUE'],
}, 'initial fill');

################################################################################

my $sql_explain = sql_select_all ("EXPLAIN PARTITIONS SELECT * FROM $table WHERE fake = 0");

$sql_explain = $sql_explain -> [0];

is_deeply ($sql_explain -> {partitions}, 'p0', 'partition pruning') or darn $sql_explain;

################################################################################

wish (table_partitions => [{
	by         => 'fake',
	kind       => 'range',
	partitions => [-1, 0, 'max'],
}] , {table => $table_def -> {name}, table_def => $table_def});

is_partitioned ({
	by         => 'fake',
	kind       => 'range',
	partitions => [-1, 0, 'MAXVALUE'],
}, 'repartition');

################################################################################

wish (table_partitions => [{
	by         => 'fake',
	kind       => 'range',
	partitions => [0],
}] , {table => $table_def -> {name}, table_def => $table_def});

is_partitioned ({}, 'single partition removes partitioning');

################################################################################

my ($label_key) = grep {$_ -> {name} eq 'idx_label'} __get_table_keys ($table);

is_deeply ($label_key -> {parts}, ['label'], 'unique index remains untouched after removing partitioning')
	or darn $label_key;

################################################################################

wish (table_partitions => [{
	by         => 'id',
	kind       => 'RANGE',
	partitions => [2, 4, 'max'],
}] , {table => $table_def -> {name}, table_def => $table_def});

is_partitioned ({
	by         => 'id',
	kind       => 'range',
	partitions => [2, 4, 'MAXVALUE'],
}, 'repartition after partition drop');

################################################################################

sub is_partitioned {

	my ($partition_def, $label) = @_;

	my $existing = wish_to_explore_existing_table_partitions ({table => $table});

	my $partitions = keys %$existing? $existing -> {$partition_def -> {by}} : $existing;

	is_deeply ($partitions, $partition_def, $label) or darn [$existing, $partitions, $partition_def];
}

################################################################################

sub cleanup {

	eval {sql_do ("DROP TABLE $table")};

}

END  { cleanup () }