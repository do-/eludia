use Test::More tests => 8;


my $table_name = 'testtesttesttable1';

sub cleanup {

	eval {sql_do ('DROP SEQUENCE   "OOC_aXe1X8jLRbZrxPDakPPnvw"')};
	eval {sql_do ('DROP CONSTRAINT "OOC_U827OA4bdWC6DX6NSDReww"')};
	eval {sql_do ("DROP TABLE $table_name")};
}

cleanup ();

my @tables = ({

	name    => $table_name,

	columns => {

		id    => {TYPE_NAME => 'int', _EXTRA => 'auto_increment', _PK => 1},
		fake  => {TYPE_NAME => 'bigint'},
		name  => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
		label => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},

	},

	data => [
		{id =>  1, fake => 0, name => 'one',    label => 'The One'},
		{id => 10, fake => 0, name => 'ten',    label => 'The Ten'},
		{id => 20, fake => 0, name => 'twenty', label => 'Twenty'},
		{id => 50, fake => 0, name => 'fifty',  label => 'Fifty'},
	],

});

wish (tables => Storable::dclone \@tables, {});

local $DB_MODEL = {tables => {}};

foreach my $table (@tables) {

	wish (table_columns => [map {{name => $_, %{$table -> {columns} -> {$_}}}}    (keys %{$table -> {columns}})], {table => $table -> {name}});

	wish (table_data => $table -> {data}, {table => $table -> {name}});

	$DB_MODEL -> {tables} -> {$table_name} = $table;
}


################################################################################

my $id_result = sql_select_id ($table_name => {
		name  => 'ten',
		fake  => -1,
		label => 'The Ten overwritten',
	}, ['name']
);
is ($id_result, 10, "sql_select_id existed 'ten'");

is_stored ("sql_select_id existed 'ten' no update", [
	{id =>  1, fake => 0, name => 'one',    label => 'The One'},
	{id => 10, fake => 0, name => 'ten',    label => 'The Ten'},
	{id => 20, fake => 0, name => 'twenty', label => 'Twenty'},
	{id => 50, fake => 0, name => 'fifty',  label => 'Fifty'},
]);


################################################################################

my $id_result = sql_select_id ($table_name => {
		name  => 'ten',
		fake  => -1,
		-label => 'The Ten overwritten',
	}, ['name']
);
is ($id_result, 10, "sql_select_id existed 'ten' overwrite");

is_stored ("sql_select_id existed 'ten' overwrite", [
	{id =>  1, fake => 0, name => 'one',    label => 'The One'},
	{id => 10, fake => 0, name => 'ten',    label => 'The Ten overwritten'},
	{id => 20, fake => 0, name => 'twenty', label => 'Twenty'},
	{id => 50, fake => 0, name => 'fifty',  label => 'Fifty'},
]);


################################################################################

my $id_result = sql_select_id ($table_name => {
		name   => 'ten',
		fake   => 0,
		-label => 'New ten',
	}, ['name', 'label']
);

is ($id_result, 51, "sql_select_id new 'ten'");

is_stored ("sql_select_id new 'ten' insert", [
	{id =>  1, fake => 0, name => 'one',    label => 'The One'},
	{id => 10, fake => 0, name => 'ten',    label => 'The Ten overwritten'},
	{id => 20, fake => 0, name => 'twenty', label => 'Twenty'},
	{id => 50, fake => 0, name => 'fifty',  label => 'Fifty'},
	{id => 51, fake => 0, name => 'ten',    label => 'New ten'},
]);

################################################################################

my $error = '-1';
eval {
	$error = sql_select_id ($table_name => {
			name   => 'ten',
			-label  => 'New ten broken',
			fake   => 0,
			-wrong_column => 'New ten',
		}, ['name', 'label']
	);
};

is ($error eq '-1' && length ($@) > 0, 1, "sql_select_id wrong column name");

is_stored ("sql_select_id wrong column name no update", [
	{id =>  1, fake => 0, name => 'one',    label => 'The One'},
	{id => 10, fake => 0, name => 'ten',    label => 'The Ten overwritten'},
	{id => 20, fake => 0, name => 'twenty', label => 'Twenty'},
	{id => 50, fake => 0, name => 'fifty',  label => 'Fifty'},
	{id => 51, fake => 0, name => 'ten',    label => 'New ten'},
]);

################################################################################

sub is_stored {

	my ($name, $data) = @_;

	my $sql_data = sql_select_all ("SELECT * FROM $table_name ORDER BY id");

	my $result = is_deeply ($sql_data, $data, $name) or darn [$sql_data, $data];

	return $result;

}

END  { cleanup (); }
