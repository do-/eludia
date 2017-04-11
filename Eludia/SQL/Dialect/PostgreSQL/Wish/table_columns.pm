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
	
	if ($i -> {TYPE_NAME} eq 'INT') {
		
		$i -> {TYPE_NAME} = 'INT4';
				
	}

	if ($i -> {TYPE_NAME} =~ /(CHAR|TEXT)/) {
		
		$i -> {TYPE_NAME} = 'TEXT';
				
	}

	if ($i -> {TYPE_NAME} eq 'VARBINARY' or $i -> {TYPE_NAME} eq 'BLOB') {
	
		$i -> {TYPE_NAME}  = 'BYTEA';
						
	}

	if ($i -> {TYPE_NAME} eq 'LONGBLOB') {
	
		$i -> {TYPE_NAME}  = 'OID';
						
	}

	if ($i -> {TYPE_NAME} eq 'TIMESTAMP') {

		$i -> {COLUMN_DEF} = 'now()';
				
	}

	if ($i -> {TYPE_NAME} eq 'DATETIME') {

		$i -> {TYPE_NAME}  = 'TIMESTAMP';
				
	}

	if ($i -> {TYPE_NAME} eq 'DECIMAL') {
		
		$i -> {TYPE_NAME} = 'NUMERIC';
		
	}

	if ($i -> {TYPE_NAME} eq 'NUMERIC') {
	
		$i -> {COLUMN_SIZE}    ||= 10;
		
		$i -> {DECIMAL_DIGITS} ||= 0;
				
	}
	
	if ($i -> {TYPE_NAME} =~ /(MEDIUM|BIG)INT$/) {
		
		$i -> {TYPE_NAME} = 'INT8';
		
	}

	if ($i -> {TYPE_NAME} =~ /(TINY|SMALL)INT$/) {
		
		$i -> {TYPE_NAME} = 'INT2';
				
	}
	
	if (!$i -> {NULLABLE} && $i -> {TYPE_NAME} =~ /^(NUM|INT)/ && $i -> {name} ne 'id') {
	
		$i -> {COLUMN_DEF} ||= 0;
	
	}
	
	if (defined $i -> {COLUMN_DEF}) {
	
		$i -> {COLUMN_DEF} .= '';
	
	}

}

################################################################################

sub wish_to_explore_existing_table_columns {

	my ($options) = @_;
		
	$options -> {_cache} or sql_select_loop (q {
	
			SELECT 
				pg_attribute.*
				, pg_type.typname
				, pg_attrdef.adsrc
				, pg_description.description
				, pg_class.relname
			FROM 
				pg_namespace
				LEFT JOIN pg_class ON (
					pg_class.relnamespace = pg_namespace.oid
					AND pg_class.relkind = 'r'
				)
				LEFT JOIN pg_attribute ON (
					pg_attribute.attrelid = pg_class.oid
					AND pg_attribute.attnum > 0
					AND NOT pg_attribute.attisdropped
				)
				LEFT JOIN pg_type ON pg_attribute.atttypid = pg_type.oid
				LEFT JOIN pg_attrdef ON (
					pg_attrdef.adrelid = pg_attribute.attrelid
					AND pg_attrdef.adnum = pg_attribute.attnum
				)
				LEFT JOIN pg_description ON (
					pg_description.objoid = pg_attribute.attrelid
					AND pg_description.objsubid = pg_attribute.attnum
				)
			WHERE
				pg_namespace.nspname = current_schema()

		}, 
		
		sub {
		
			my $name = $i -> {attname};

			$options -> {_cache} -> {$i -> {relname}} -> {$name} = (my $r = {
			
				name       => $name,
			
				TYPE_NAME  => uc $i -> {typname},
			
				REMARKS    => $i -> {description},
				
				NULLABLE   => 1 - $i -> {attnotnull},
				
				COLUMN_DEF => undef,

			});
			
			if (length $i -> {adsrc} && $name ne 'id') {
			
				$r -> {COLUMN_DEF} = $i -> {adsrc} . '';
			
				$r -> {COLUMN_DEF} =~ s{\:\:\w+$}{};

			}
			
		}

	);

	$options -> {_cache} -> {$options -> {table}};

}

#############################################################################

sub __genereate_sql_fragment_for_column {

	my ($i) = @_;
	
	return if $i -> {SQL};

	$i -> {TYPE} = $i -> {TYPE_NAME} . (
					
		$i -> {TYPE_NAME} eq 'NUMERIC'   ? " ($i->{COLUMN_SIZE}, $i->{DECIMAL_DIGITS})" :

		'');
		
	$i -> {SQL} = $i -> {TYPE};

	if (defined $i -> {COLUMN_DEF}) {
	
		if ($i -> {COLUMN_DEF} !~ /\)/) {

			$i -> {COLUMN_DEF} =~ s{'}{''}g; #';
			
			$i -> {COLUMN_DEF} = "'$i->{COLUMN_DEF}'";

		}

		$i -> {SQL} .= " DEFAULT $i->{COLUMN_DEF}";
	
	}

	if (!$i -> {NULLABLE}) {

		$i -> {SQL} .= " NOT NULL";

	}
	
	%$i = map {$_ => $i -> {$_}} qw (name SQL REMARKS NULLABLE TYPE_NAME TYPE COLUMN_DEF);

}

#############################################################################

sub wish_to_update_demands_for_table_columns {

	my ($old, $new, $options) = @_;
	
	__adjust_column_dimensions ($old, $new, {
	
		char    => qr {^-},
	
		decimal => 'NUMERIC',

	});
	
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

	if ($old -> {TYPE} ne $new -> {TYPE}) {
	
		push @{$new -> {actions}}, "TYPE $new->{TYPE}";
	
	}

	if ($old -> {COLUMN_DEF} ne $new -> {COLUMN_DEF}) {
	
		push @{$new -> {actions}}, $new -> {COLUMN_DEF} eq '' ? "DROP DEFAULT" : "SET DEFAULT $new->{COLUMN_DEF}";
	
	}

	if (!$old -> {NULLABLE} and $new -> {NULLABLE}) {
	
		push @{$new -> {actions}}, "DROP NOT NULL";
	
	}

	if ($old -> {NULLABLE} and !$new -> {NULLABLE}) {
	
		push @{$new -> {actions}}, "SET NOT NULL";
	
	}
	
	push @{$todo -> {create}}, $new;

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
	
	my @to_comment = ();
	
	my @actions    = ();
	
	foreach my $i (@$items) {
	
		if ($i -> {actions}) {
		
			push @actions, map {"ALTER $i->{name} $_"} @{$i -> {actions}};
			
		}
		else {
		
			next if $i -> {name} eq 'id';
		
			__genereate_sql_fragment_for_column ($i);

			push @actions, qq {ADD "$i->{name}" $i->{SQL}};
			
			push @to_comment, $i if $i -> {REMARKS};
		
		}
	
	}
	
	sql_do ("ALTER TABLE $options->{table} " . (join ', ', @actions)) if @actions;
	
	wish_to_actually_comment_table_columns (\@to_comment, $options);

}

1;