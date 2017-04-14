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

	$db -> {sqlite_unicode} = 1;

	$db -> func ('REPLACE', 3, sub { my ($s, $from, $to) = @_; $s =~ s{$from}{$to}g; return $s }, 'create_function');
	$db -> func ('CONCAT',  2, sub { return $_[0] . $_[1] }, 'create_function');
	$db -> func ('CONCAT',  3, sub { return $_[0] . $_[1] . $_[2] }, 'create_function');
	$db -> func ('NOW',     0, sub { return POSIX::strftime ('%Y-%m-%d %H:%M:%S', localtime (time)) }, 'create_function');	
	$db -> func ('DATE_FORMAT', 2, sub { return _sqlite_format_datetime ($_[1], _sqlite_parse_datetime ($_[0])) }, 'create_function');	

	my $version = $SQL_VERSION;
	
	$version -> {string} = 'SQLite ' . sql_select_scalar ('SELECT sqlite_version(*)');
	
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

sub sql_do {
	darn \@_ if $preconf -> {core_debug_sql_do};
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
	
	if ($sql =~ s{\bLIMIT\b.*}{}ism) {
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
		
		$_REQUEST {__the_table} = $sql_or_table_name;

		return sql_select_hash ("SELECT * FROM $sql_or_table_name WHERE $field = ?", $id);

	}	
	
	if (!$_REQUEST {__the_table} && $sql_or_table_name =~ /\s+FROM\s+(\w+)/sm) {
	
		$_REQUEST {__the_table} = $1;
	
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

	$options -> {id} ||= $_REQUEST {id};

	foreach my $column (@{$options -> {file_path_columns}}) {
		my $path = sql_select_array ("SELECT $column FROM $$options{table} WHERE id = ?", $options -> {id});
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

1;
