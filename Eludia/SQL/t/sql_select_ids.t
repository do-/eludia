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

	data => [
		{fake => 0, name => 'one',    label => 'The One'},
		{fake => 0, name => 'ten',    label => 'The Ten'},
		{fake => 0, name => 'sure_see', label => 'Are you sure ? Try it!'},
		{fake => 0, name => 'sure', label => 'Are you sure?'},
	],

});

wish (tables => Storable::dclone \@tables, {});

foreach my $table (@tables) {

	wish (table_columns => [map {{name => $_, %{$table -> {columns} -> {$_}}}}    (keys %{$table -> {columns}})], {table => $table -> {name}});

	wish (table_data => $table -> {data}, {table => $table -> {name}});
}

my $result = sql_select_ids ("SELECT name FROM $table WHERE name = ?", 'ten');

is ($result, '-1,ten', "sql_select_ids ?, params = ('ten')");


my $sure = sql_select_ids ("SELECT name FROM $table WHERE label = 'Are you sure?'");

is ($sure, '-1,sure', "sql_select_ids ? with question mark, params = ()");


my $sure_see = sql_select_ids ("SELECT name FROM $table WHERE label = 'Are you sure ? Try it!'");

is ($sure_see, '-1,sure_see', "sql_select_ids ? with question mark in middle, params = ()");


my $error = '-1';
eval {
	$error = sql_select_ids ("SELECT name FROM $table WHERE name = ?");
};

is ($error eq '-1' && length ($@) > 0, 1, "sql_select_ids ?, params = ()");

END  { cleanup (); }
