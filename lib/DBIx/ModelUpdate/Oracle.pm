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
	
	return $self -> {db} -> prepare ($sql);

}

################################################################################

sub get_keys {

	my ($self, $table_name, $core_voc_replacement_use) = @_;
	
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

		my $id_name = lc $r -> {INDEX_NAME};		

		my $name;

		if ($core_voc_replacement_use) {

			my $core_name = $self -> {__voc_replacements};

			if ($id_name =~ s/^IDX_//i) {

				$name = $self -> sql_select_scalar ("SELECT OBJECT_NAME FROM $core_name WHERE ID=$id_name AND OBJECT_TYPE=1");
			}
			else {

				$name = $id_name;

				$name =~ s/^${table_name}_//;	
			}
		}
		else {

			$name = $id_name;

			$name =~ s/^${table_name}_//;	
		}
		
		next if $name eq 'PRIMARY';
		
		my $column = lc $r -> {COLUMN_NAME};
		
		if (exists $keys -> {$name}) {
			$keys -> {$name} -> {columns} .= ',' . $column;
		}
		else {
			$keys -> {$name} = {columns => $column};
		}
	
	}
			
	return $keys;

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

	my $type_name = lc $definition -> {TYPE_NAME};
	
	if ($type_name =~ /int$/) {
	
		$definition -> {COLUMN_SIZE} ||= 
		
			$type_name eq 'int'       ? 10 : 
			$type_name eq 'tinyint'   ? 3  : 
			$type_name eq 'bigint'    ? 22 : 
			$type_name eq 'smallint'  ? 5  : 
			$type_name eq 'mediumint' ? 8  :
			undef;
		
		return 'NUMBER';
	
	}
	
	return 'NUMBER' if $type_name eq 'decimal';

	my $utf = $self -> {characterset} =~ /UTF/i;

	my $N = $utf ? 'N' : '';
	
	if ($type_name eq 'text') {
	
		$definition -> {COLUMN_SIZE} ||= $utf ? 2000 : 4000;
	
	}

	return $N . 'VARCHAR2' if $type_name =~ /char$/;
	return $N . 'VARCHAR2' if $type_name eq 'text';
	return $N . 'CLOB'     if $type_name eq 'longtext';
	return 'RAW'           if $type_name eq 'varbinary';
	return 'BLOB'          if $type_name eq 'longblob';
			
	if ($type_name =~ /date|time/) {
	
		$definition -> {COLUMN_DEF} = 'SYSDATE' if $should_change && ($type_name eq 'timestamp');
		
		return 'DATE';
		
	};
	
	return uc $type_name;

}    

################################################################################

sub gen_column_definition {

	my ($self, $name, $definition, $table_name, $core_voc_replacement_use) = @_;
	
	$definition -> {NULLABLE} = 1 unless defined $definition -> {NULLABLE};
	
	my $type = $self -> get_canonic_type ($definition, 1);

	if (lc $name eq 'date') {
		$name = '"'.$name.'"';
	}
	
	my $sql = " $name $type";
		
	if ($definition -> {COLUMN_SIZE} && !($type eq 'CLOB' || $type eq 'NCLOB' || $type eq 'DATE' || $type eq 'BLOB')) {	
		$sql .= ' (' . $definition -> {COLUMN_SIZE};		
		$sql .= ',' . $definition -> {DECIMAL_DIGITS} if $definition -> {DECIMAL_DIGITS};		
		$sql .= ')';	
	}
	
	if ($type eq 'CLOB' || $type eq 'NCLOB') {
		$sql .= ' DEFAULT empty_clob()';
	} 
	elsif (exists $definition -> {COLUMN_DEF}) {
		$sql .= ' DEFAULT ' . ($definition -> {COLUMN_DEF} eq 'SYSDATE' ? 'SYSDATE' : $self -> {db} -> quote ($definition -> {COLUMN_DEF}));
	}

	my ($nn_constraint_name, $pk_constraint_name) = ('nn_' . $table_name . '_' . $name, 'pk_' . $table_name . '_' . $name);

	if ($core_voc_replacement_use) {	
		unless ($definition -> {NULLABLE}) {
		   if (uc $table_name ne uc $self -> {__voc_replacements}) { 	

			my $index_id = voc_replacements ($self ,$table_name, $nn_constraint_name, 1,'CREATE');
	
			$sql .= " CONSTRAINT $index_id NOT NULL"; 
		   }
		   else {
			$sql .= " CONSTRAINT $nn_constraint_name NOT NULL"; 		
		   }

		}
		if ($definition -> {_PK}) {
		   if (uc $table_name ne uc $self -> {__voc_replacements}) { 	

			my $index_id = voc_replacements ($self ,$table_name, $pk_constraint_name, 1,'CREATE');
		
			$sql .= " CONSTRAINT $index_id PRIMARY KEY"; 
		   }
		   else {
			$sql .= " CONSTRAINT $pk_constraint_name PRIMARY KEY"; 		
		   }
	    
		}
	}
	else {
		if (length ($nn_constraint_name ) > 30) {
				my ($i, $cn) = ($self -> {nn_constraint_num} || 0);
				$nn_constraint_name = substr ($nn_constraint_name, 0, 25);
				while ($self -> sql_select_scalar ('SELECT constraint_name FROM all_constraints WHERE owner = ? AND constraint_name = ?', $self->{schema}, $nn_constraint_name . "_$i")) {
					$i ++;
				}
				$nn_constraint_name .= "_$i";
			
				$self -> {nn_constraint_num} = $i + 1;			
		}
	
		if (length ($pk_constraint_name ) > 30) {
				my $i = 0;
				$pk_constraint_name = substr ($pk_constraint_name, 0, 25);
				while ($self -> sql_select_scalar ('SELECT constraint_name FROM all_constraints WHERE owner = ? AND constraint_name = ?', $self->{schema}, $pk_constraint_name . "_$i")) {
					$i ++;
				}
				$pk_constraint_name .= "_$i";			
		}
	
		$sql .= " CONSTRAINT $nn_constraint_name NOT NULL" unless $definition -> {NULLABLE};
		$sql .= " CONSTRAINT $pk_constraint_name PRIMARY KEY" if $definition -> {_PK};
			
	}

	return $sql;
	
}

################################################################################

sub create_table {

	my ($self, $name, $definition, $core_voc_replacement_use) = @_;

	$name = $self -> unquote_table_name ($name);
	my $q = $name =~ /^_/ ? $self -> {quote} : '';

	$self -> do ("CREATE TABLE $q$name$q (\n  " . (join "\n ,", map {$self -> gen_column_definition ($_, $definition -> {columns} -> {$_}, $name,,$core_voc_replacement_use)} keys %{$definition -> {columns}}) . "\n)\n");

	my $pk_column = (grep {$definition -> {columns} -> {$_} -> {_PK}} keys %{$definition -> {columns}}) [0];

	if ($pk_column) {

		if ($core_voc_replacement_use) {			
			my ($sequence_name,$trigger_name);

			if (uc $name ne uc $self -> {__voc_replacements}) { 	
				$sequence_name = voc_replacements($self, $name, $name, 2, 'CREATE');
			}
			else {
				$sequence_name = "SEQ_"."$name";			
			}
	
			unless ($self -> sql_select_scalar("SELECT COUNT(*) FROM USER_SEQUENCES WHERE SEQUENCE_NAME = '${sequence_name}' ")) {		

				$self -> do ("CREATE SEQUENCE $q${sequence_name}$q START WITH 1 INCREMENT BY 1 MINVALUE 1");

			}

			if (uc $name ne uc $self -> {__voc_replacements}) { 			
				$trigger_name = voc_replacements($self, $name, $name, 3, 'CREATE');		
			}
	 		else {
				$trigger_name = "TRG_"."$name";			
			}

			unless ($self -> sql_select_scalar("SELECT COUNT(*) FROM USER_TRIGGERS WHERE TRIGGER_NAME = '${trigger_name}'")) {		
				$self -> do (<<EOS);
					CREATE TRIGGER $q${trigger_name}$q BEFORE INSERT ON $q${name}$q
					FOR EACH ROW
					WHEN (new.$pk_column is null)
					BEGIN
						SELECT $q${sequence_name}$q.nextval INTO :new.$pk_column FROM DUAL;
					END;		
EOS
				$self -> do ("ALTER TRIGGER $q${trigger_name}$q COMPILE");
			}
		}
		else {

			my $sequence_name = $name;
			if (length ($name) > 25) {
				my $i = 0;
				$sequence_name = substr ($sequence_name, 0, 22);
				while ($self -> sql_select_scalar ('SELECT sequence_name FROM all_sequences WHERE sequence_owner = ? AND sequence_name = ?', $self->{schema}, $sequence_name . "_$i")) {
					$i ++;
				}
				$sequence_name .= "_$i";			
			}
			$self -> do ("CREATE SEQUENCE $q${sequence_name}_seq$q START WITH 1 INCREMENT BY 1");
	
			my $trigger_name = $name;
			if (length ($name) > 25) {
				my $i = 0;
				$trigger_name = substr ($trigger_name, 0, 21);
				while ($self -> sql_select_scalar ('SELECT trigger_name FROM all_triggers WHERE owner = ? AND trigger_name = ?', $self->{schema}, $trigger_name . "_$i")) {
					$i ++;
				}
				$trigger_name .= "_$i";			
			}

			$self -> do (<<EOS);

				CREATE TRIGGER $q${trigger_name}_trig$q BEFORE INSERT ON $q${name}$q
				FOR EACH ROW

				BEGIN
    					IF (:NEW.$pk_column IS NULL) THEN
					       SELECT $q${sequence_name}_seq$q.NEXTVAL INTO :NEW.$pk_column FROM DUAL;
  	                	        END IF;
				END;		
EOS
			$self -> do ("ALTER TRIGGER $q${trigger_name}_trig$q COMPILE");
		}

		$self -> do ("ALTER TABLE $q${name}$q ENABLE ALL TRIGGERS");
	}

}

################################################################################

sub add_columns {

	my ($self, $name, $columns,$core_voc_replacement_use) = @_;

	$name = $self -> unquote_table_name ($name);
	my $q = $name =~ /^_/ ? $self -> {quote} : '';

	my $sql = "ALTER TABLE $q$name$q ADD (\n  " . (join "\n ,", map {$self -> gen_column_definition ($_, $columns -> {$_}, $name,,$core_voc_replacement_use)} keys %$columns) . "\n)\n";
			
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

	my ($self, $name, $c_name, $existing_column, $c_definition,$core_voc_replacement_use) = @_;
	
	my $existing_type = $self -> get_canonic_type ($existing_column);

#warn Dumper ($existing_column);

	my $c_type = $self -> get_canonic_type ($c_definition, 1);
	
#warn Dumper ($c_definition);

	if ($c_type =~ /(\w+)\s*\(\s*(\d+)\s*\,\s*(\d+)/) {
		$c_type = $1;
		$c_definition -> {COLUMN_SIZE} = $2;
	}

	my $eq_types = $existing_type eq $c_type;

	my $eq_sizes = ($existing_column -> {COLUMN_SIZE} >= $c_definition -> {COLUMN_SIZE});

	my $existing_def = $self -> get_column_def ($existing_column);
	my $column_def   = $self -> get_column_def ($c_definition);
	my $eq_defaults  = ($existing_def eq $column_def);

	return if $eq_types && $eq_sizes && $eq_defaults;
	
	return if $self -> get_canonic_type ($existing_column) =~ /LOB/;
	
	$c_definition -> {_PK} = 0 if ($existing_column -> {_PK} == 1);
	delete $c_definition -> {NULLABLE} if (exists $existing_column -> {NULLABLE} && $existing_column -> {NULLABLE} == 0);

	$name = $self -> unquote_table_name ($name);
	my $q = $name =~ /^_/ ? $self -> {quote} : '';

	my $sql = "ALTER TABLE $q$name$q MODIFY" . $self -> gen_column_definition ($c_name, $c_definition, $name,,$core_voc_replacement_use);
	
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
	
	my ($self, $table_name, $index_name, $core_voc_replacement_use) = @_;

	$table_name = $self -> unquote_table_name ($table_name);
	my $q = $table_name =~ /^_/ ? $self -> {quote} : '';

	if ($core_voc_replacement_use) {
		my $replaced_name;

		if ($replaced_name = voc_replacements ($self ,$table_name, $index_name, 1,'DELETE')) {
			$index_name = $replaced_name;
		}

		warn "DROP INDEX $q$index_name$q\n";

		$self -> {db} -> do ("DROP INDEX $q$index_name$q");
	}
	else {

		warn "DROP INDEX $q${table_name}_${index_name}$q\n";
	
		$self -> {db} -> do ("DROP INDEX $q${table_name}_${index_name}$q");	

	}
	
}

################################################################################

sub create_index {

	my ($self, $table_name, $index_name, $index_def, $table_def, $core_voc_replacement_use) = @_;

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


	if ($core_voc_replacement_use) {
	
		my $replaced_name = voc_replacements ($self ,$table_name, $index_name, 1,'CREATE');

		warn "CREATE INDEX $q${replaced_name}$q ON $q${table_name}$q ($index_def)\n";

		$self -> {db} -> do ("CREATE INDEX $q${replaced_name}$q ON $q${table_name}$q ($index_def)");
	}
	else {
	
		warn "CREATE INDEX $q${table_name}_${index_name}$q ON $q$table_name$q ($index_def)\n";

		$self -> {db} -> do ("CREATE INDEX $q${table_name}_${index_name}$q ON $q$table_name$q ($index_def)");	
	
	}
	
}

################################################################################

sub sql_select_scalar {

	my ($self, $sql, @params) = @_;

	my $st = $self -> prepare ($sql);
	
	$st -> execute (@params);

	my @result = $st -> fetchrow_array ();
	$st -> finish;
	
	return $result [0];

}

################################################################################

sub voc_replacements {
	
	my ($self, $table_name, $object_name, $object_type, $action) = @_;

	my $core_name = $self -> {__voc_replacements};
	
	my $replaced_name = 
		$object_type == 1 ? 'IDX_' :
		$object_type == 2 ? 'SEQ_' :
		$object_type == 3 ? 'TRG_' :
		'';

	if ($action eq 'DELETE') {

		my $id = $self -> sql_select_scalar ("SELECT id FROM $core_name WHERE table_name= '${table_name}' AND object_name='${object_name}' AND object_type=$object_type");		
	
		$replaced_name .= $id; 
	
		$self -> {db} -> do ("DELETE FROM $core_name WHERE id = $id");		
	
	}
	
	if ($action eq 'CREATE') {	

		unless ($self -> sql_select_scalar("SELECT COUNT(*) FROM $core_name WHERE table_name= '${table_name}' AND object_name='${object_name}' AND object_type=$object_type")) {

			$self -> {db} -> do ("INSERT INTO $core_name (table_name,object_name,object_type) VALUES ('${table_name}','${object_name}',$object_type)");

		}
 
		$replaced_name .= $self -> sql_select_scalar ("SELECT id FROM $core_name WHERE table_name= '${table_name}' AND object_name='${object_name}' AND object_type=$object_type");
	
	}

	return $replaced_name;

}

1;