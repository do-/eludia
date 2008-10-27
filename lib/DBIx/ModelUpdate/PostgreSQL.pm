package DBIx::ModelUpdate::PostgreSQL;

use Data::Dumper;

no warnings;

our @ISA = qw (DBIx::ModelUpdate);

################################################################################

sub _db_model_checksums {
	return '"_db_model_checksums"';
}

################################################################################

sub unquote_table_name {

	my ($self, $name) = @_;
	
	my @name = split /\./, $name;
	
	$name = $name [-1];
	
	$name =~ s{"}{}g; #"
	
	return $name;
	
}

################################################################################

sub prepare {

	my ($self, $sql) = @_;
	
	return $self -> {db} -> prepare ($sql);

}

################################################################################

sub get_keys {

	my ($self, $table_name) = @_;
	
	my $keys = {};
	
	my $st = $self -> prepare ('SELECT * FROM pg_indexes WHERE schemaname = current_schema () AND tablename = ?');

	$st -> execute ($table_name);

	while (my $r = $st -> fetchrow_hashref) {
		$r -> {indexdef} =~ /\((.*)\)/;
		my $def = $1;
		$def =~ s{\s}{}g;
		$r -> {indexname} =~ s{^ix_${table_name}_}{};
		$keys -> {$r -> {indexname}} = $def;	
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
	
	my $st = $self -> {db} -> column_info ('', '', $table_name, '');

	while (my $r = $st -> fetchrow_hashref) {
				
		my $name = lc $r -> {COLUMN_NAME};

		next if $options -> {default_columns} -> {$name};

		my $rr = {};
		
		$rr -> {TYPE_NAME} = lc $r -> {TYPE_NAME};
		$rr -> {TYPE_NAME} =~ s{numeric}{decimal};
		$rr -> {TYPE_NAME} =~ s{int4}{int};
		$rr -> {TYPE_NAME} =~ s{int8}{bigint};
		
		if ($r -> {COLUMN_DEF}) {
			$rr -> {COLUMN_DEF} = $r -> {COLUMN_DEF};
			$rr -> {COLUMN_DEF} =~ s{\:\:\w+$}{};
			$rr -> {COLUMN_DEF} =~ /^\d+$/ or $rr -> {COLUMN_DEF} =~ /\(/ or $rr -> {COLUMN_DEF} = "'$rr->{COLUMN_DEF}'";
		}

		if ($name eq $pk_column) {
			$rr -> {_PK} = 1;
			$rr -> {_EXTRA} = 'auto_increment' if $rr -> {TYPE_NAME} =~ /serial/i;
			delete $rr -> {COLUMN_DEF};
		}
		
		$rr -> {NULLABLE} = defined $r -> {NULLABLE} ? $r -> {NULLABLE} : 1;

		$fields -> {$name} = $rr;
	
	}
	
	return $fields;

}

################################################################################

sub get_canonic_type {

	my ($self, $definition, $should_change) = @_;

	my $type_name = lc $definition -> {TYPE_NAME};

	return 'SERIAL'           if $definition -> {_EXTRA} eq "auto_increment";
	return 'SMALLINT'         if $type_name eq 'tinyint';		
	return uc $type_name      if $type_name =~ /(big|small)?int$/;
	return 'NUMERIC'          if $type_name eq 'decimal';
	return 'TEXT'             if $type_name =~ /(char|text)$/;
	return 'BYTEA'            if $type_name eq 'varbinary';
	return 'DATE'             if $type_name eq 'date';	
	return 'OID'              if $type_name eq 'longblob';
	
	if ($type_name =~ /time/) {				
		$definition -> {COLUMN_DEF} = 'now()' if $should_change && ($type_name eq 'timestamp');		
		return 'TIMESTAMP';			
	};

	return uc $type_name;

}    

################################################################################

sub gen_column_definition {

	my ($self, $name, $definition, $table_name, $core_voc_replacement_use) = @_;
	
	$definition -> {NULLABLE} = 1 unless defined $definition -> {NULLABLE};
	
	my $type = $self -> get_canonic_type ($definition, 1);
	
	my $sql = " $name $type";
		
	if ($definition -> {COLUMN_SIZE} && $type eq 'NUMERIC') {	
		$sql .= ' (' . $definition -> {COLUMN_SIZE};		
		$sql .= ',' . $definition -> {DECIMAL_DIGITS} if $definition -> {DECIMAL_DIGITS};		
		$sql .= ')';
	}

	if (exists $definition -> {COLUMN_DEF}) {
	
		if ($definition -> {COLUMN_DEF} !~ /\(/) {
			$definition -> {COLUMN_DEF} = $self -> {db} -> quote ($definition -> {COLUMN_DEF});
		}
	
		$sql .= ' DEFAULT ' . $definition -> {COLUMN_DEF};
	}

	$sql .= ' NOT NULL' unless $definition -> {NULLABLE};
	$sql .= ' PRIMARY KEY' if $definition -> {_PK};

	return $sql;
	
}

################################################################################

sub create_table {

	my ($self, $name, $definition) = @_;

	$name = $self -> unquote_table_name ($name);

	$self -> do ("CREATE TABLE $name (\n  " . (join "\n ,", map {$self -> gen_column_definition ($_, $definition -> {columns} -> {$_}, $name,,$core_voc_replacement_use)} keys %{$definition -> {columns}}) . "\n)\n");

}

################################################################################

sub add_columns {

	my ($self, $name, $columns) = @_;

	$name = $self -> unquote_table_name ($name);
	
	foreach my $c (keys %$columns) {

		$self -> do ("ALTER TABLE $name ADD COLUMN " . $self -> gen_column_definition ($c, $columns -> {$c}, $name));

	}

}

################################################################################

sub get_column_def {

	my ($self, $column) = @_;
	
	return '' if $column -> {_PK};
	
	return 0 if $column -> {TYPE_NAME} =~ /bit|int|float|numeric|decimal/;

	return $column -> {COLUMN_DEF} if defined $column -> {COLUMN_DEF};
	
	return '';

}    

################################################################################

sub update_column {

	my ($self, $name, $c_name, $existing_column, $c_definition) = @_;
	
	my $existing_type = $self -> get_canonic_type ($existing_column);

	my $c_type = $self -> get_canonic_type ($c_definition, 1);
	
	if ($c_type =~ /(\w+)\s*\(\s*(\d+)\s*\,\s*(\d+)/) {
		$c_type = $1;
		$c_definition -> {COLUMN_SIZE} = $2;
	}

	my $eq_types = $existing_type eq $c_type;

	my $eq_sizes = ($existing_column -> {COLUMN_SIZE} >= $c_definition -> {COLUMN_SIZE});

	my $existing_def = $self -> get_column_def ($existing_column);
	my $column_def   = $self -> get_column_def ($c_definition);
	my $eq_defaults  = ($existing_def eq $column_def);

	if ($c_definition -> {_PK}) {
		$c_definition -> {NULLABLE} = 0;
	}

	$name = $self -> unquote_table_name ($name);
	
	my $flag;

	if (
		exists $existing_column -> {NULLABLE} && $existing_column -> {NULLABLE} == 0
		&& (!exists $c_definition -> {NULLABLE} || $c_definition -> {NULLABLE})
	) {
		$self -> do ("ALTER TABLE $name ALTER COLUMN $c_name DROP NOT NULL");
		$flag = 1;
	}

	if (
		$existing_type ne $c_type && $c_name ne 'id'
	) {
		my $def = $self -> gen_column_definition ($c_name, $c_definition, $name);
		$def =~ s{DEFAULT.*}{};
		$def =~ s{ NOT NULL}{};
		$def =~ s{ PRIMARY KEY}{};
		$def =~ s{$c_name}{$c_name TYPE};
		$self -> do ("ALTER TABLE $name ALTER COLUMN $def");
		$flag = 1;
	}

	if (
		$existing_def ne $column_def
	) {
		$self -> do ("ALTER TABLE $name ALTER COLUMN $c_name SET DEFAULT $column_def");
		$flag = 1;
	}

	if (
		exists $c_definition -> {NULLABLE} && $c_definition -> {NULLABLE} == 0
		&& (!exists $existing_column -> {NULLABLE} || $existing_column -> {NULLABLE})
	) {
		$self -> do ("ALTER TABLE $name ALTER COLUMN $c_name SET NOT NULL");
		$flag = 1;
	}
	
	return $flag;
	
}

################################################################################

sub insert_or_update {

	my ($self, $name, $data, $table) = @_;
		
	my $st = $self -> prepare ("SELECT * FROM $name WHERE id = ?");
	
	$st -> execute ($data -> {id});
	
	my $existing_data = $st -> fetchrow_hashref;
	
	$st -> finish;

	if ($existing_data -> {id}) {
	
		my @terms = ();
		
		foreach my $key (keys %$data) {
			next if $key eq 'id';
			my $value = $data -> {$key};
			next if $value eq $existing_data -> {$key};
			push @terms, "$key = " . $self -> {db} -> quote ($value);
		}
		
		if (@terms) {
			$self -> do ("UPDATE $name SET " . (join ', ', @terms) . " WHERE id = " . $data -> {id});
		}
	
	}
	else {
		my @names = keys %$data;
		$self -> do ("INSERT INTO $name (" . (join ', ', @names) . ") VALUES (" . (join ', ', map {$self -> {db} -> quote ($data -> {$_})} @names) . ')');
	}

}

################################################################################

sub drop_index {
	
	my ($self, $table_name, $index_name) = @_;
		
	$self -> do ("DROP INDEX ix_${table_name}_${index_name}");	
	
}

################################################################################

sub canonic_key_definition {

	my ($self, $s) = @_;
	
	$s =~ s{\s+}{}g;
	$s =~ s{\(\d+\)}{}g;
	
	return $s;

}

################################################################################

sub create_index {

	my ($self, $table_name, $index_name, $index_def, $table_def) = @_;
	
	my $concurrently = $self -> {db} -> {AutoCommit} ? 'CONCURRENTLY' : '';
	
	$self -> do ("CREATE INDEX $concurrently ix_${table_name}_${index_name} ON $table_name ($index_def)");

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

1;
