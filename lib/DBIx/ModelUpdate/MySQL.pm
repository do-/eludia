package DBIx::ModelUpdate::MySQL;

no warnings;

use Data::Dumper;

our @ISA = qw (DBIx::ModelUpdate);

################################################################################

sub _db_model_checksums {
	return '_db_model_checksums';
}

################################################################################

sub unquote_table_name {
	my ($self, $name) = @_;
	$name =~ s{^.*?(\w+)\W*$}{$1};
	return $name;
}

################################################################################

sub get_keys {

	my ($self, $table_name) = @_;
	
	my $keys = {};
	
	my $st = $self -> {db} -> prepare ("SHOW KEYS FROM $table_name");
	
	$st -> execute ();
		
	while (my $r = $st -> fetchrow_hashref) {
		
		my $name = $r -> {Key_name};
		
		next if $name eq 'PRIMARY';
		
		my $column = $r -> {Column_name};
		
		$column .= '(' . $r -> {Sub_part} . ')' if $r -> {Sub_part};

		if (exists $keys -> {$name}) {
			$keys -> {$name} .= ',' . $column;
		}
		else {
			$keys -> {$name} = $column;
		}
	
	}
	
	return $keys;

}

################################################################################

sub get_columns {

	my ($self, $table_name) = @_;
		
	my $fields = {};
	
	my $st = $self -> {db} -> prepare ("SHOW COLUMNS FROM $table_name");
	
	$st -> execute ();
		
	while (my $r = $st -> fetchrow_hashref) {
	
		my $name = $r -> {Field};
		
		$r -> {Type} =~ /^\w+/;
		$r -> {TYPE_NAME} = $&;
		$r -> {Type} =~ /(\d+)(?:\,(\d+))?/;
		$r -> {COLUMN_SIZE} = $1;
		$r -> {DECIMAL_DIGITS} = $2 if defined $2;
		$r -> {COLUMN_DEF} = $r -> {Default} if $r -> {Default};
		$r -> {_EXTRA} = $r -> {Extra} if $r -> {Extra};
		$r -> {_PK} = 1 if $r -> {Key} eq 'PRI';
		$r -> {NULLABLE} = $r -> {Null} eq 'YES' ? 1 : 0;
		map {delete $r -> {$_}} grep {/[a-z]/} keys %$r;
		$fields -> {$name} = $r;
	
	}
	
	return $fields;

}

################################################################################

sub gen_column_definition {

	my ($self, $name, $definition) = @_;

	$definition -> {NULLABLE} = 1 unless defined $definition -> {NULLABLE};

	my $sql = " $name $$definition{TYPE_NAME}";

	if ($definition -> {COLUMN_SIZE}) {
		$sql .= ' (' . $definition -> {COLUMN_SIZE};
		$sql .= ',' . $definition -> {DECIMAL_DIGITS} if $definition -> {DECIMAL_DIGITS};
		$sql .= ')';	
	}

	$sql .= ' ' . $definition -> {_EXTRA} if $definition -> {_EXTRA};
	$sql .= ' NOT NULL' unless $definition -> {NULLABLE};
	$sql .= ' PRIMARY KEY' if $definition -> {_PK};
	$sql .= ' DEFAULT ' . $self -> {db} -> quote ($definition -> {COLUMN_DEF}) if defined $definition -> {COLUMN_DEF};

	return $sql;

}

################################################################################

sub create_table {

	my ($self, $name, $definition) = @_;
	
	my $sql = "CREATE TABLE $name (\n  " . (join "\n ,", map {$self -> gen_column_definition ($_, $definition -> {columns} -> {$_})} keys %{$definition -> {columns}}) . "\n)\n";
			
	$self -> do ($sql);

}

################################################################################

sub add_columns {

	my ($self, $name, $columns) = @_;
	
	my $sql = "ALTER TABLE $name ADD (\n  " . (join "\n ,", map {$self -> gen_column_definition ($_, $columns -> {$_})} keys %$columns) . "\n)\n";
			
	$self -> do ($sql);

}

################################################################################

sub get_column_def {

	my ($self, $column) = @_;
	
	return $column -> {COLUMN_DEF} if defined $column -> {COLUMN_DEF};
	
	return 0 if $column -> {TYPE_NAME} =~ /bit|int|float|numeric|decimal/;
	
	return '';

}

################################################################################

sub update_column {

	my ($self, $name, $c_name, $existing_column, $c_definition) = @_;
	
	my $existing_def = $self -> get_column_def ($existing_column);
	my $column_def   = $self -> get_column_def ($c_definition);

	my $types_are_equal = $existing_column -> {TYPE_NAME} eq $c_definition -> {TYPE_NAME};
	
	if (
		!$types_are_equal &&
		$existing_column -> {TYPE_NAME} eq 'varchar' &&
		$c_definition    -> {TYPE_NAME} eq 'char'
	) {
		$types_are_equal = 1;
	}
	
	my $defs_are_equal = ($existing_def eq $column_def);
	
	if (!$defs_are_equal && $existing_def != 0) {
		
		my $precision = 0.5;
		
		for (my $i = 0; $i < $existing_column -> {DECIMAL_DIGITS}; $i++) { $precision /= 10 }
		
		$defs_are_equal = 1 if abs ($existing_def - $column_def) < $precision;

	}
	
	return if 
		$types_are_equal
		and $existing_column -> {COLUMN_SIZE}    >= $c_definition -> {COLUMN_SIZE}
		and $existing_column -> {DECIMAL_DIGITS} >= $c_definition -> {DECIMAL_DIGITS}
		and $defs_are_equal
	;
	
	$c_definition -> {_PK} = 0 if ($existing_column -> {_PK} == 1);

	my $sql = "ALTER TABLE $name CHANGE $c_name " . $self -> gen_column_definition ($c_name, $c_definition);
	
	$self -> do ($sql);
	
}

################################################################################

sub insert_or_update {

	my ($self, $name, $data) = @_;
	
	my $pk_column = 'id';
	
	my $st = $self -> {db} -> prepare ("SELECT * FROM $name WHERE $pk_column = ?");
	$st -> execute ($data -> {$pk_column});
	my $existing_data = $st -> fetchrow_hashref;
	$st -> finish;
	
	if ($existing_data -> {$pk_column}) {
	
		my @terms = ();
		
		foreach my $key (keys (%$data)) {
			my $value = $data -> {$key};
  			
			next if $key eq $pk_column;
			next if $value eq $existing_data -> {$key};
			push @terms, "$key = " . $self -> {db} -> quote ($value);
		}
		
		if (@terms) {
			$self -> do ("UPDATE $name SET " . (join ', ', @terms) . " WHERE $pk_column = " . $data -> {$pk_column});
		}
	
	} else {
		my @names = keys %$data;
		$self -> do ("INSERT INTO $name (" . (join ', ', @names) . ") VALUES (" . (join ', ', map {$self -> {db} -> quote ($data -> {$_})} @names) . ')');
	}

	
}

################################################################################

sub drop_index {
	
	my ($self, $table_name, $index_name) = @_;
	
	$self -> {db} -> do ("ALTER TABLE $table_name DROP INDEX $index_name");
	
}

################################################################################

sub create_index {
	
	my ($self, $table_name, $index_name, $index_def) = @_;
	
	$self -> {db} -> do ("ALTER TABLE $table_name ADD INDEX $index_name ($index_def)");
	
}

1;
