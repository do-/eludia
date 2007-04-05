package DBIx::ModelUpdate::Oracle;

no warnings;

use Data::Dumper;

our @ISA = qw (DBIx::ModelUpdate);

################################################################################

sub _db_model_checksums {
	return '"_db_model_checksums"';
}

################################################################################

sub unquote_table_name {
	my ($self, $name) = @_;

	$name =~ s{$self->{quote}}{}g;

	if ($name !~ /\./ || $name =~ s/^$self->{schema}\.//i) {
		return lc $name;
	}

	return undef;
}

################################################################################

sub prepare {

	my ($self, $sql) = @_;
	
#print STDERR "prepare (pid=$$): $sql\n";

	return $self -> {db} -> prepare ($sql);

}

################################################################################

sub get_keys {

	my ($self, $table_name) = @_;
	
	my $keys = {};

	my $uc_table_name = $table_name =~ /^_/ ? $table_name : uc $table_name;
	
	my $st = $self -> prepare (<<EOS);
		SELECT 
			* 
		FROM 
			user_indexes
			, user_ind_columns 
		WHERE 
			user_ind_columns.index_name = user_indexes.index_name 
			AND user_indexes.table_name = ?
EOS
	
	$st -> execute ($uc_table_name);
		
	while (my $r = $st -> fetchrow_hashref) {
		
		my $name = lc $r -> {INDEX_NAME};
		$name =~ s/^${table_name}_//;
		
		next if $name eq 'PRIMARY';
		
		my $column = lc $r -> {COLUMN_NAME};
		
		if (exists $keys -> {$name}) {
			$keys -> {$name} -> {columns} .= ',' . $column;
		}
		else {
			$keys -> {$name} = {columns => $column};
		}
	
	}
	
#print STDERR Dumper ($keys);
		
	return $keys;

}

################################################################################

sub get_tables {

	my ($self, $options) = @_;
	
	my $st = $self -> prepare ("SELECT table_name FROM user_tables");
	$st -> execute;
	my $tables = {};
	
	while (my $r = $st -> fetchrow_hashref) {
		my $name = lc ($r -> {TABLE_NAME});
		$name =~ s{\W}{}g;
		$tables -> {$name} = {
#			columns => $self -> get_columns ($name, $options), 
#			keys => $self -> get_keys ($name),
		}
	}	

	$st -> finish;

#print STDERR "get_tables (pid=$$): $tables = " . Dumper ($tables);
	
	foreach my $name (keys %$tables) {
		$tables -> {$name} -> {columns} = $self -> get_columns ($name, $options);
		$tables -> {$name} -> {keys}    = $self -> get_keys ($name);
	}
	
	return $tables;

}

################################################################################

sub get_columns {

	my ($self, $table_name, $options) = @_;
	
	$options -> {default_columns} ||= {};

	my $uc_table_name = $table_name =~ /^_/ ? $table_name : uc $table_name;
			
	$pk_column = 'id';
		
	my $fields = {};
	
	my $st = $self -> prepare (<<EOS);
		SELECT
			COLUMN_NAME
			, DATA_LENGTH
			, DATA_PRECISION
			, DATA_SCALE
			, DATA_TYPE
--			, DATA_DEFAULT
			, NULLABLE
		FROM user_tab_columns WHERE table_name = ?
EOS

	$st -> execute ($uc_table_name);

	while (my $r = $st -> fetchrow_hashref) {
				
		my $name = lc $r -> {COLUMN_NAME};
		next if $options -> {default_columns} -> {$name};

		my $rr = {};
		
		$rr -> {COLUMN_SIZE} = $r -> {DATA_PRECISION} || $r -> {DATA_LENGTH};
		
		$rr -> {DECIMAL_DIGITS} = $r -> {DATA_SCALE} if $r -> {DATA_SCALE};

		$rr -> {TYPE_NAME} = lc $r -> {DATA_TYPE};
		$rr -> {TYPE_NAME} =~ s{2$}{};
		if ($rr -> {TYPE_NAME} eq 'number') {
			$rr -> {TYPE_NAME} = $r -> {DATA_SCALE} ? 'decimal' : 'int';
		}

		$rr -> {COLUMN_SIZE} ||= 255 if $rr -> {TYPE_NAME} eq 'varchar';
		
		if ($r -> {DATA_DEFAULT}) {
			$rr -> {COLUMN_DEF} = $r -> {DATA_DEFAULT};
			$rr -> {COLUMN_DEF} =~ s{^\'}{};
			$rr -> {COLUMN_DEF} =~ s{\'$}{};
		}
		
		if ($name eq $pk_column) {
			$rr -> {_PK} = 1;
			$rr -> {_EXTRA} = 'auto_increment';
		}
		
		$rr -> {NULLABLE} = $r -> {NULLABLE} eq 'Y' ? 1 : 0;
				
		$fields -> {$name} = $rr;
	
	}
	
	return $fields;

}

################################################################################

sub get_canonic_type {

	my ($self, $definition, $should_change) = @_;
	
	$type_name = lc $definition -> {TYPE_NAME};
	
	return 'VARCHAR2' if $type_name eq 'varchar';
	return 'NUMBER'   if $type_name =~ /int$/;
	return 'NUMBER'   if $type_name eq 'decimal';
	return 'CLOB'     if $type_name eq 'text';
	if ($type_name =~ /date|time/) {
		if ($should_change && $type_name =~ /timestamp/) {
			$definition -> {COLUMN_DEF} = 'SYSDATE';
		}
		return 'DATE';
	};
	
	return uc $type_name;

}    

################################################################################

sub gen_column_definition {

	my ($self, $name, $definition, $table_name) = @_;
	
	$definition -> {NULLABLE} = 1 unless defined $definition -> {NULLABLE};
	
	my $type = $self -> get_canonic_type ($definition, 1);

	my $sql = " $name $type";
		
	if ($definition -> {COLUMN_SIZE}) {	
		$sql .= ' (' . $definition -> {COLUMN_SIZE};		
		$sql .= ',' . $definition -> {DECIMAL_DIGITS} if $definition -> {DECIMAL_DIGITS};		
		$sql .= ')';	
	}
	
#	$sql .= ' ' . $definition -> {_EXTRA} if $definition -> {_EXTRA};

	if ($type eq 'CLOB') {
		$sql .= ' DEFAULT empty_clob()';
	} elsif (exists $definition -> {COLUMN_DEF}) {
		$sql .= ' DEFAULT ' . ($definition -> {COLUMN_DEF} eq 'SYSDATE' ? 'SYSDATE' : $self -> {db} -> quote ($definition -> {COLUMN_DEF}));
	}

	$sql .= ' CONSTRAINT nn_' . $table_name . '_' . $name . ' NOT NULL' unless $definition -> {NULLABLE};
	$sql .= ' CONSTRAINT pk_' . $table_name . '_' . $name . ' PRIMARY KEY' if $definition -> {_PK};
	
	return $sql;
	
}

################################################################################

sub create_table {

	my ($self, $name, $definition) = @_;

	$name = $self -> unquote_table_name ($name);
	my $q = $name =~ /^_/ ? $self -> {quote} : '';

	$self -> do ("CREATE TABLE $q$name$q (\n  " . (join "\n ,", map {$self -> gen_column_definition ($_, $definition -> {columns} -> {$_}, $name)} keys %{$definition -> {columns}}) . "\n)\n");

	my $pk_column = (grep {$definition -> {columns} -> {$_} -> {_PK}} keys %{$definition -> {columns}}) [0];

	if ($pk_column) {
		$self -> do ("CREATE SEQUENCE $q${name}_seq$q START WITH 1 INCREMENT BY 1");
	
		$self -> do (<<EOS);
			CREATE TRIGGER $q${name}_id_trigger$q BEFORE INSERT ON $q${name}$q
			FOR EACH ROW
			WHEN (new.$pk_column is null)
			BEGIN
				SELECT $q${name}_seq$q.nextval INTO :new.$pk_column FROM DUAL;
			END;		
EOS

		$self -> do ("ALTER TRIGGER $q${name}_id_trigger$q COMPILE");
		$self -> do ("ALTER TABLE $q${name}$q ENABLE ALL TRIGGERS");
	}

}

################################################################################

sub add_columns {

	my ($self, $name, $columns) = @_;

	$name = $self -> unquote_table_name ($name);
	my $q = $name =~ /^_/ ? $self -> {quote} : '';

	my $sql = "ALTER TABLE $q$name$q ADD (\n  " . (join "\n ,", map {$self -> gen_column_definition ($_, $columns -> {$_}, $name)} keys %$columns) . "\n)\n";
			
	$self -> do ($sql);

}

################################################################################

sub get_column_def {

	my ($self, $column) = @_;
	
	return '' if $column -> {_PK};
	
	return $column -> {COLUMN_DEF} if defined $column -> {COLUMN_DEF};
	
	return 0 if lc $column -> {TYPE_NAME} =~ /bit|int|float|numeric|decimal|number/;
	
	return '';

}    

################################################################################

sub update_column {

	my ($self, $name, $c_name, $existing_column, $c_definition) = @_;
	
	my $eq_types = ($self -> get_canonic_type ($existing_column) eq $self -> get_canonic_type ($c_definition, 1));
	my $eq_sizes = ($existing_column -> {COLUMN_SIZE} >= $c_definition -> {COLUMN_SIZE});

	my $existing_def = $self -> get_column_def ($existing_column);
	my $column_def = $self -> get_column_def ($c_definition);
	my $eq_defaults = ($existing_def eq $column_def);

#print STDERR '$existing_type = ', $self -> get_canonic_type ($existing_column -> {TYPE_NAME}), "\n";
#print STDERR '$c_type = ', $self -> get_canonic_type ($c_definition -> {TYPE_NAME}), "\n";
#print STDERR "\$eq_types = $eq_types\n";
#print STDERR "\$eq_sizes = $eq_sizes\n";
#print STDERR "\$eq_defaults = $eq_defaults\n";

	return if $eq_types && $eq_sizes && $eq_defaults;
	
	return if $self -> get_canonic_type ($existing_column) =~ /LOB/;
	
	$c_definition -> {_PK} = 0 if ($existing_column -> {_PK} == 1);
	delete $c_definition -> {NULLABLE} if (exists $existing_column -> {NULLABLE} && $existing_column -> {NULLABLE} == 0);

	$name = $self -> unquote_table_name ($name);
	my $q = $name =~ /^_/ ? $self -> {quote} : '';

	my $sql = "ALTER TABLE $q$name$q MODIFY" . $self -> gen_column_definition ($c_name, $c_definition, $name);
	
	$self -> do ($sql);
	
}

################################################################################

sub insert_or_update {

	my ($self, $name, $data, $table) = @_;
	
	my $pk_column = 'id';
	
	$name = $self -> unquote_table_name ($name);
	my $q = $name =~ /^_/ ? $self -> {quote} : '';

	my $st = $self -> prepare ("SELECT * FROM $q$name$q WHERE $pk_column = ?");
	$st -> execute ($data -> {$pk_column});
	my $existing_data = $st -> fetchrow_hashref;
	$st -> finish;
	
	if ($existing_data -> {uc $pk_column}) {
	
		my @terms = ();
		
		while (my ($key, $value) = each %$data) {
			next if $key eq $pk_column;
			next if $value eq $existing_data -> {uc $key};
			push @terms, "$key = " . $self -> {db} -> quote ($value);
		}
		
		if (@terms) {
			$self -> do ("UPDATE $q$name$q SET " . (join ', ', @terms) . " WHERE $pk_column = " . $data -> {$pk_column});
		}
	
	}
	else {
		my @names = keys %$data;
		$self -> do ("INSERT INTO $q$name$q (" . (join ', ', @names) . ") VALUES (" . (join ', ', map {$self -> {db} -> quote ($data -> {$_})} @names) . ')');
	}

}

################################################################################

sub drop_index {
	
	my ($self, $table_name, $index_name) = @_;

	$table_name = $self -> unquote_table_name ($table_name);
	my $q = $table_name =~ /^_/ ? $self -> {quote} : '';

	warn "DROP INDEX $q${table_name}_${index_name}$q\n";
	$self -> {db} -> do ("DROP INDEX $q${table_name}_${index_name}$q");
	
}

################################################################################

sub create_index {
	
	my ($self, $table_name, $index_name, $index_def, $table_def) = @_;

	$table_name = $self -> unquote_table_name ($table_name);
	my $q = $table_name =~ /^_/ ? $self -> {quote} : '';

	while ($index_def =~ /(\w+)\((\d+)\)/) {
		if ($table_def -> {columns} -> {$1} -> {TYPE_NAME} =~ /char/i ) {
			$index_def =~ s/(\w+)\((\d+)\)/substr($1, 1, $2)/;
		} elsif ($table_def -> {columns} -> {$1} -> {TYPE_NAME} =~ /lob$/i || $table_def -> {columns} -> {$1} -> {TYPE_NAME} =~ /text$/i) {
			$index_def =~ s/(\w+)\((\d+)\)/substr(to_char($1), 1, $2)/;
		} else {
			warn Dumper ($table_def);
			die;
		}
	}
	
	warn "CREATE INDEX $q${table_name}_${index_name}$q ON $q$table_name$q ($index_def)\n";
	$self -> {db} -> do ("CREATE INDEX $q${table_name}_${index_name}$q ON $q$table_name$q ($index_def)");
	
}

1;