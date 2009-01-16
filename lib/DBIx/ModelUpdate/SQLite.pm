package DBIx::ModelUpdate::SQLite;

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
	$name =~ s{\W}{}g;
	return $name;
}

################################################################################

sub get_keys {

	my ($self, $table_name) = @_;
	
	my $keys = {};
	
	my $st = $self -> {db} -> prepare ("SELECT * FROM sqlite_master WHERE type = 'index' and tbl_name = ?");
	$st -> execute ($table_name);	
	
	while (my $r = $st -> fetchrow_hashref) {
		
		my $name = $r -> {name};
		
		$name =~ s{^$table_name}{};
		$name =~ s{^_}{};
		

		$r -> {sql} =~ m{\((.*)\)}gsm;
		
		$keys -> {$name} = $1;
		
		$keys -> {$name} =~ s{\s}{}gsm;	

	}
	
print STDERR "keys for $table_name:" . Dumper ($keys);
	
	return $keys;

}

################################################################################

sub get_columns {

	my ($self, $table_name) = @_;
		
	my $fields = {};

	my $st = $self -> {db} -> prepare ("SELECT sql FROM sqlite_master WHERE type = 'table' and name = ?");
	$st -> execute ($table_name);
	my ($sql) = $st -> fetchrow_array;
	$st -> finish;

	$sql =~ m{\((.*)\)}gsm;
	my $defs = $1;

	foreach my $def (split /\n/gsm, $defs) {
	
		$def =~ /\w/ or next;
	
		my $r = {};
		
		if ($def =~ /DEFAULT/gism) {
			$def =~ s/\s*DEFAULT\s*\'(.*?)\'\s*//gism;
			$r -> {COLUMN_DEF} = $1;
		}

		if ($def =~ /PRIMARY\s+KEY/gism) {
			$r -> {_PK} = 1;
			$def =~ s/\s*PRIMARY\s+KEY\s*//gism;
		}
	
		if ($def =~ /NOT\s+NULL/gism) {
			$r -> {NULLABLE} = 0;
			$def =~ s/\s*NOT\s+NULL\s*//gism;
		}
		else {
			$r -> {NULLABLE} = 1;
		}

		$def =~ s{^[\s\,]+}{}gsm;

		$def =~ m{\s+}gsm;

		my ($name, $clause) = ($`, $');

		$clause =~ s{^\s+}{}gsm;
		$clause =~ m{^\w+};
		$r -> {TYPE_NAME} = $&;
		
		$clause =~ /(\d+)(?:\s*\,\s*(\d+))?/gsm;
		$r -> {COLUMN_SIZE} = $1;
		$r -> {DECIMAL_DIGITS} = $2 if defined $2;
		
		$fields -> {$name} = $r;		
	
	}
		
#print STDERR Dumper ($fields);
	
	return $fields;

}

################################################################################

sub gen_column_definition {

	my ($self, $name, $definition) = @_;
	
	$definition -> {NULLABLE} = 1 unless defined $definition -> {NULLABLE};
	
	$definition -> {TYPE_NAME} = 'INTEGER' if $definition -> {_PK};

	my $sql = " $name $$definition{TYPE_NAME}";
		
	if ($definition -> {COLUMN_SIZE}) {	
		$sql .= ' (' . $definition -> {COLUMN_SIZE};		
		$sql .= ',' . $definition -> {DECIMAL_DIGITS} if $definition -> {DECIMAL_DIGITS};		
		$sql .= ')';	
	}
	
#	$sql .= ' ' . $definition -> {_EXTRA} if $definition -> {_EXTRA};
	$sql .= ' NOT NULL' unless $definition -> {NULLABLE};
	$sql .= ' PRIMARY KEY' if $definition -> {_PK};
	$sql .= ' DEFAULT ' . $self -> {db} -> quote ($definition -> {COLUMN_DEF}) if $definition -> {COLUMN_DEF};
	
	return $sql;
	
}

################################################################################

sub create_table {

	my ($self, $name, $definition) = @_;
	
	$self -> do ("CREATE TABLE $name (\n  " . (join "\n ,", map {$self -> gen_column_definition ($_, $definition -> {columns} -> {$_})} keys %{$definition -> {columns}}) . "\n)");
	

	while (my ($col_name, $col_def) = each %{$definition -> {columns}}) {
	
		lc $col_def -> {TYPE_NAME} eq 'timestamp' or next;
		
		$self -> do (<<EOS);
	CREATE TRIGGER ${name}_${col_name}_timestamp_insert_trigger AFTER INSERT ON $name
		BEGIN
			UPDATE $name SET ${col_name} = NOW() WHERE oid = new.oid;
		END;
EOS
		
		$self -> do (<<EOS);
	CREATE TRIGGER ${name}_${col_name}_timestamp_update_trigger AFTER UPDATE ON $name
		BEGIN
			UPDATE $name SET ${col_name} = NOW() WHERE oid = new.oid;
		END;
EOS

	}
	
	
	while (my ($key_name, $key_def) = each %{$definition -> {keys}}) {
	
		$self -> create_index ($name, $key_name, $key_def);
		
	}
	

}

################################################################################

sub add_columns {

	my ($self, $name, $new_columns) = @_;
		
	$self -> do ("CREATE TEMP TABLE __buffer AS SELECT * FROM $name");		
	
	my $columns = $self -> get_columns ($name);

	my $keys    = $self -> get_keys ($name);

	my $column_names = join ', ', keys %$columns;

	foreach my $column_name (keys %$new_columns) {

		$columns -> {$column_name} = $new_columns -> {$column_name};

	}
	
	$self -> do ("DROP TABLE $name");
	
	$self -> create_table ($name, {columns => $columns});
	
	$self -> do ("INSERT INTO $name ($column_names) SELECT $column_names FROM __buffer");

	$self -> do ("DROP TABLE __buffer");
	
	while (my ($key_name, $key_def) = each %$keys) {
	
		$self -> create_index ($name, $key_name, $key_def -> {columns});
		
	}
	
	while (my ($col_name, $col_def) = each %{$definition -> {new_columns}}) {
	
		lc $col_def -> {TYPE_NAME} eq 'timestamp' or next;
		
		$self -> do (<<EOS);
	CREATE TRIGGER ${name}_${col_name}_timestamp_insert_trigger AFTER INSERT ON $name
		BEGIN
			UPDATE $name SET ${col_name} = NOW() WHERE oid = new.oid;
		END;
EOS
		
		$self -> do (<<EOS);
	CREATE TRIGGER ${name}_${col_name}_timestamp_update_trigger AFTER UPDATE ON $name
		BEGIN
			UPDATE $name SET ${col_name} = NOW() WHERE oid = new.oid;
		END;
EOS

	}
	

	$self -> do ("VACUUM");

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

#	do nothing;

}

################################################################################

sub insert_or_update {

	my ($self, $name, $data) = @_;

	my @names = keys %$data;

	my $sql = "REPLACE INTO $name (" . (join ', ', @names) . ") VALUES (" . (join ', ', map {$self -> {db} -> quote ($data -> {$_})} @names) . ')';

	$self -> do ($sql);

}

################################################################################

sub drop_index {
	
	my ($self, $table_name, $index_name) = @_;
	
	$self -> do ("DROP INDEX ${table_name}_${index_name}");
	
}

################################################################################

sub create_index {
	
	my ($self, $table_name, $index_name, $index_def) = @_;
	
	$index_def =~ s{\(\d+\)}{}g;
		
	$self -> do ("CREATE INDEX ${table_name}_${index_name} ON ${table_name} ($index_def)");
	
}

################################################################################

sub assert_view {

	my ($self, $name, $definition) = @_;
	
	my $columns = '';

	foreach my $line (split /\n/, $definition -> {src}) {

		last if $line =~ /^[\#\s]*(keys|data|sql)\s*=\>/;
		next if $line =~ /^\s*columns\s*=\>/;
		$line =~ /^\s*(\w+)\s*=\>/ or next;
		$columns .= ', ' if $columns;
		$columns .= $1;

	}

	$self -> do ("DROP VIEW IF EXISTS $name");
	$self -> do ("CREATE VIEW $name ($columns) AS $definition->{sql}");

}

1;