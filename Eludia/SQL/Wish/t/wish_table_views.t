use Test::More tests => 6;

my $table = 'test';

cleanup ();

my $table_def = {

	name    => $table,

	columns => {

		id    => {TYPE_NAME => 'int', _EXTRA => 'auto_increment', _PK => 1},
		fake  => {TYPE_NAME => 'bigint'},
		name  => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
		label => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},

	},
};

wish (tables =>  Storable::dclone [$table_def], {});

wish (table_columns => [map {{name => $_, %{$table_def -> {columns} -> {$_}}}}    (keys %{$table_def -> {columns}})], {table => $table_def -> {name}, table_def => $table_def}) if exists $table_def -> {columns};

my $views = test_views_def ();

wish (views => $views, {});

################################################################################

wish (table_data => [

	{id => 1, fake => 0, name => 'one',   label => 'The One'},
	{id => 2, fake => 0,  name => 'two',   label => 'The Two'},
	{id => 3, fake => 0, name => 'one', label => 'The Three'},
	{id => 4, fake => -1,  name => 'four',  label => 'The Four'},

], {table => $table, key => 'id'});

################################################################################

foreach my $view (@$views) {

	my $sql_explain = sql_select_scalar ("SELECT TABLE_NAME FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_SCHEMA = database() AND TABLE_NAME = ?", $view -> {name});

	is_deeply ($sql_explain, $view -> {name}, "view created: $$view{name}") or darn [$view, $sql_explain];

	my $cnt = sql_select_all ("SELECT name, cnt FROM $$view{name}");

	is_deeply ($cnt, [{name => 'one', cnt => 2}, {name => 'two', cnt => 1}], "view select: $$view{name}") or darn $cnt;
}

################################################################################

sub test_views_def {

	my $sql = <<EOS;
	SELECT
		name
		, COUNT(name) AS cnt
	FROM
		$table
	WHERE
		fake = 0
	GROUP BY
		name
EOS

	my $sql_src = <<'SRC';
sql => <<EOS,
$sql
EOS
SRC

	my $columns_src = <<EOS;
columns => {
	name     => 'string',
	cnt      => 'int',
},
EOS

	my $label_src = "label => 'label',";

	return [
		{
			name => "${table}_view_label_first",

			label => 'label',

			columns => {
				name     => 'string',
				cnt      => 'int',
			},

			sql => $sql,

			_src => <<SRC,
	$label_src

	$columns_src

	$sql_src
SRC
		},
		{
			name => "${table}_view_label_middle",


			columns => {
				name     => 'string',
				cnt      => 'int',
			},

			sql => $sql,

			label => 'label',

			_src => <<SRC,
	$columns_src

	$label_src

	$sql_src
SRC

		},
		{
			name => "${table}_view_label_last",


			columns => {
				name     => 'string',
				cnt      => 'int',
			},

			sql => $sql,

			label => 'label',

			_src => <<SRC,
	$columns_src

	$sql_src

	$label_src
SRC

		},
	];
}

################################################################################

sub cleanup {

	foreach my $view (@{test_views_def ()}) {
		eval {sql_do ("DROP VIEW $$view{name}")};
	}

	eval {sql_do ("DROP TABLE $table")};
}

END  { cleanup () }
