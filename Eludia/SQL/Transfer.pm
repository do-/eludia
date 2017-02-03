################################################################################

sub sql_assert_timestamp {

	my ($table) = @_;

	my $columns = $model_update -> get_columns ($table);

	foreach my $name (keys %$columns) {

		return $name if $columns -> {$name} -> {TYPE_NAME} eq 'timestamp'

	};

	$model_update -> assert (

		default_columns => $DB_MODEL -> {default_columns},

		tables => {$table => {

			columns => { ts => {TYPE_NAME => 'timestamp'} },

			keys    => { ts => 'ts'	},

		}},

		prefix => 'sql_assert_timestamp#',

	);

	sql_do ("UPDATE $table SET ts = NOW() WHERE ts = 0");

	return 'ts';

}

################################################################################

sub sql_insert_fakes {

	my ($table, $last_id) = @_;

	$last_id ||= sql_select_scalar ("SELECT MAX(id) FROM $table");

	my $st_insert = $db -> prepare ("INSERT INTO $table (id, fake) VALUES (?, -127)");

	my $st_prev_existing = $db -> prepare ("SELECT MAX(id) FROM $table WHERE id < ?");

	my $st_prev_after_hole = $db -> prepare (qq {
		SELECT
			MAX(current.id)
		FROM
			$table current
			LEFT JOIN $table prev ON prev.id = current.id - 1
		WHERE
			current.id <= ?
			AND prev.id IS NULL
	});

	while ($last_id > 0) {

		$st_prev_after_hole -> execute ($last_id);

		my ($id_after_hole) = $st_prev_after_hole -> fetchrow_array;

		$st_prev_after_hole -> finish;

		$id_after_hole > 0 or last;

		$st_prev_existing -> execute ($id_after_hole);

		($last_id) = $st_prev_existing -> fetchrow_array;

		$st_prev_existing -> finish;

		my $min = ($last_id ||= 0) + 1;

		$min >= 1 or $min = 1;

		my $max = $id_after_hole - 1;

		$min <= $max or next;

		warn "sql_insert_fakes: $table [$min .. $max]\n";

		$st_insert -> execute_array ({}, [$last_id + 1 .. $id_after_hole - 1]);

	}

}

################################################################################

sub sql_export_table_to_json_by_id {

	my ($table, $out, $from) = @_;

	sql_export_json  ("DESCRIBE $table", $out);

	sql_export_json  ("SELECT * FROM $table WHERE id >= ?", $out, 0 + $from);

}

################################################################################

sub sql_export_table_to_json_by_timestamp {

	my ($table, $out, $from) = @_;

	my $ts = sql_assert_timestamp ($table);

	my $data = $DB_MODEL -> {tables} -> {$table} -> {data};

	if (!$data || @$data != sql_select_scalar ("SELECT COUNT(*) FROM $table")) {

		sql_insert_fakes ($table);

	}

	sql_export_json  ("DESCRIBE $table", $out);

	my $id = sql_select_scalar ("SELECT MAX(id) FROM $table");

	$id > 0 or return;

	sql_export_json  ("SELECT * FROM $table WHERE $ts > ? AND $ts < ? AND id <= ? ORDER BY $ts", $out, $from, sprintf ('%04d-%02d-%02d %02d:%02d:%02d', Date::Calc::Today_and_Now), $id);

	my $cb = ref $out eq CODE ? $out : sub {print $out $_[0]};

	&$cb ("DELETE FROM $table WHERE id > $id\n");

}

################################################################################

sub sql_export_json {

	my ($sql, $out, @params) = @_;

	my $cb = ref $out eq CODE ? $out : sub {print $out $_[0]};

	$_JSON or setup_json ();

	my $table;

	if ($sql =~ /^\s*DESC(?:RIBE)?\s+(\w+)\s*$/gism) {

		$table = $1;

		$_REQUEST {__last_described_to_json} = $table;

		my $def = {
			name    => $table,
			columns => $model_update -> get_columns ($table),
		};

		my $keys = $model_update -> get_keys ($table, $conf -> {core_voc_replacement_use});

		foreach my $k (keys %$keys) {
			next if $k =~ /^pk/;
			$def -> {keys} -> {$k} = $keys -> {$k};
		}

		&$cb ($_JSON -> encode ($def) . "\n");

		return;

	}

	if ($sql =~ /\bSELECT\s+(\w+)\.*/gism) {
		$table = $1;
	}
	elsif ($sql =~ /\bFROM\s+(\w+)/gism) {
		$table = $1;
	}

	$table or die "Invalid SQL (no table): $sql";

	if ($sql =~ /^\s*SELECT\s+\*/ism && $_REQUEST {__last_described_to_json} eq $table) {

		my %columns = %{ $model_update -> get_columns ($table) };

		delete $columns {id};

		my @columns = ('id', sort keys %columns);

		sql_select_loop ($sql, sub {&$cb ($_JSON -> encode ([@$i{@columns}]) . "\n")}, @params);

		delete $_REQUEST {__last_described_to_json};

	}
	else {

		sql_select_loop ($sql, sub {&$cb ($_JSON -> encode ([$table => $i]) . "\n")}, @params);

	}


}

################################################################################

sub sql_import_json {

	my ($in, $cb) = @_;

	my $auto_commit;
	eval { $auto_commit = $db -> {AutoCommit}; $db -> {AutoCommit} = 0; };

	$_JSON or setup_json ();

	my $last_table = '';
	my $last_identified_table = '';
	my $table = '';

	my @data = ();
	my @columns;

	my $data_item;

	while (my $line = <$in>) {

		if ($line !~ /^[\{\[]/) {

			sql_do ($line);

			next;

		}

		my $r = $_JSON -> decode ($line);

		if (ref $r eq HASH) {

			foreach my $c (values %{$r -> {columns}}) {

				exists $c -> {REMARKS} and $c -> {REMARKS} or next;

				$c -> {REMARKS} = Encode::encode ('windows-1252', $c -> {REMARKS});

			}

			$model_update -> assert (

				tables => {($table = $r -> {name}) => $r},

				default_columns => $DB_MODEL -> {default_columns},

				prefix => 'sql_import_json#',

			);

			next;

		}

		$table = $r -> [1] eq HASH ? $r -> [0] : $last_table;

		if ($last_identified_table ne $table) {

			@columns = ('id', sort grep {$_ ne 'id'} keys %{$model_update -> get_columns ($table)});

			$last_identified_table = $table;

		}

		if (ref $r -> [1] eq HASH) {

			$data_item = $r -> [1];

		}
		else {

			my %h = ();

			@h {@columns} = @$r;

			$data_item = \%h;

		}

		if ($data_item) {

			our $i18n ||= i18n ();

			use Encode;

			foreach (values %$data_item) {

				$_ = Encode::encode ('windows-1252', $_);

			}

		}

		&$cb ($r, $data_item) if $cb;

	}
	continue {

		if (@data > 99 or ($last_table and ($last_table ne $table))) {

			wish (table_data => \@data, {table => $last_table});

			$db -> commit;

			@data = ();

		}

		$last_table = $table;

		push @data, $data_item if ref $data_item;

		$data_item = undef;

	}

	wish (table_data => \@data, {table => $last_table}) if @data > 0;

	$db -> commit;

	eval { $db -> {AutoCommit} = $auto_commit; };

}

1;