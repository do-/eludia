#############################################################################

sub wish_to_adjust_options_for_table_columns {

	my ($options) = @_;

	$options -> {key} = ['name'];

}

#############################################################################

sub wish_to_clarify_demands_for_table_columns {

	my ($i, $options) = @_;

	$i -> {REMARKS} ||= delete $i -> {label};

	exists $i -> {NULLABLE} or $i -> {NULLABLE} = $i -> {name} eq 'id' ? 0 : 1;

	exists $i -> {COLUMN_DEF} or $i -> {COLUMN_DEF} = undef;

	$i -> {TYPE_NAME} = uc $i -> {TYPE_NAME};

	if ($i -> {TYPE_NAME} eq 'NUMERIC') {

		$i -> {TYPE_NAME} = 'DECIMAL';

	}

	if ($i -> {TYPE_NAME} eq 'MEDIUMINT') {

		$i -> {TYPE_NAME} = 'BIGINT';

	}

	if ($i -> {TYPE_NAME} =~ /TEXT$/) {

		$i -> {TYPE_NAME} = 'VARCHAR';
		$i -> {COLUMN_SIZE} ||= 'max';

	}

	if ($i -> {TYPE_NAME} eq 'DECIMAL') {

		$i -> {COLUMN_SIZE}    ||= 10;

		$i -> {DECIMAL_DIGITS} ||= 0;

	}

	if ($i -> {TYPE_NAME} =~ /VARCHAR$/) {

		$i -> {COLUMN_SIZE} ||= 255;

	}

	if ($i -> {TYPE_NAME} eq 'TIMESTAMP') {

		$i -> {TYPE_NAME} = 'DATETIME';

		$i -> {COLUMN_DEF} = 'GETDATE()';

	}

	if (!$i -> {NULLABLE} && !defined $i -> {COLUMN_DEF} && $i -> {name} ne 'id') {

		$i -> {COLUMN_DEF} =

			$i -> {TYPE_NAME} =~ /INT$/     ? 0 :
			$i -> {TYPE_NAME} eq 'DECIMAL'  ? 0 :
			$i -> {TYPE_NAME} eq 'DATETIME' ? '1970-01-01' :
			''

	}

	if (defined $i -> {COLUMN_DEF}) {

		$i -> {COLUMN_DEF} .= '';

	}

}

################################################################################

sub wish_to_explore_existing_table_columns {

	my ($options) = @_;

	my $existing = {};

	sql_select_loop (

		q {
			SELECT
				column_name
				, data_type
				, column_default
				, is_nullable
				, numeric_precision
				, numeric_scale
				, character_maximum_length
			FROM
				information_schema.columns
			WHERE
				table_catalog = db_name()
				AND table_name = ?
		},

		sub {

			my $name = $i -> {column_name};

			$existing -> {$name} = my $def = {

				name       => $name,

				TYPE_NAME  => uc $i -> {data_type},

				COLUMN_DEF => $i -> {column_default},

				NULLABLE   => ($i -> {is_nullable} =~ /^No/i ? 0 : 1),

			};

			if ($def -> {COLUMN_DEF} =~ /^\(\'(.*)\'\)$/) {

				$def -> {COLUMN_DEF} = $1;

			}

			if ($def -> {TYPE_NAME} eq 'NUMERIC') {

				$def -> {TYPE_NAME} = 'DECIMAL';

			}

			if ($def -> {TYPE_NAME} eq 'DECIMAL') {

				$def -> {COLUMN_SIZE}    = $i -> {numeric_precision};
				$def -> {DECIMAL_DIGITS} = $i -> {numeric_scale};

			}
			elsif ($def -> {TYPE_NAME} eq 'VARBINARY') {

				$def -> {COLUMN_SIZE}    = $i -> {character_maximum_length};

			}
			elsif ($def -> {TYPE_NAME} =~ /CHAR$/) {

				$def -> {COLUMN_SIZE}    = $i -> {character_maximum_length};

			}

		},

		$options -> {table}

	);

	sql_select_loop ("EXEC sp_helpindex '$options->{table}'", sub {

		foreach my $col (split /\,/, $i -> {index_keys}) {

			$col =~ /^\w+/ or next;

			push @{$options -> {col2key} -> {lc $1}}, $i -> {index_name};

		}

	});

	return $existing;

}

#############################################################################

sub __genereate_sql_fragment_for_column {

	my ($i) = @_;

	return if $i -> {SQL};

	$i -> {SQL} = $i -> {TYPE_NAME} . (

		$i -> {TYPE_NAME} eq 'DECIMAL' ? " ($i->{COLUMN_SIZE}, $i->{DECIMAL_DIGITS})" :

		$i -> {TYPE_NAME} eq 'VARBINARY' ? " ($i->{COLUMN_SIZE})" :

		$i -> {TYPE_NAME} =~ /CHAR$/ ? " ($i->{COLUMN_SIZE})" :

		'');

	$i -> {SQL} .= $i -> {NULLABLE} ? ' NULL' : ' NOT NULL';

	$i -> {SQL_DEF} = $i -> {SQL};

	if (defined $i -> {COLUMN_DEF}) {

		$i -> {COLUMN_DEF} =~ s{'}{''}g; #';

		if ($i->{COLUMN_DEF} =~ /^\w+\(\)$/ || $i->{COLUMN_DEF} =~ /\d+/) {
			$i -> {SQL_DEF} .= " DEFAULT $i->{COLUMN_DEF}";
		} else {
			$i -> {SQL_DEF} .= " DEFAULT '$i->{COLUMN_DEF}'";
		}

	}

	%$i = map {$_ => $i -> {$_}} qw (name SQL SQL_DEF NULLABLE TYPE_NAME COLUMN_DEF);

}

#############################################################################

sub wish_to_update_demands_for_table_columns {

	my ($old, $new, $options) = @_;

	if ($old -> {TYPE_NAME} =~ /^N.*CHAR$/ and $new -> {TYPE_NAME} !~ /^N/ and $new -> {TYPE_NAME} =~ /(CHAR|TEXT)$/) {

		$new -> {TYPE_NAME} = 'N' . $new -> {TYPE_NAME};

	}

	__adjust_column_dimensions ($old, $new, {

		char    => qr {CHAR$},

		decimal => 'DECIMAL',

	});

	__genereate_sql_fragment_for_column ($_) foreach ($old, $new);

}

#############################################################################

sub wish_to_schedule_modifications_for_table_columns {

	my ($old, $new, $todo, $options) = @_;

	unless ($old -> {TYPE_NAME} eq $new -> {TYPE_NAME} and $new -> {TYPE_NAME} =~ /VARCHAR$/) {

		sql_do ("DROP INDEX [$_]") foreach @{$options -> {col2key} -> {$new -> {name}}};

	}

	push @{$todo -> {$old -> {COLUMN_DEF} eq $new -> {COLUMN_DEF} ? 'alter' : 'recreate'}}, $new;

}

#############################################################################

sub wish_to_actually_alter_table_columns {

	my ($items, $options) = @_;

	sql_do ("ALTER TABLE [$options->{table}] ALTER COLUMN [$_->{name}] $_->{SQL}") foreach @$items;

}

#############################################################################

sub wish_to_actually_create_table_columns {

	my ($items, $options) = @_;

	__genereate_sql_fragment_for_column ($_) foreach @$items;

	sql_do ("ALTER TABLE [$options->{table}] ADD " . (join ', ', map {"[$_->{name}] $_->{SQL_DEF}"} @$items));

}

#############################################################################

sub wish_to_actually_recreate_table_columns {

	my ($items, $options) = @_;

	foreach my $i (@$items) {

		my $constraint_name = __get_constraint_name_for_column ($options -> {table}, $i -> {name});

		sql_do ("ALTER TABLE $options->{table} DROP CONSTRAINT $constraint_name")
			if $constraint_name;

		foreach (__get_index_name_for_column ($options -> {table}, $i -> {name})) {
			sql_do ("DROP INDEX [$options->{table}].[$_]");
		}

		eval {

			foreach (

				"ALTER TABLE $options->{table} ADD           mssuxx    $i->{SQL_DEF} ",
				"UPDATE      $options->{table} SET           mssuxx =  $i->{name}",
				"ALTER TABLE $options->{table} DROP COLUMN             $i->{name}",
				"EXEC sp_rename '$options->{table}.mssuxx', '$i->{name}', 'COLUMN'"

			) { sql_do ($_) }

		};

		if ($@) {

			my $error = $@;

			my $constraint_name = __get_constraint_name_for_column ($options -> {table}, 'mssuxx');

			sql_do ("ALTER TABLE $options->{table} DROP CONSTRAINT $constraint_name")
				if $constraint_name;

			eval {

				sql_do ("ALTER TABLE $options->{table} DROP COLUMN mssuxx");

			};

			die $error;

		}

	}

}

#############################################################################

sub __get_constraint_name_for_column {

	my ($table, $column) = @_;

	return sql_select_scalar (<<EOS);
		SELECT
			dc.name
		FROM
			sys.default_constraints dc
			JOIN sys.columns c ON c.default_object_id = dc.object_id
		WHERE
			dc.parent_object_id = OBJECT_ID('$table')
			AND c.name = '$column'
EOS

}

#############################################################################

sub __get_index_name_for_column {

	my ($table, $column) = @_;

	my @index_names;

	sql_select_loop ("exec sp_helpindex '$table'", sub {

		push @index_names, lc $i -> {index_name}
			if lc ($i -> {index_keys}) =~ /\b$column\b/;

	});

	return @index_names;

}

1;