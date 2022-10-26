use Test::More tests => 2;

my $table = 'testtesttesttable1';

cleanup ();

my @tables = ({

	name    => $table,

	columns => {

		id                 => {TYPE_NAME => 'int', _EXTRA => 'auto_increment', _PK => 1},
		fake               => {TYPE_NAME => 'bigint'},
		label              => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
		id_status          => {TYPE_NAME => 'int', label => 'Статус'},
		dt_status          => {TYPE_NAME => 'datetime', label => 'Дата изменения статуса'},

	},

	triggers => {
		before_update => q {
			IF NEW.id_status <> OLD.id_status THEN
				SET NEW.dt_status = '2022-10-26 15:00:00';
			END IF;
		},
	}

});

wish (tables => Storable::dclone \@tables, {});

foreach my $table (@tables) {

	wish (table_columns => [map {{name => $_, %{$table -> {columns} -> {$_}}}}    (keys %{$table -> {columns}})], {table => $table -> {name}});
	wish (table_triggers => [map {{name => $_, body => $table -> {triggers} -> {$_}}} (keys %{$table -> {triggers}})], {table => $table -> {name}});
}

################################################################################

wish (table_data => [

	{id => 1, fake => 0, label => 'The One',   id_status => undef, dt_status => undef},
	{id => 2, fake => 0, label => 'The One',   id_status => 10,    dt_status => undef},

], {table => $table, key   => 'id'});

is_stored ('Initial fill in by id', [

	{id => 1, fake => 0, label => 'The One',   id_status => undef, dt_status => undef},
	{id => 2, fake => 0, label => 'The One',   id_status => 10,    dt_status => undef},

]);

################################################################################

sql_do ("UPDATE $table SET id_status = 20 WHERE id <= 2");

is_stored ('Update status dt by trigger', [

	{id => 1, fake => 0, label => 'The One',   id_status => 20,   dt_status => undef},
	{id => 2, fake => 0, label => 'The One',   id_status => 20,   dt_status => '2022-10-26 15:00:00'},

]);

################################################################################

sub is_stored {

	my ($name, $data) = @_;

	my $sql_data = sql_select_all ("SELECT * FROM $table ORDER BY id");

	my $result = is_deeply ($sql_data, $data, $name) or darn [$sql_data, $data];

	return $result;

}

sub cleanup {

	eval {sql_do ("DROP TABLE $table")};

}

END  { cleanup () }