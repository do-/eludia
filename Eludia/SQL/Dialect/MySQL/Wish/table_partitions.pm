#############################################################################

sub wish_to_clarify_demands_for_table_partitions {

	my ($i, $options) = @_;

	$i -> {kind} = uc $i -> {kind};
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

			my $name = $i -> {partition_expression};

			if (exists $existing -> {$name}) {

				if ($i -> {partition_method} eq 'HASH') {
					$existing -> {$name} -> {partitions}++;
				}

				if ($i -> {partition_method} eq 'RANGE') {
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
				kind => lc $i -> {partition_method},
				partitions => $partition_list -> {lc $i -> {partition_method}},
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

	$i -> {SQL} = "PARTITION BY " . uc $$i{kind} . "($$i{by}) ";

	$i -> {kind} eq 'hash' and $i -> {SQL} .= "PARTITIONS $$i{partitions}";

	if (lc $i -> {kind} eq 'range') {

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

		my $columns = join ', ', @{$i -> {parts}};

		if ($i -> {name} eq 'PRIMARY') {
			sql_do ("ALTER TABLE $table DROP PRIMARY KEY, ADD PRIMARY KEY ($columns, $column)");
			next;
		}

		sql_do (
			"ALTER TABLE $table DROP KEY $$i{name}, ADD UNIQUE KEY $$i{name}($columns, $column)"
		);
	}


}

#############################################################################

sub wish_to_actually_alter_table_partitions {

	my ($items, $options) = @_;

	my $partition = $items -> [0];

	my $supported_kinds = ['hash', 'range'];

	if ($partition -> {kind} ~~ $supported_kinds) {
		die "Wrong partition kind '$$partition{kind}' in table '$$options{table}'. Supported partition kinds: @$supported_kinds";
	}

	__genereate_sql_fragment_for_partition ($partition);

	__add_column_table_keys ($partition -> {by}, $options -> {table});

	sql_do ("ALTER TABLE $options->{table} $$partition{SQL}");
}

1;