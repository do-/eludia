#############################################################################

sub wish_to_adjust_options_for_table_columns {

	my ($options) = @_;
	
	$options -> {key} = ['name'];
		
	$options -> {table_name} = $options -> {table} =~ /^_/ ? $options -> {table} : uc $options -> {table};

	$options -> {table} = $options -> {table} =~ /^_/ ? qq {"$options->{table}"} : uc $options -> {table};

}

#############################################################################

sub wish_to_clarify_demands_for_table_columns {	

	my ($i, $options) = @_;
	
	$i -> {REMARKS} ||= delete $i -> {label};

	exists $i -> {NULLABLE} or $i -> {NULLABLE} = $i -> {name} eq 'id' ? 0 : 1;

	$i -> {COLUMN_DEF} ||= undef;

	$i -> {TYPE_NAME} = uc $i -> {TYPE_NAME};
	
	if ($i -> {TYPE_NAME} eq 'VARBINARY') {
	
		$i -> {TYPE_NAME}  = 'RAW';
				
		return;
		
	}

	if ($i -> {TYPE_NAME} eq 'TIMESTAMP') {
	
		$i -> {TYPE_NAME}  = 'DATE';
		
		$i -> {COLUMN_DEF} = 'SYSDATE';
		
		return;
		
	}

	if ($i -> {TYPE_NAME} =~ /(DATE|TIME)/) {

		$i -> {TYPE_NAME}  = 'DATE';
				
		return;

	}

	if ($i -> {TYPE_NAME} =~ /^(DECIMAL|NUMERIC)$/) {
		
		$i -> {TYPE_NAME} = 'NUMBER';
		
	}
	elsif ($i -> {TYPE_NAME} =~ /INT$/) {
		
		$i -> {TYPE_NAME} = 'NUMBER';
		
		$i -> {COLUMN_SIZE} = 
			
			$` eq 'TINY'   ? 3  :
			$` eq 'SMALL'  ? 5  :
			$` eq 'MEDIUM' ? 8  :
			$` eq 'BIG'    ? 22 :
			10;
			
	}
	
	if ($i -> {TYPE_NAME} eq 'NUMBER') {
	
		$i -> {COLUMN_SIZE}    ||= 22;
		
		$i -> {DECIMAL_DIGITS} ||= 0;
		
		return;
		
	}

	$i -> {TYPE_NAME} =~ s{^(LONG|MEDIUM)TEXT$}{CLOB};
		
	$i -> {TYPE_NAME} =~ s{BLOB$}{BLOB};
	
	if ($i -> {TYPE_NAME} =~ /LOB$/) {

		$i -> {COLUMN_DEF} = 'empty_' . (lc $i -> {TYPE_NAME}) . '()';
		
		return;

	}

	if ($i -> {TYPE_NAME} eq 'TEXT') {
	
		$i -> {TYPE_NAME} = 'VARCHAR2';

		$i -> {COLUMN_SIZE} = 4000;

	}
	elsif ($i -> {TYPE_NAME} =~ /CHAR/) {
	
		$i -> {TYPE_NAME} = 'VARCHAR2';

	}

	if ($i -> {TYPE_NAME} eq 'VARCHAR2') {

		$i -> {COLUMN_SIZE} ||= 255;

	}

}

################################################################################

sub wish_to_explore_existing_table_columns {

	my ($options) = @_;

	my $existing = {};

	sql_select_loop (
		
		q {
			SELECT 
				user_tab_columns.*
				, user_col_comments.comments
			FROM 
				user_tab_columns 
				LEFT JOIN user_col_comments ON (
					user_tab_columns.table_name = user_col_comments.table_name
					AND user_tab_columns.column_name = user_col_comments.column_name
				)
			WHERE
				user_tab_columns.table_name = ?
		}, 
		
		sub {
		
			my $name = lc $i -> {column_name};

			$i -> {data_default} =~ s{\s+$}{}gsm;

			if ($i -> {data_default} =~ /\'(.*)\'/sm) {
			
				$i -> {data_default} = $1;
			
			}
			
			$existing -> {$name} = my $def = {
			
				name       => $name,
			
				TYPE_NAME  => $i -> {data_type},

				COLUMN_DEF => $i -> {data_default},

				REMARKS    => $i -> {comments},

				NULLABLE   => ($i -> {nullable} eq 'N' ? 0 : 1),
				
			};
			
			if ($i -> {data_type} eq 'NUMBER') {
			
				$def -> {COLUMN_SIZE}    = $i -> {data_precision};
				$def -> {DECIMAL_DIGITS} = $i -> {data_scale};
			
			}
			elsif ($i -> {data_type} eq 'VARCHAR2') {
			
				$def -> {COLUMN_SIZE}    = $i -> {char_length};
			
			}
		
		},

		$options -> {table_name}

	);
#darn $existing;
	return $existing;

}

#############################################################################

sub __recompile_triggers_for_table {

	my ($table) = @_;
	
	sql_select_loop (
	
		"SELECT trigger_name FROM user_triggers WHERE table_name = ?", 
		
		sub {
		
			sql_do (qq {ALTER TRIGGER "$i->{trigger_name}" COMPILE});
		
		},
		
		$table,

	);

}

#############################################################################

sub __genereate_sql_fragment_for_column {

	my ($i) = @_;

	$i -> {SQL} = $i -> {TYPE_NAME} . (
					
		$i -> {TYPE_NAME} eq 'NUMBER'   ? " ($i->{COLUMN_SIZE}, $i->{DECIMAL_DIGITS})" :

		$i -> {TYPE_NAME} eq 'VARCHAR2' ? " ($i->{COLUMN_SIZE} CHAR)" :

		'');

	if ($i -> {COLUMN_DEF}) {
	
		if ($i -> {COLUMN_DEF} ne 'SYSDATE' && $i -> {COLUMN_DEF} !~ /\)/) {

			$i -> {COLUMN_DEF} =~ s{'}{''}g; #';
			
			$i -> {COLUMN_DEF} = "'$i->{COLUMN_DEF}'";

		}
	
		$i -> {SQL} .= " DEFAULT $i->{COLUMN_DEF}";
	
	}
	
	%$i = map {$_ => $i -> {$_}} qw (name SQL REMARKS NULLABLE TYPE_NAME);

}

#############################################################################

sub wish_to_update_demands_for_table_columns {

	my ($old, $new, $options) = @_;
	
	if ($old -> {TYPE_NAME} eq $new -> {TYPE_NAME}) {
	
		$new -> {$_} >= $old -> {$_} or $new -> {$_} = $old -> {$_} foreach 
		
			$old -> {TYPE_NAME} eq 'NUMBER' ? qw (COLUMN_SIZE DECIMAL_DIGITS) :

			$old -> {TYPE_NAME} eq 'VARCHAR2' ? qw (COLUMN_SIZE) :
			
			()

	}

	__genereate_sql_fragment_for_column ($_) foreach ($old, $new);

}

#############################################################################

sub wish_to_schedule_modifications_for_table_columns {

	my ($old, $new, $todo, $options) = @_;
	
	if ($old -> {REMARKS} ne $new -> {REMARKS}) {
	
		push @{$todo -> {comment}}, {name => $new -> {name}, REMARKS => delete $new -> {REMARKS}};
		
		delete $old -> {REMARKS};
		
		return if Dumper ($old) eq Dumper ($new);
	
	}
	
	if (

		($old -> {TYPE_NAME} ne $new -> {TYPE_NAME}) and ($old -> {TYPE_NAME} . $new -> {TYPE_NAME} =~ /(CHAR|LOB)/)

	) {
	
		push @{$todo -> {recreate}}, $new;
	
	}
	else {

		push @{$todo -> {alter}}, $new;

		push @{$todo -> {switch_nulls_on}}, $new if $old -> {NULLABLE} != $new -> {NULLABLE};

	}
	

}

#############################################################################

sub wish_to_actually_switch_nulls_on_table_columns {

	my ($items, $options) = @_;
#darn $items;	
	sql_do ("ALTER TABLE $options->{table} MODIFY (" . (join ', ', map {$_ -> {name} . ($_ -> {NULLABLE} ? ' NULL' : ' NOT NULL')} @$items) . ')');

}

#############################################################################

sub wish_to_actually_comment_table_columns {

	my ($items, $options) = @_;
	
	foreach my $i (@$items) {
	
		$i -> {REMARKS} =~ s{'}{''}g; #'

		sql_do ("COMMENT ON COLUMN $options->{table}.$i->{name} IS '$i->{REMARKS}'");
		
	}

}

#############################################################################

sub wish_to_actually_create_table_columns {	

	my ($items, $options) = @_;
	
	foreach my $i (@$items) {
	
		__genereate_sql_fragment_for_column ($i);
		
		$i -> {NULLABLE} or $i -> {SQL} .= ' NOT NULL';
	
	}

	wish_to_actually_alter_table_columns ($items, $options, 'ADD');
	
	wish_to_actually_comment_table_columns ([grep {$_ -> {REMARKS}} @$items], $options);
	
	__recompile_triggers_for_table ($options -> {table_name});

}

#############################################################################

sub wish_to_actually_alter_table_columns {	

	my ($items, $options, $verb) = @_;
	
	$verb ||= 'MODIFY';
	
	sql_do ("ALTER TABLE $options->{table} $verb (" . (join ', ', map {"$_->{name} $_->{SQL}"} @$items) . ')');

	__recompile_triggers_for_table ($options -> {table_name});

}

#############################################################################

sub wish_to_actually_recreate_table_columns {

	my ($items, $options) = @_;
	
	foreach my $i (@$items) {
	
		$i -> {NULLABLE} or $i -> {SQL} .= ' NOT NULL';

		foreach (
		
			"ALTER TABLE $options->{table} ADD           oracle_suxx    $i->{SQL} ", 
			"UPDATE      $options->{table} SET           oracle_suxx =  $i->{name}",
			"ALTER TABLE $options->{table} DROP COLUMN                  $i->{name}",
			"ALTER TABLE $options->{table} RENAME COLUMN oracle_suxx TO $i->{name}"
			
		) { sql_do ($_) }
		
	}

	wish_to_actually_comment_table_columns (@_);

	__recompile_triggers_for_table ($options -> {table_name});

}

1;