#############################################################################

sub wish_to_adjust_options_for_table_columns {

	my ($options) = @_;
	
	$options -> {key} = ['global_name'];

}

#############################################################################

sub wish_to_clarify_demands_for_table_columns {	

	my ($i, $options) = @_;
	
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
		
	$i -> {TYPE_NAME} =~ s{^.*BLOB$}{BLOB};
	
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

	my $existing = {id => {_PK => 1}};

	sql_select_loop (
		
		'SELECT * FROM user_tab_columns WHERE table_name = ?', 
		
		sub {
		
			my $name = lc $i -> {column_name};
			
			return if $name eq 'id';

			my $def = {
			
				TYPE_NAME  => $i -> {data_type},
				
				COLUMN_DEF => $i -> {data_default},
				
			};
			
			if ($i -> {data_type} eq 'NUMBER') {
			
				$def -> {COLUMN_SIZE}    = $i -> {data_precision};
				$def -> {DECIMAL_DIGITS} = $i -> {data_scale};
			
			}
			elsif ($i -> {data_type} =~ /VARCHAR/) {
			
				$def -> {COLUMN_SIZE}    = $i -> {char_length};
			
			}
									
			$existing -> {$name} = $def;
		
		},
		
		uc_table_name ($options -> {table})
		
	);

	return $existing;

}

#############################################################################

sub wish_to_update_demands_for_table_columns {

	my ($old, $new, $options) = @_;

	if ($old -> {_PK}) {
			
		foreach (keys %$new) {$old -> {$_} = $new -> {$_}}

		$new -> {_PK} = 1;
		
		return;
	
	}
	
	if ($old -> {TYPE_NAME} eq 'NUMBER' && $new -> {TYPE_NAME} eq 'NUMBER') {
	
		foreach my $field ('COLUMN_SIZE', 'DECIMAL_DIGITS') {

			$new -> {$field} >= $old -> {$field} or $new -> {$field} = $old -> {$field};

		}
		
	}	

}

#############################################################################

sub wish_to_actually_create_table_columns {	

	my ($items, $options) = @_;
	
	if ($options -> {table} =~ /^_/) {
	
		$options -> {table} = '"' . $options -> {table} . '"';
	
	}
	
	foreach my $i (@$items) {
	
		eval { sql_do ("CREATE INDEX \"$i->{global_name}\" ON $options->{table} (@{[ join ', ', @{$i -> {parts}} ]})") };
		
		next if $@ =~ /ORA-01408/;
		
		die $@ if $@;	
	
	}

	
}

#############################################################################

sub wish_to_actually_alter_table_columns {

	my ($items, $options) = @_;
	
	wish_to_actually_create_table_columns (@_);

}

1;