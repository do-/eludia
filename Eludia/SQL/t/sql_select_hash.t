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

	data => [
		{fake => 0, name => 'one',    label => 'The One'},
		{fake => 0, name => 'ten',    label => 'The Ten'},
		{fake => 0, name => 'eleven', label => 'The Eleven'},
		{fake => 0, name => 'twelve', label => 'The Twelve'},
	],

});

wish (tables => Storable::dclone \@tables, {});

foreach my $table (@tables) {

	wish (table_columns => [map {{name => $_, %{$table -> {columns} -> {$_}}}}    (keys %{$table -> {columns}})], {table => $table -> {name}});

	wish (table_data => $table -> {data}, {table => $table -> {name}});
}

my $result = sql_select_hash ("SELECT name FROM $table WHERE name = ?", 'ten');

is ($result -> {name}, 'ten', "SELECT ?, params = ('ten')");


$result = sql_select_hash ("SELECT name FROM $table WHERE name = ?", 'ten');

$result = sql_select_hash ("SELECT name FROM $table WHERE name = ?", undef);

is ($result -> {name}, undef, "SELECT ?, params = (undef)");


$result = sql_select_hash ("SELECT name FROM $table WHERE name = ?", 'ten');

$result = sql_select_hash ("SELECT name FROM $table WHERE name = ?", ());

is ($result -> {name}, undef, "SELECT ?, params = ()");

END  { cleanup (); }
