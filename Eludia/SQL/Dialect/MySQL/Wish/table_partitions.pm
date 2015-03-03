#############################################################################

sub wish_to_clarify_demands_for_table_partitions {

	my ($i, $options) = @_;

	$i -> {kind} = lc $i -> {kind};

	if (ref $i -> {partitions} eq 'ARRAY') {

		foreach (@{$i -> {partitions}}) {
			$_ .= "";
		}
	}
}

################################################################################

sub wish_to_explore_existing_table_partitions {

	my ($options) = @_;

	my $existing = {};

	sql_select_loop (<<EOS
			SELECT
				partition_name
				, partition_method
				, partition_expression
				, partition_description
			FROM
				information_schema.partitions
			WHERE
				table_schema = database()
			AND
				table_name = ?
EOS
		, sub {

			$i -> {partition_expression} or return;

			my $name = lc $i -> {partition_expression};

			$i -> {partition_method} = lc $i -> {partition_method};

			if (exists $existing -> {$name}) {

				if ($i -> {partition_method} eq 'hash') {
					$existing -> {$name} -> {partitions}++;
				}

				if ($i -> {partition_method} eq 'range') {
					push @{$existing -> {$name} -> {partitions}}, $i -> {partition_description};
				}

				return;
			}

			my $partition_list = {
				hash  => 1,
				range => [$i -> {partition_description}],
			};

			$existing -> {$name} = {
				by   => $name,
				kind => $i -> {partition_method},
				partitions => $partition_list -> {$i -> {partition_method}},
			};
		}
		, $options -> {table}
	);

	return $existing;
}


#############################################################################

sub __genereate_sql_fragment_for_partition {

	my ($i) = @_;

	$i -> {SQL} and return;

	$i -> {SQL} = "PARTITION BY " . uc ($i -> {kind}) . "($$i{by}) ";

	if ($i -> {kind} eq 'hash') {

		$i -> {SQL} .= "PARTITIONS $$i{partitions}";

	} elsif ($i -> {kind} eq 'range') {

		my $cnt = -1;

		foreach (@{$i -> {partitions}}) {
			$_ eq 'max' and $_ = 'MAXVALUE';
		}

		my $partitions = join ", ", map {$cnt++; "PARTITION p$cnt VALUES LESS THAN ($_)"} @{$i -> {partitions}};

		$i -> {SQL} .= "($partitions)";
	}
}

#############################################################################

sub wish_to_update_demands_for_table_partitions {

	my ($old, $new, $options) = @_;

	__genereate_sql_fragment_for_partition ($_) foreach ($old, $new);
}

#############################################################################

sub wish_to_schedule_modifications_for_table_partitions {

	my ($old, $new, $todo, $options) = @_;

	push @{$todo -> {alter}}, $new;

}

#############################################################################

sub wish_to_actually_create_table_partitions {

	my ($items, $options) = @_;

	wish_to_actually_alter_table_partitions($items, $options);
}

#############################################################################

sub __get_table_keys {

	my ($table) = @_;

	my $raw_keys = sql_select_all("SHOW KEYS FROM $table");

	my $key_hash;

	foreach my $i (@$raw_keys) {

		my $key = ($key_hash -> {$i -> {Key_name}} ||= {});

		$key -> {name} = $i -> {Key_name};

		$key -> {unique} = !$i -> {Non_unique};

		$key -> {parts} ||= [];

		push @{$key -> {parts}}, $i -> {Column_name};
	}

	return map {$key_hash -> {$_}} keys %$key_hash;
}

#############################################################################

sub __add_column_table_keys {

	my ($column, $table) = @_;

	foreach my $i (__get_table_keys ($table)) {

		next
			if !$i -> {unique} || $column ~~ $i -> {parts};

		my $key_columns = join ', ', @{$i -> {parts}};

		if ($i -> {name} eq 'PRIMARY') {
			sql_do ("ALTER TABLE $table DROP PRIMARY KEY, ADD PRIMARY KEY ($key_columns, $column)");
			next;
		}

		sql_do (
			"ALTER TABLE $table DROP KEY $$i{name}, ADD UNIQUE KEY $$i{name}($key_columns, $column)"
		);
	}


}

#############################################################################

sub __remove_column_table_keys {

	my ($column, $table) = @_;

	my %is_partitioning_column = ($column => 1);

	foreach my $i (__get_table_keys ($table)) {

		next
			if !$i -> {unique} || !($column ~~ $i -> {parts});

		my $key_columns = join ', ', grep {!$is_partitioning_column{$_}} @{$i -> {parts}};

		if ($i -> {name} eq 'PRIMARY') {
			sql_do ("ALTER TABLE $table DROP PRIMARY KEY, ADD PRIMARY KEY ($key_columns)");
			next;
		}

		sql_do (
			"ALTER TABLE $table DROP KEY $$i{name}, ADD UNIQUE KEY $$i{name}($key_columns)"
		);
	}

}

#############################################################################

sub __drop_table_partitions {

	my ($options) = @_;

	sql_do ("ALTER TABLE $options->{table} REMOVE PARTITIONING");

	my $columns = $options -> {table_def} -> {partition} -> {columns};

	__remove_column_table_keys ($columns, $options -> {table});
}

#############################################################################

sub wish_to_actually_alter_table_partitions {

	my ($items, $options) = @_;

	my $partition = $items -> [0];

	my $supported_kinds = ['hash', 'range'];

	if (!($partition -> {kind} ~~ $supported_kinds)) {
		die "Wrong partition kind '$$partition{kind}' in table '$$options{table}'. Supported partition kinds: @$supported_kinds";
	}

	$partition -> {columns} ||= $partition -> {by};

	my $partition_cnt = ref $partition -> {partitions} eq 'ARRAY'?
		0 + @{$partition -> {partitions}} : $partition -> {partitions};

	if (1 == $partition_cnt) {
		__drop_table_partitions ($options);
		return;
	}

	__genereate_sql_fragment_for_partition ($partition);

	__add_column_table_keys ($partition -> {columns}, $options -> {table});

	sql_do ("ALTER TABLE $options->{table} $$partition{SQL}");
}

1;