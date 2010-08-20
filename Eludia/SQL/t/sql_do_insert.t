use Test::More tests => 3;

my $table = 'testtesttesttable1';

sub cleanup {

	eval {sql_do ('DROP SEQUENCE   "OOC_aXe1X8jLRbZrxPDakPPnvw"')};
	eval {sql_do ('DROP CONSTRAINT "OOC_U827OA4bdWC6DX6NSDReww"')};
	eval {sql_do ("DROP TABLE $table")};

}

cleanup ();

my @tables = ({

	name    => $table,

	columns => {

		id    => {TYPE_NAME => 'int', _EXTRA => 'auto_increment', _PK => 1},
		fake  => {TYPE_NAME => 'bigint'},
		name  => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
		label => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},

	},

});

wish (tables => Storable::dclone \@tables, {});

foreach my $table (@tables) {

	wish (table_columns => [map {{name => $_, %{$table -> {columns} -> {$_}}}}    (keys %{$table -> {columns}})], {table => $table -> {name}});

}

################################################################################

sql_do_insert ($table => {

	fake  => 0,
	name  => 'one', 
	label => 'The One',
	
});

is_stored ('Empty table, no ID', [

	{id => 1, fake => 0, name => 'one', label => 'The One'},

]);

################################################################################

sql_do_insert ($table => {

	id    => 3,
	fake  => 0,
	name  => 'three', 
	label => 'The Three',
	
});

is_stored ('Non-empty table, explicit ID', [

	{id => 1, fake => 0, name => 'one',   label => 'The One'},
	{id => 3, fake => 0, name => 'three', label => 'The Three'},

]);

################################################################################

sql_do_insert ($table => {

	fake  => 0,
	name  => 'four', 
	label => 'The Four',
	
});

is_stored ('Non-empty table, auto increment after explicit ID', [

	{id => 1, fake => 0, name => 'one',   label => 'The One'},
	{id => 3, fake => 0, name => 'three', label => 'The Three'},
	{id => 4, fake => 0, name => 'four',  label => 'The Four'},

]);

################################################################################

sub is_stored {

	my ($name, $data) = @_;
	
	my $sql_data = sql_select_all ("SELECT * FROM $table ORDER BY id");
	
	my $result = is_deeply ($sql_data, $data, $name) or darn [$sql_data, $data];
	
	return $result;

}

END  { cleanup (); }