#############################################################################

sub wish_to_adjust_options_for_table_keys {

	my ($options) = @_;
	
	$options -> {key} = ['def'];

}

#############################################################################

sub wish_to_clarify_demands_for_table_keys {	

	my ($i, $options) = @_;

	$i -> {global_name} = sql_mangled_name ($options -> {table} . '_' . delete $i -> {name});

	ref $i -> {parts} eq ARRAY or $i -> {parts} = [split /\,/, $i -> {parts}];

	foreach my $part (@{$i -> {parts}}) {
	
		$part = uc $part;
		
		$part =~ s{\s}{}gsm;
	
		if ($part =~ /^(\w+)\((\d+)\)$/) {
		
			my ($column, $width) = ($1, $2);
			
			my $type = uc $options -> {table_def} -> {columns} -> {lc $column} -> {TYPE_NAME};

			if ($type =~ /CHAR/) {

				$part = qq{SUBSTR("$column",1,$width)};

			} 
			elsif ($type =~ /(LOB|TEXT)$/) {

				$part = qq{SUBSTR(TO_CHAR("$column"),1,$width)};

			} 
			else {

				die Dumper ($options);

			}
			
		
		}

	}
	
	$i -> {def} = join ', ', @{$i -> {parts}};

}

################################################################################

sub wish_to_explore_existing_table_keys {

	my ($options) = @_;

	my %k = ();

	sql_select_loop (<<EOS, sub {$k {$i -> {index_name}} -> [$i -> {column_position} - 1] = uc $i -> {column_name}}, uc_table_name ($options -> {table}));
		SELECT 
			user_indexes.index_name
			, user_ind_columns.column_name
			, user_ind_columns.column_position
		FROM 
			user_indexes
			INNER JOIN user_ind_columns ON user_ind_columns.index_name = user_indexes.index_name
		WHERE
			user_indexes.index_type LIKE '%NORMAL%'
			AND user_indexes.table_name = ?
EOS

	sql_select_loop (<<EOS, sub {$k {$i -> {index_name}} -> [$i -> {column_position} - 1] = uc $i -> {column_expression}; $k {$i -> {index_name}} -> [$i -> {column_position} - 1] =~ s/SYS_OP_C2C/TO_CHAR/g;}, uc_table_name ($options -> {table}));
		SELECT 
			user_indexes.index_name
			, user_ind_expressions.column_expression
			, user_ind_expressions.column_position
		FROM 
			user_indexes
			INNER JOIN user_ind_expressions ON user_ind_expressions.index_name = user_indexes.index_name
		WHERE
			user_indexes.index_type LIKE '%NORMAL%'
			AND user_indexes.table_name = ?
EOS


	my $existing = {};
	
	while (my ($global_name, $parts) = each %k) {
	
		my $i = {
		
			global_name => $global_name,
			
			parts       => $parts,
			
			def         => join ', ', @$parts,
		
		};
		
		next if $i -> {def} eq 'id';
	
		$existing -> {$i -> {def}} = $i;
	
	}

	return $existing;

}

#############################################################################

sub wish_to_update_demands_for_table_keys {

	my ($old, $new, $options) = @_;
	
	$new -> {global_name} = $old -> {global_name};

}

#############################################################################

sub wish_to_schedule_modifications_for_table_keys {

	my ($old, $new, $todo, $options) = @_;

	push @{$todo -> {create}}, $new;
	
}

#############################################################################

sub wish_to_actually_create_table_keys {

	my ($items, $options) = @_;
	
	if ($options -> {table} =~ /^_/) {
	
		$options -> {table} = '"' . $options -> {table} . '"';
	
	}
	
	foreach my $i (@$items) {
	
		eval { sql_do (qq {DROP INDEX \"$i->{global_name}\"})};

		sql_do (qq {CREATE INDEX \"$i->{global_name}\" ON $options->{table} ($i->{def})});
	
	}

	
}

1;