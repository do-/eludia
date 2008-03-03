package DBIx::ModelUpdate::MicrosoftSQLServer;

no warnings;

use Data::Dumper;

our @ISA = qw (DBIx::ModelUpdate);

# Необходимо инициализировать переменную $CATALOG реальным именем базы данных
$CATALOG = 'trunk1';

################################################################################

sub _db_model_checksums {
	return '_db_model_checksums';
}

################################################################################

sub unquote_table_name {

	my ($self, $name) = @_;

	my @tokens = split /\./, $name;

	$name = $tokens [-1];

	$name =~ s{^\W*(\w+)\W*$}{$1};

	return lc $name;

}

################################################################################

sub get_keys {

	my ($self, $table_name) = @_;
	
	my $keys = {};
	
	my $st = $self -> {db} -> prepare ("exec sp_helpindex '$table_name'");

	$st -> execute ();
		
	while (my $r = $st -> fetchrow_hashref) {

		$r -> {index_name} =~ s{^${table_name}_}{};

		$keys -> {$r -> {index_name}} = $r -> {index_keys};

	}
	
	return lc $keys;

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
			, DATA_TYPE
			, NUMERIC_PRECISION
			, CHARACTER_MAXIMUM_LENGTH
			, NUMERIC_SCALE
			, COLUMN_DEFAULT
			, IS_NULLABLE
		FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ?
EOS

#	$st -> execute ($uc_table_name);
	$st -> execute ($table_name);

	while (my $r = $st -> fetchrow_hashref) {
				
		my $name = lc $r -> {COLUMN_NAME};

		next if $options -> {default_columns} -> {$name};

		my $rr = {};
		
		$rr -> {COLUMN_SIZE} = $r -> {NUMERIC_PRECISION} || $r -> {CHARACTER_MAXIMUM_LENGTH};
		
		$rr -> {DECIMAL_DIGITS} = $r -> {NUMERIC_SCALE} if $r -> {NUMERIC_SCALE};

		$rr -> {TYPE_NAME} = lc $r -> {DATA_TYPE};
		$rr -> {TYPE_NAME} =~ s{2$}{};
		if ($rr -> {TYPE_NAME} eq 'number') {
			$rr -> {TYPE_NAME} = $r -> {NUMERIC_SCALE} ? 'decimal' : 'int';
		}

		$rr -> {COLUMN_SIZE} ||= 255 if ($rr -> {TYPE_NAME} eq 'varchar') || ($rr -> {TYPE_NAME} eq 'nvarchar');
		
		if ($r -> {DATA_DEFAULT}) {
			$rr -> {COLUMN_DEF} = $r -> {COLUMN_DEFAULT};
			$rr -> {COLUMN_DEF} =~ s{^\'}{};
			$rr -> {COLUMN_DEF} =~ s{\'$}{};
		}
		
		if ($name eq $pk_column) {
			$rr -> {_PK} = 1;
			$rr -> {_EXTRA} = 'auto_increment';
		}
		
		$rr -> {NULLABLE} = $r -> {IS_NULLABLE} eq 'Y' ? 1 : 0;

		$fields -> {$name} = $rr;
	
	}
	
	return $fields;

}

################################################################################

sub gen_column_definition {

	my ($self, $name, $definition, $tablename) = @_;

	$definition -> {NULLABLE} = 1 unless defined $definition -> {NULLABLE};
	$type = $$definition{TYPE_NAME};
	$oldtype = $type;
	$type = get_canonic_type($type);

	my $sql = " $name $type";

	if ($type ne 'int')
	{
		if ($definition -> {COLUMN_SIZE}) {
			$sql .= ' (' . $definition -> {COLUMN_SIZE};
			$sql .= ',' . $definition -> {DECIMAL_DIGITS} if $definition -> {DECIMAL_DIGITS};
			$sql .= ')';	
		}
	}

	$definition -> {_EXTRA} = " IDENTITY(1,1)" if $definition -> {_EXTRA} eq "auto_increment";

	$definition -> {_EXTRA} = "DEFAULT (getdate())" if $oldtype eq "timestamp";

	# Надо потом подумать, чем заменить эти определения
	$definition -> {_EXTRA} = "" if $definition -> {_EXTRA} eq "unsigned";
	$definition -> {_EXTRA} = "" if $definition -> {_EXTRA} eq "binary";

	$sql .= ' ' . $definition -> {_EXTRA} if $definition -> {_EXTRA};

	$sql .= ' NOT NULL' unless $definition -> {NULLABLE};
	$sql .= ' CONSTRAINT PK_' . $name . '_' . $tablename . ' PRIMARY KEY' if $definition -> {_PK};
	$sql .= ' DEFAULT ' . $self -> {db} -> quote ($definition -> {COLUMN_DEF}) if defined $definition -> {COLUMN_DEF};

	return $sql;

}

################################################################################

sub create_table {

	my ($self, $name, $definition) = @_;
	
	my $sql = "CREATE TABLE $name (\n  " . (join "\n ,", map {$self -> gen_column_definition ($_, $definition -> {columns} -> {$_}, $name)} keys %{$definition -> {columns}}) . "\n)\n";

	$self -> do ($sql);

}

################################################################################

sub add_columns {

	my ($self, $name, $columns) = @_;
	
#	my $sql = "ALTER TABLE $name ADD (\n  " . (join "\n ,", map {$self -> gen_column_definition ($_, $columns -> {$_}, $name)} keys %$columns) . "\n)\n";

	my $sql = "ALTER TABLE $name ADD \n  " . (join "\n ,", map {$self -> gen_column_definition ($_, $columns -> {$_}, $name)} keys %$columns) . "\n";
			
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
	my $column_def = $self -> get_column_def ($c_definition);
	
	my $eq_types = ($self -> get_canonic_type ($existing_column -> {TYPE_NAME}) eq $self -> get_canonic_type ($c_definition -> {TYPE_NAME}));
	my $eq_sizes = ($existing_column -> {COLUMN_SIZE} >= $c_definition -> {COLUMN_SIZE});
	my $eq_defaults = ($existing_def eq $column_def);

	return if $eq_types && $eq_sizes && $eq_defaults;
	
	return if $self -> get_canonic_type ($existing_column -> {TYPE_NAME}) =~ /LOB/;
	
	$c_definition -> {_PK} = 0 if ($existing_column -> {_PK} == 1);
	delete $c_definition -> {NULLABLE} if (exists $existing_column -> {NULLABLE} && $existing_column -> {NULLABLE} == 0);

	my $sql = "ALTER TABLE $name ALTER COLUMN " . $self -> gen_column_definition ($c_name, $c_definition, $name);
	
	$self -> do ($sql);
	
}


################################################################################

sub drop_index {
	
	my ($self, $table_name, $index_name) = @_;
	
	$self -> {db} -> do ("DROP INDEX " . $table_name  . "_" . $index_name . " ON $table_name");
	
}

################################################################################

sub create_index {
	
	my ($self, $table_name, $index_name, $index_def) = @_;

	# Поле типа text не может быть ключевым. Так что пока без индекса.
	$index_def = "id_session" if $index_def eq "id_session,href(255)";

	my $sql = "CREATE INDEX " . $table_name . "_" . $index_name . " ON $table_name ($index_def)";

print STDERR ("Создаем индекс: " . $sql . "\n");

	$self -> {db} -> do ($sql);
	
}

################################################################################

sub prepare {

	my ($self, $sql) = @_;
	return $self -> {db} -> prepare ($sql);

}

################################################################################

sub get_canonic_type {

	my ($type) = @_;
	my $type_name = $type;

	return 'nvarchar' 	if $type_name =~ /varchar/;
	return 'int'   	  	if $type_name =~ /int$/;
	return 'numeric'   	if ($type_name eq 'decimal') || ($type_name eq 'number');
	return 'text'  		if $type_name =~ /text$/;
        return 'datetime' 	if $type_name =~ /date|time/;
	return 'text'  		if $type_name =~ /LOB/;
	return $type_name;
}    

################################################################################

sub insert_or_update {

	my ($self, $name, $data, $table) = @_;
	
	my $pk_column = 'id';
	
	my $st = $self -> prepare ("SELECT * FROM $name WHERE $pk_column = ?");
	$st -> execute ($data -> {$pk_column});
	my $existing_data = $st -> fetchrow_hashref;
	$st -> finish;
	
	print STDERR ("existing_data = " . Dumper($existing_data));

	if ($existing_data -> {$pk_column}) {
	
		my @terms = ();
		
		while (my ($key, $value) = each %$data) {
			print STDERR ("key - $key, value - $value \n");
			next if $key eq $pk_column;
			next if $value eq $existing_data -> {$key};
			push @terms, "$key = " . $self -> {db} -> quote ($value);
		}
		
		if (@terms) {
			$self -> do ("UPDATE $name SET " . (join ', ', @terms) . " WHERE $pk_column = " . $data -> {$pk_column});
		}
	
	}
	else {
		my @names = keys %$data;
		$self -> do ("SET IDENTITY_INSERT $name ON; INSERT INTO $name (" . (join ', ', @names) . ") VALUES (" . (join ', ', map {$self -> {db} -> quote ($data -> {$_})} @names) . "); SET IDENTITY_INSERT $name OFF;");
	}

}

################################################################################


1;