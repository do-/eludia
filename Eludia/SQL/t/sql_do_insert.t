use Test::More tests => 4;

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

	id    => 10,
	fake  => 0,
	name  => 'ten', 
	label => 'The Ten',
	
});

is_stored ('Non-empty table, explicit ID', [

	{id => 1,  fake => 0, name => 'one', label => 'The One'},
	{id => 10, fake => 0, name => 'ten', label => 'The Ten'},

]);

################################################################################

sql_do ("INSERT INTO $table (fake, name, label) VALUES (?, ?, ?)",

	0,
	'eleven', 
	'The Eleven',
	
);

is_stored ('Non-empty table, native auto increment after explicit ID', [

	{id => 1,  fake => 0, name => 'one',    label => 'The One'},
	{id => 10, fake => 0, name => 'ten',    label => 'The Ten'},
	{id => 11, fake => 0, name => 'eleven', label => 'The Eleven'},

]);

################################################################################

sql_do_insert ($table => {

	fake  => 0,
	name  => 'twelve', 
	label => 'The Twelve',
	
});

is_stored ('Non-empty table, sql_do_insert again', [

	{id => 1,  fake => 0, name => 'one',    label => 'The One'},
	{id => 10, fake => 0, name => 'ten',    label => 'The Ten'},
	{id => 11, fake => 0, name => 'eleven', label => 'The Eleven'},
	{id => 12, fake => 0, name => 'twelve', label => 'The Twelve'},

]);

################################################################################

sub is_stored {

	my ($name, $data) = @_;
	
	my $sql_data = sql_select_all ("SELECT * FROM $table ORDER BY id");
	
	my $result = is_deeply ($sql_data, $data, $name) or darn [$sql_data, $data];
	
	return $result;

}

END  { cleanup (); }