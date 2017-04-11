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
	
	if ($i -> {TYPE_NAME} eq 'DECIMAL') {
	
		$i -> {COLUMN_SIZE}    ||= 22;
		
		$i -> {DECIMAL_DIGITS} ||= 0;
		
	}
		
	if ($i -> {TYPE_NAME} eq 'VARCHAR') {

		$i -> {COLUMN_SIZE} ||= 255;

	}

	if ($i -> {TYPE_NAME} eq 'TIMESTAMP') {

		$i -> {NULLABLE} = 0;
		
		$i -> {_EXTRA} = 'on update CURRENT_TIMESTAMP';

	}

}

################################################################################

sub wish_to_explore_existing_table_columns {

	my ($options) = @_;

	my $existing = {};
	
	my $pk = '';
	
	sql_select_loop ("SHOW KEYS FROM $options->{table} WHERE Key_name = 'PRIMARY'", sub {$pk = $i -> {Column_name}});

	sql_select_loop (
		
		q {
			SELECT 
				column_name
				, data_type
				, column_default
				, column_comment
				, is_nullable
				, numeric_precision
				, numeric_scale
				, character_maximum_length
				, extra
			FROM 
				information_schema.columns 
			WHERE 
				table_schema=database() 
				AND table_name = ?
		}, 
		
		sub {

			my $name = $i -> {column_name};
			
			$existing -> {$name} = my $def = {
			
				name       => $name,
			
				TYPE_NAME  => uc $i -> {data_type},

				COLUMN_DEF => $i -> {column_default},

				REMARKS    => length $i -> {column_comment} ? $i -> {column_comment} : undef,

				NULLABLE   => ($i -> {is_nullable} eq 'NO' ? 0 : 1),

			};
			
			$def -> {_EXTRA} = $i -> {extra} if $i -> {extra};
			
			$def -> {_PK}    = 1             if $name eq $pk;

			if ($def -> {TYPE_NAME} eq 'DECIMAL') {
			
				$def -> {COLUMN_SIZE}    = $i -> {numeric_precision};
				$def -> {DECIMAL_DIGITS} = $i -> {numeric_scale};
			
			}
			elsif ($def -> {TYPE_NAME} eq 'VARBINARY') {
			
				$def -> {COLUMN_DEF}     = $i -> {character_maximum_length};
			
			}
			elsif ($def -> {TYPE_NAME} =~ /CHAR$/) {
			
				$def -> {COLUMN_SIZE}    = $i -> {character_maximum_length};
			
			}
			elsif ($def -> {TYPE_NAME} eq 'TIMESTAMP') {
			
				$def -> {COLUMN_DEF}     = undef;
			
			}
		
		},

		$options -> {table}

	);

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

	$i -> {SQL} .= ' ' . $i -> {_EXTRA} if $i -> {_EXTRA};
	
	$i -> {SQL} .= ' PRIMARY KEY' if  $i -> {_PK};

	if (!$i -> {NULLABLE}) {
	
		$i -> {SQL} .= " NOT NULL";

	}

	if (defined $i -> {COLUMN_DEF}) {
	
		$i -> {COLUMN_DEF} =~ s{'}{''}g; #';

		$i -> {SQL} .= " DEFAULT '$i->{COLUMN_DEF}'";
	
	}

	($i -> {REMARKS} ||= '') =~ s{'}{''}g; #';

	$i -> {SQL} .= " COMMENT '$i->{REMARKS}'";

	%$i = map {$_ => $i -> {$_}} qw (name SQL REMARKS NULLABLE TYPE_NAME);

}

#############################################################################

sub wish_to_update_demands_for_table_columns {

	my ($old, $new, $options) = @_;
	
	__adjust_column_dimensions ($old, $new, {
	
		char    => qr {CHAR$},
	
		decimal => 'DECIMAL',

	});
	
	if (exists $old -> {_PK} && exists $new -> {_PK} && $old -> {_PK} == $new -> {_PK}) {
	
		delete $old -> {_PK};
		delete $new -> {_PK};
	
	}

	if (exists $old -> {_EXTRA} && exists $new -> {_EXTRA} && $old -> {_EXTRA} eq $new -> {_EXTRA}) {
	
		delete $old -> {_EXTRA};
		delete $new -> {_EXTRA};
	
	}
	
	__genereate_sql_fragment_for_column ($_) foreach ($old, $new);

}

#############################################################################

sub wish_to_schedule_modifications_for_table_columns {

	my ($old, $new, $todo, $options) = @_;

	$new -> {verb} = 'MODIFY';
	
	push @{$todo -> {create}}, $new;

}

#############################################################################

sub wish_to_actually_create_table_columns {	

	my ($items, $options) = @_;

	my $sql = "ALTER TABLE $options->{table} ENABLE KEYS";
	
	foreach my $i (@$items) {
	
		__genereate_sql_fragment_for_column ($i);
		
		$sql .= ', ' . ($i -> {verb} || 'ADD') . ' `' . $i -> {name} . '` ' . $i -> {SQL};
	
	}

	sql_do ($sql);

}

1;