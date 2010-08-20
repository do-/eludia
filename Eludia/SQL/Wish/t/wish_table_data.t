use Test::More tests => 6;

my $table = 'testtesttesttable1';

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

wish (table_data => [

	{id => 1, fake => 0, name => 'one',   label => 'The One'},
	{id => 2, fake => 0, name => 'two',   label => 'The Two'},
	{id => 3, fake => 0, name => 'three', label => 'The Three'},
	{id => 4, fake => 0, name => 'four',  label => 'The Four'},

], {table => $table, key   => 'id'});

is_stored ('Initial fill in by id', [

	{id => 1, fake => 0, name => 'one',   label => 'The One'},
	{id => 2, fake => 0, name => 'two',   label => 'The Two'},
	{id => 3, fake => 0, name => 'three', label => 'The Three'},
	{id => 4, fake => 0, name => 'four',  label => 'The Four'},

]);

################################################################################

wish (table_data => [

	{id => 1, name => 'impair'},
	{id => 2, name => 'pair'},
	{id => 3, name => 'impair'},
	{id => 4, name => 'pair'},

], {table => $table, key   => 'id'});

is_stored ('Partial update by id', [

	{id => 1, fake => 0, name => 'impair', label => 'The One'},
	{id => 2, fake => 0, name => 'pair',   label => 'The Two'},
	{id => 3, fake => 0, name => 'impair', label => 'The Three'},
	{id => 4, fake => 0, name => 'pair',   label => 'The Four'},

]);

################################################################################

wish (table_data => [

	{id => 5, fake => 0, name => 'impair', label => 'The Five'},

], {table => $table, key   => 'id'});

is_stored ('Append by id', [

	{id => 1, fake => 0, name => 'impair', label => 'The One'},
	{id => 2, fake => 0, name => 'pair',   label => 'The Two'},
	{id => 3, fake => 0, name => 'impair', label => 'The Three'},
	{id => 4, fake => 0, name => 'pair',   label => 'The Four'},
	{id => 5, fake => 0, name => 'impair', label => 'The Five'},

]);

################################################################################

wish (table_data => [

	{fake => 0, name => 'pair',   label => 'The Four'},
	{fake => 0, name => 'pair',   label => 'The Six'},

], {table => $table, key => 'label', root => {name => 'pair'}});

is_stored ('Insert / Update / Delete by key & root', [

	{id => 1, fake => 0, name => 'impair', label => 'The One'},
	{id => 3, fake => 0, name => 'impair', label => 'The Three'},
	{id => 4, fake => 0, name => 'pair',   label => 'The Four'},
	{id => 5, fake => 0, name => 'impair', label => 'The Five'},
	{id => 6, fake => 0, name => 'pair',   label => 'The Six'},

]);

################################################################################

wish (table_data => [

	{fake => 0, name => 'pair',   label => 'The Four'},
	{fake => 0, name => 'pair',   label => 'The Six'},

], {table => $table, key => 'label', root => {name => 'pair'}});

is_stored ('The same thig once more', [

	{id => 1, fake => 0, name => 'impair', label => 'The One'},
	{id => 3, fake => 0, name => 'impair', label => 'The Three'},
	{id => 4, fake => 0, name => 'pair',   label => 'The Four'},
	{id => 5, fake => 0, name => 'impair', label => 'The Five'},
	{id => 6, fake => 0, name => 'pair',   label => 'The Six'},

]);

################################################################################

wish (table_data => [

	{fake => 0, name => 'pair',   label => 'The Four'},
	{fake => 0, name => 'pair',   label => 'The Six'},
	{fake => 0, name => 'pair',   label => 'The Six'},
	{fake => 0, name => 'pair',   label => 'The Six'},
	{fake => 0, name => 'pair',   label => 'The Six'},

], {table => $table, key => 'label', root => {name => 'pair'}});

is_stored ('Duplicated items', [

	{id => 1, fake => 0, name => 'impair', label => 'The One'},
	{id => 3, fake => 0, name => 'impair', label => 'The Three'},
	{id => 4, fake => 0, name => 'pair',   label => 'The Four'},
	{id => 5, fake => 0, name => 'impair', label => 'The Five'},
	{id => 6, fake => 0, name => 'pair',   label => 'The Six'},

]);

################################################################################

sub is_stored {

	my ($name, $data) = @_;
	
	my $sql_data = sql_select_all ("SELECT * FROM $table ORDER BY id");
	
	my $result = is_deeply ($sql_data, $data, $name) or darn [$sql_data, $data];
	
	return $result;

}

sub cleanup {

	eval {sql_do ('DROP SEQUENCE   "OOC_aXe1X8jLRbZrxPDakPPnvw"')};
	eval {sql_do ('DROP CONSTRAINT "OOC_U827OA4bdWC6DX6NSDReww"')};
	eval {sql_do ("DROP TABLE $table")};

}

END  { cleanup () }