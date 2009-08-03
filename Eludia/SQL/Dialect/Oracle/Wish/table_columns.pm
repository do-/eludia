#############################################################################

sub wish_to_adjust_options_for_table_columns {

	my ($options) = @_;
	
	$options -> {key} = ['name'];
	
	$options -> {table} = $options -> {table} =~ /^_/ ? qq {"$options->{table}"} : uc $options -> {table};

}

#############################################################################

sub wish_to_clarify_demands_for_table_columns {	

	my ($i, $options) = @_;
	
	$i -> {REMARKS} ||= delete $i -> {label};

	exists $i -> {NULLABLE} or $i -> {NULLABLE} = 1;

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
				, user_tab_columns.coomments
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

			$existing -> {$name} = my $def = {
			
				TYPE_NAME  => $i -> {data_type},

				COLUMN_DEF => $i -> {data_default},

				REMARKS    => $i -> {comments},

				NULLABLE   => $i -> {NULLABLE} eq 'N' ? 0 : 1,
				
			};
			
			if ($i -> {data_type} eq 'NUMBER') {
			
				$def -> {COLUMN_SIZE}    = $i -> {data_precision};
				$def -> {DECIMAL_DIGITS} = $i -> {data_scale};
			
			}
			elsif ($i -> {data_type} eq /VARCHAR2$/) {
			
				$def -> {COLUMN_SIZE}    = $i -> {char_length};
			
			}
		
		},

		$options -> {table}

	);

	return $existing;

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
	
	foreach my $i ($old, $new) {
	
		$i -> {SQL} = $i -> {TYPE_NAME} .
						
			$i -> {TYPE_NAME} eq 'NUMBER'   ? " ($i->{COLUMN_SIZE}, $i->{DECIMAL_DIGITS})" :

			$i -> {TYPE_NAME} eq 'VARCHAR2' ? " ($i->{COLUMN_SIZE})" :

			'';

		if ($i -> {COLUMN_DEF}) {
		
			if ($i -> {COLUMN_DEF} ne 'SYSDATE' && $i -> {COLUMN_DEF} !~ /\)/) {

				$i -> {COLUMN_DEF} =~ s{'}{''}g; #';
				
				$i -> {COLUMN_DEF} = "'$i->{COLUMN_DEF}'";

			}
		
			$i -> {SQL} .= " DEFAULT $i->{COLUMN_DEF}";
		
		}

		$i -> {SQL} .= $i -> {NULLABLE} ? ' NULL' : ' NOT NULL';
		
		%$i = map {$_ => $i -> {$_}} qw (SQL REMARKS);

	}

}

#############################################################################

sub wish_to_schedule_modifications_for_table_columns {

	my ($old, $new, $todo, $options) = @_;
	
	if ($old -> {REMARKS} ne $new -> {REMARKS}) {
	
		push @{$todo -> {comment}}, {name => $new -> {name}, REMARKS => delete $new -> {REMARKS}};
		
		delete $old -> {REMARKS};
		
		return if Dumper ($old) eq Dumper ($new);
	
	}

	push @{$todo -> {$old -> {TYPE_NAME} eq 'VARCHAR2' and $new -> {TYPE_NAME} ne 'VARCHAR2' ? 'recreate' : 'alter'}}, $new;

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
	
	wish_to_actually_alter_table_columns ($items, $options, 'ADD');
	
	wish_to_actually_comment_table_columns (@_);

}

#############################################################################

sub wish_to_actually_alter_table_columns {	

	my ($items, $options, $verb) = @_;
	
	$verb ||= 'MODIFY';
	
	sql_do ("ALTER TABLE $options->{table} $verb (" . (join ', ', map {"$_->{name} $_->{SQL}"} @$items) . ')');

}

#############################################################################

sub wish_to_actually_recreate_table_columns {

	my ($items, $options) = @_;
	
	foreach my $i (@$items) {
	
		foreach (
		
			"ALTER TABLE $options->{table} ADD           oracle_suxx    $i->{SQL} ", 
			"UPDATE      $options->{table} SET           oracle_suxx =  $i->{name}",
			"ALTER TABLE $options->{table} DROP COLUMN                  $i->{name}",
			"ALTER TABLE $options->{table} RENAME COLUMN oracle_suxx TO $i->{name}"
			
		) sql_do ($_)
		
	}

	wish_to_actually_comment_table_columns (@_);

}

1;