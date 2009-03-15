#############################################################################

sub wish_to_adjust_options_for_table_keys {

	my ($options) = @_;
	
	$options -> {key} = ['global_name'];

}

#############################################################################

sub wish_to_clarify_demands_for_table_keys {	

	my ($i, $options) = @_;

	$i -> {global_name}   = sql_select_scalar ("SELECT ID FROM $conf->{systables}->{__voc_replacements} WHERE TABLE_NAME = ? AND OBJECT_NAME = ? AND OBJECT_TYPE = 1", $options -> {table}, $i -> {name}) if ($conf -> {core_voc_replacement_use});

	$i -> {global_name} ||= 'OOC_' . Digest::MD5::md5_base64 ($options -> {table} . '_' . $i -> {name});

	ref $i -> {parts} eq ARRAY or $i -> {parts} = [split /\,/, $i -> {parts}];

	foreach my $part (@{$i -> {parts}}) {
	
		$part = lc $part;
		
		$part =~ s{\s}{}gsm;
	
		if ($part =~ /^(\w+)\((\d+)\)$/) {
		
			my ($column, $width) = ($1, $2);
			
			my $type = lc $options -> {table_def} -> {columns} -> {$column} -> {TYPE_NAME};

			if ($type =~ /char/) {

				$part = "substr($column,1,$width)";

			} 
			elsif ($type =~ /(lob|text)$/) {

				$part = "substr(to_char($column),1,$width)";

			} 
			else {

				die Dumper ($options);

			}
			
		
		}

	}

}

################################################################################

sub wish_to_explore_existing_table_keys {

	my ($options) = @_;

	my $existing = {};

	my $uc_table_name = $options -> {table} =~ /^_/ ? $options -> {table} : uc $options -> {table};

	sql_select_loop (<<EOS, sub {$existing -> {$i -> {index_name}} -> [$i -> {column_position} - 1] = lc $i -> {column_name}}, $uc_table_name);
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

	sql_select_loop (<<EOS, sub {$existing -> {$i -> {index_name}} -> [$i -> {column_position} - 1] = lc $i -> {column_expression}}, $uc_table_name);
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

	return $existing;

}

#############################################################################

sub wish_to_actually_create_table_keys {	

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

sub wish_to_actually_alter_table_keys {

	my ($items, $options) = @_;

	foreach my $i (@$items) {
	
		sql_do ("DROP INDEX \"$i->{global_name}\"");
	
	}
	
	wish_to_actually_create_table_keys (@_);

}

1;