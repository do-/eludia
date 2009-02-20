no strict;
no warnings;


################################################################################

sub _sqlite_format_datetime {
	$_[0] =~ s{\%i}{\%M};
	return POSIX::strftime (@_);
}

################################################################################

sub _sqlite_parse_datetime {
	my ($s) = @_;	
	$s =~ s{[^\d]}{}g;	
	$s =~ /(\d\d\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)/;	
	return ($6, $5, $4 , $3, $2 - 1, $1 - 1900);
}

################################################################################

sub sql_version {

	$db -> func ('REPLACE', 3, sub { my ($s, $from, $to) = @_; $s =~ s{$from}{$to}g; return $s }, 'create_function');
	$db -> func ('CONCAT',  2, sub { return $_[0] . $_[1] }, 'create_function');
	$db -> func ('CONCAT',  3, sub { return $_[0] . $_[1] . $_[2] }, 'create_function');
	$db -> func ('NOW',     0, sub { return POSIX::strftime ('%Y-%m-%d %H:%M:%S', localtime (time)) }, 'create_function');	
	$db -> func ('DATE_FORMAT', 2, sub { return _sqlite_format_datetime ($_[1], _sqlite_parse_datetime ($_[0])) }, 'create_function');	

	my $version = {	string => 'SQLite ' . sql_select_scalar ('SELECT sqlite_version(*)') };
	
	($version -> {number}) = $version -> {string} =~ /([\d\.]+)/;
	
	$version -> {number_tokens} = [split /\./, $version -> {number}];
	
	return $version;
	
}

################################################################################

sub sql_prepare {
	my ($sql) = @_;
	$sql =~ s{\#}{--}gm;
	return $db  -> prepare ($sql);
}


################################################################################

sub sql_do_refresh_sessions {

	my $timeout = $preconf -> {session_timeout} || $conf -> {session_timeout} || 30;

	if ($preconf -> {core_auth_cookie} =~ /^\+(\d+)([mhd])/) {
		$timeout = $1;
		$timeout *= 
			$2 eq 'h' ? 60 :
			$2 eq 'd' ? 1440 :
			1;
	}
	
	my @now = Date::Calc::Today_and_Now;

	my $now = sprintf ('%04d-%02d-%02d %02d:%02d:%02d', @now);
	
	my @new = Date::Calc::Add_Delta_YMDHMS (@now, 0, 0, 0, 0, 1 - $timeout, 0);

	my $new = sprintf ('%04d-%02d-%02d %02d:%02d:%02d', @new);

	sql_do ("UPDATE $conf->{systables}->{sessions} SET ts = ? WHERE id = ? AND ts < ?", $ts, $_REQUEST {sid}, $new);

	my @old = Date::Calc::Add_Delta_YMDHMS (@now, 0, 0, 0, 0, - $timeout, 0);
	
	my $old = sprintf ('%04d-%02d-%02d %02d:%02d:%02d', @old);
	
	sql_do ("DELETE FROM $conf->{systables}->{sessions} WHERE ts < ?", $old);

}

################################################################################

sub sql_do {
	my ($sql, @params) = @_;
	my $st = sql_prepare ($sql);
	$st -> execute (@params);
	$st -> finish;	
}

################################################################################

sub sql_select_all_cnt {

	my ($sql, @params) = @_;
	
	my $options = {};
	if (@params > 0 and ref ($params [-1]) eq HASH) {
		$options = pop @params;
	}
	
	if ($options -> {fake}) {
	
		my $where = 'WHERE ';
		my $fake  = $_REQUEST {fake} || 0;
	
		foreach my $table (split /\,/, $options -> {fake}) {
			$where .= "$table.fake IN ($fake) AND ";
		}	
		
		$sql =~ s{where}{$where}i;
			
	}

	my $st = sql_prepare ($sql);
	$st -> execute (@params);
	my $result = $st -> fetchall_arrayref ({});	
	$st -> finish;

	my $cnt = 0;	


	$sql =~ s{SELECT.*?FROM}{SELECT COUNT(*) FROM}ism;
	
	if ($sql =~ s{LIMIT.*}{}ism) {
#		pop @params;
	}
	
	$st = sql_prepare ($sql);
	$st -> execute (@params);

	if ($sql =~ /GROUP\s+BY/i) {
		$cnt++ while $st -> fetch ();
	}
	else {
		$cnt = $st -> fetchrow_array ();
	}
			
	return ($result, $cnt);

}

################################################################################

sub sql_select_all {

	my ($sql, @params) = @_;


	my $options = {};
	if (@params > 0 and ref ($params [-1]) eq HASH) {
		$options = pop @params;
	}
	
	if ($options -> {fake}) {
	
		my $where = 'WHERE ';
		my $fake  = $_REQUEST {fake} || 0;
	
		foreach my $table (split /\,/, $options -> {fake}) {
			$where .= "$table.fake IN ($fake) AND ";
		}	
		
		$sql =~ s{where}{$where}i;
			
	}


	my $st = sql_prepare ($sql);
	$st -> execute (@params);
	my $result = $st -> fetchall_arrayref ({});	
	$st -> finish;
	
	return $result;

}

################################################################################

sub sql_select_col {

	my ($sql, @params) = @_;
	
	my @result = ();
	my $st = sql_prepare ($sql);
	$st -> execute (@params);
	while (my @r = $st -> fetchrow_array ()) {
		push @result, @r;
	}
	$st -> finish;
	
	return @result;

}

################################################################################

sub sql_select_hash {

	my ($sql_or_table_name, @params) = @_;
	
	if ($sql_or_table_name !~ /^\s*SELECT/i) {
	
		my $id = $_REQUEST {id};

		my $field = 'id'; 
		
		if (@params) {
			if (ref $params [0] eq HASH) {
				($field, $id) = each %{$params [0]};
			} else {
				$id = $params [0];
			}
		}
	
		@params = ({}) if (@params == 0);
		
		return sql_select_hash ("SELECT * FROM $sql_or_table_name WHERE $field = ?", $id);

	}	
	
	my $st = sql_prepare ($sql_or_table_name);
	$st -> execute (@params);
	my $result = $st -> fetchrow_hashref ();
	$st -> finish;
	
	return $result;

}

################################################################################

sub sql_select_array {

	my ($sql, @params) = @_;
	my $st = sql_prepare ($sql);
	$st -> execute (@params);
	my @result = $st -> fetchrow_array ();
	$st -> finish;
	
	return wantarray ? @result : $result [0];

}

################################################################################

sub sql_select_scalar {

	my ($sql, @params) = @_;
	my $st = sql_prepare ($sql);
	$st -> execute (@params);
	my @result = $st -> fetchrow_array ();
	$st -> finish;
	
	return $result [0];

}

################################################################################

sub sql_select_path {
	
	my ($table_name, $id, $options) = @_;
	
	$options -> {name} ||= 'name';
	$options -> {type} ||= $table_name;
	$options -> {id_param} ||= 'id';

	my ($parent) = $id;

	my @path = ();

	while ($parent) {	
		my $r = sql_select_hash ("SELECT id, parent, $$options{name} as name, '$$options{type}' as type, '$$options{id_param}' as id_param FROM $table_name WHERE id = ?", $parent);
		$r -> {cgi_tail} = $options -> {cgi_tail},
		unshift @path, $r;		
		$parent = $r -> {parent};	
	}
	
	if ($options -> {root}) {
		unshift @path, {
			id => 0, 
			parent => 0, 
			name => $options -> {root}, 
			type => $options -> {type}, 
			id_param => $options -> {id_param},
			cgi_tail => $options -> {cgi_tail},
		};
	}

	return \@path;

}

################################################################################

sub sql_select_subtree {

	my ($table_name, $id, $options) = @_;
	
	my @ids = ($id);
	
	while (TRUE) {
	
		my $ids = join ',', @ids;
	
		my @new_ids = sql_select_col ("SELECT id FROM $table_name WHERE parent IN ($ids) AND id NOT IN ($ids)");
		
		last unless @new_ids;
	
		push @ids, @new_ids;
	
	}
	
	return @ids;

}

################################################################################

sub sql_last_insert_id {
	return 0 + sql_select_array ("SELECT last_insert_rowid()");
}

################################################################################

sub sql_do_update {

	my ($table_name, $field_list, $options) = @_;

	ref $options eq HASH or $options = {
		stay_fake => $options,
		id        => $_REQUEST {id},
	};

	$options -> {id} ||= $_REQUEST {id};
	
	my $item = sql_select_hash ($table_name, $options -> {id});

	my $sql = join ', ', map {"$_ = ?"} @$field_list;
	$options -> {stay_fake} or $sql .= ', fake = 0';
	$sql = "UPDATE $table_name SET $sql WHERE id = ?";	
	my @params = @_REQUEST {(map {"_$_"} @$field_list)};	
	push @params, $options -> {id};
	sql_do ($sql, @params);
	
	if ($item -> {fake} == -1 && $conf -> {core_undelete_to_edit} && !$options -> {stay_fake}) {
		do_undelete_DEFAULT ($table_name, $options -> {id});
	}

}

################################################################################

sub sql_do_insert {

	my ($table_name, $pairs) = @_;
		
	my $fields = '';
	my $args   = '';
	my @params = ();

	$pairs -> {fake} = $_REQUEST {sid} unless exists $pairs -> {fake};

	foreach my $field (keys %$pairs) { 
		my $comma = @params ? ', ' : '';	
		$fields .= "$comma $field";
		$args   .= "$comma ?";
		push @params, $pairs -> {$field};	
	}
	
	sql_do ("INSERT INTO $table_name ($fields) VALUES ($args)", @params);	
	
	return sql_last_insert_id ();
	
}

################################################################################

sub sql_do_delete {

	my ($table_name, $options) = @_;
		
	if (ref $options -> {file_path_columns} eq ARRAY) {
		
		map {sql_delete_file ({table => $table_name, path_column => $_})} @{$options -> {file_path_columns}}
		
	}
	
	our %_OLD_REQUEST = %_REQUEST;
	
	eval {
		my $item = sql_select_hash ($table_name);

		foreach my $key (keys %$item) {
			$_OLD_REQUEST {'_' . $key} = $item -> {$key};
		}
	};
	
	sql_do ("DELETE FROM $table_name WHERE id = ?", $_REQUEST{id});
	
	delete $_REQUEST{id};
	
}

################################################################################

sub sql_delete_file {

	my ($options) = @_;	
	
	if ($options -> {path_column}) {
		$options -> {file_path_columns} = [$options -> {path_column}];
	}
	
	foreach my $column (@{$options -> {file_path_columns}}) {
		my $path = sql_select_array ("SELECT $$options{path_column} FROM $$options{table} WHERE id = ?", $_REQUEST {id});
		delete_file ($path);
	}
	

}

################################################################################

sub sql_download_file {

	my ($options) = @_;
	
	$_REQUEST {id} ||= $_PAGE -> {id};
	
	my $r = sql_select_hash ("SELECT * FROM $$options{table} WHERE id = ?", $_REQUEST {id});
	$options -> {path} = $r -> {$options -> {path_column}};
	$options -> {type} = $r -> {$options -> {type_column}};
	$options -> {file_name} = $r -> {$options -> {file_name_column}};
	
	download_file ($options);
	
}

################################################################################

sub sql_upload_file {
	
	my ($options) = @_;

	my $uploaded = upload_file ($options) or return;
		
	sql_delete_file ($options);
	
	my (@fields, @params) = ();
	
	foreach my $field (qw(file_name size type path)) {	
		my $column_name = $options -> {$field . '_column'} or next;
		push @fields, "$column_name = ?";
		push @params, $uploaded -> {$field};
	}
	
	foreach my $field (keys (%{$options -> {add_columns}})) {
		push @fields, "$field = ?";
		push @params, $options -> {add_columns} -> {$field};
	}
	
	@fields or return;
	
	my $tail = join ', ', @fields;
		
	sql_do ("UPDATE $$options{table} SET $tail WHERE id = ?", @params, $_REQUEST {id});
	
	return $uploaded;
	
}

################################################################################
	
sub sql_select_loop {

	my ($sql, $coderef, @params) = @_;
	
#	my $st = sql_prepare ($sql);
#	$st -> execute (@params);

	my $items = sql_select_all ($sql, @params);
	
	our $i;
	
#	while ($i = $st -> fetchrow_hashref) {
#		&$coderef ();
#	}

	foreach $i (@$items) {
		&$coderef ();
	}
	
#	$st -> finish ();

}

################################################################################

sub keep_alive {

	my $sid = shift;
	sql_do ("UPDATE $conf->{systables}->{sessions} SET ts = ? WHERE id = ? ", int(time), $sid);

}

################################################################################

sub sql_lock {

	sql_do ("PRAGMA locking_mode = EXCLUSIVE");
	keep_alive ($_REQUEST {sid});

}

################################################################################

sub sql_unlock {

	sql_do ("PRAGMA locking_mode = NORMAL");
	keep_alive ($_REQUEST {sid});

}

################################################################################

sub _sql_ok_subselects { 1 }

################################################################################

sub get_sql_translator_ref { 0 }

################################################################################
################################################################################

#package DBIx::ModelUpdate::SQLite;

#no warnings;

#use Data::Dumper;

#our @ISA = qw (DBIx::ModelUpdate);

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
