no strict;
no warnings;

################################################################################

sub sql_version {
	
	$db -> {mysql_auto_reconnect} = 0;
	
	$preconf -> {db_charset}       ||= 'utf8';		
	
	$db -> do ("SET CHARACTER SET $preconf->{db_charset}");
	
	my $character_set_connection = ($preconf -> {core_src_charset} ||= 'windows-1251');
	
	$character_set_connection =~ s{windows-}{cp};

	eval {$db -> do ("SET character_set_connection = '$character_set_connection'")} if $character_set_connection eq 'cp1251';

	my $version = $SQL_VERSION;
	
	$version -> {string} = 'MySQL ' . sql_select_scalar ('SELECT VERSION()');
	
	($version -> {number}) = $version -> {string} =~ /([\d\.]+)/;
	
	$version -> {number_tokens} = [split /\./, $version -> {number}];

	$db -> {HandleError} = sub {

		my $err = $_[0] or return 0;
		
		if (
			$err =~ m{Incorrect key file for table .*?(\w+)\.MYI'} || 
			$err =~ m{Table .*?(\w+)' is marked as crashed and should be repaired}
		) {

			warn "FOUND CORRUPTED TABLE [$1]! TRYING TO 'REPAIR TABLE `$1` QUICK' ORIG ERR:[$err]";

			my $db_repair = DBI -> connect ($preconf -> {'db_dsn'}, $preconf -> {'db_user'}, $preconf -> {'db_password'}, {
				AutoCommit  => 1,
				LongReadLen => 100000000,
				LongTruncOk => 1,
				InactiveDestroy => 0,
			});
			
			$db_repair -> do ("REPAIR TABLE `$1` QUICK") or warn "UNABLE TO REPAIR [$1]: ", $db -> errstr;

			$db_repair -> disconnect;

		}

		return 0;

	};

	return $version;
	
}

################################################################################

sub sql_do {

	darn \@_ if $preconf -> {core_debug_sql_do};

	my ($sql, @params) = @_;

#	undef $__last_insert_id if $sql =~ /INSERT/i;
	my $ids = '-1';

	if ($conf -> {'db_temporality'} && $_REQUEST {_id_log}) {
			
		my $insert_sql = '';
		my $update_sql = '';

		if ($sql =~ /\s*DELETE\s+FROM\s*(\w+).*?(WHERE.*)/i && $1 ne $conf -> {systables} -> {log} && sql_is_temporal_table ($1)) {
		
			my $cols = join ', ', keys %{$model_update -> get_columns ($1)};

			my $select_sql = "SELECT id FROM $1 $2";
			my $param_number = $select_sql =~ y/?/?/;

			my @copy_params = (@params);
			splice (@copy_params, 0, @params - $param_number);

			$ids = sql_select_ids ($select_sql, @copy_params);

			$update_sql = "UPDATE __log_$1 SET __is_actual = 0 WHERE id IN ($ids) AND __is_actual = 1";
			$insert_sql = "INSERT INTO __log_$1 ($cols, __dt, __op, __id_log, __is_actual) SELECT $cols, NOW() AS __dt, 3 AS __op, $_REQUEST{_id_log} AS __id_log, 1 AS __is_actual FROM $1 WHERE $1.id IN ($ids)";
			
		}
		elsif ($sql =~ /\s*UPDATE\s*(\w+).*?(WHERE.*)/i && $1 ne $conf -> {systables} -> {log} && sql_is_temporal_table ($1)) {
		
			my $cols = join ', ', keys %{$model_update -> get_columns ($1)};

			my $select_sql = "SELECT id FROM $1 $2";
			my $param_number = $select_sql =~ y/?/?/;

			my @copy_params = (@params);
			splice (@copy_params, 0, @params - $param_number);
			$ids = sql_select_ids ($select_sql, @copy_params);

		}
		
		$db -> do ($update_sql) if $update_sql;
		$db -> do ($insert_sql) if $insert_sql;

	}	
	
	$sql .= " # type='$_REQUEST{type}', id='$_REQUEST{id}', action='$_REQUEST{action}', user=$_USER->{id}, process=$$";

	my $st = $db -> prepare ($sql);

#	if ($preconf -> {core_fix_tz}) {
#		for (my $i=0; $i < @params; $i ++) {
#			if ($params [$i] =~ /^(\d{4})-(\d{1,2})-(\d{1,2}) (\d{2}):(\d{2})(:(\d{2}))?$/) {
#				$params [$i] = sprintf ('%04d-%02d-%02d %02d:%02d:%02d', Date::Calc::Add_Delta_DHMS ($1, $2, $3, $4, $5, $7 || 0, 0, $_USER -> {tz_offset} + 0 || 0, 0, 0));
#			}
#		}
#	}

	$st -> execute (@params);
	$st -> finish;	
	
	if ($conf -> {'db_temporality'} && $_REQUEST {_id_log}) {
			
		my $insert_sql = '';
		my $update_sql = '';
		
		if ($sql =~ /\s*UPDATE\s*(\w+).*?(WHERE.*)/i && $1 ne $conf -> {systables} -> {log} && sql_is_temporal_table ($1)) {

			my $cols = join ', ', keys %{$model_update -> get_columns ($1)};
			$update_sql = "UPDATE __log_$1 SET __is_actual = 0 WHERE id IN ($ids) AND __is_actual = 1";
			$insert_sql = "INSERT INTO __log_$1 ($cols, __dt, __op, __id_log, __is_actual) SELECT $cols, NOW() AS __dt, 1 AS __op, $_REQUEST{_id_log} AS __id_log, 1 AS __is_actual FROM $1 WHERE $1.id IN ($ids)";

		}
		elsif ($sql =~ /\s*INSERT\s+INTO\s*(\w+)/i && $1 ne $conf -> {systables} -> {log} && sql_is_temporal_table ($1)) {

			my $cols = join ', ', keys %{$model_update -> get_columns ($1)};
			our $__last_insert_id = sql_last_insert_id ();
			$update_sql = "UPDATE __log_$1 SET __is_actual = 0 WHERE id = $__last_insert_id AND __is_actual = 1";
			$insert_sql = "INSERT INTO __log_$1 ($cols, __dt, __op, __id_log, __is_actual) SELECT $cols, NOW() AS __dt, 0 AS __op, $_REQUEST{_id_log} AS __id_log, 1 AS __is_actual FROM $1 WHERE $1.id = $__last_insert_id";

		}

		$db -> do ($update_sql) if $update_sql;
		$db -> do ($insert_sql) if $insert_sql;

	}	
	
}

################################################################################

sub sql_select_all_cnt {

	my ($sql, @params) = @_;
	
	$sql =~ s{^\s+}{};
	
	my $options = {};
	if (@params > 0 and ref ($params [-1]) eq HASH) {
		$options = pop @params;
	}
	
	if ($options -> {fake}) {
	
		my $where = 'WHERE ';
		my $fake  = $_REQUEST {fake} || 0;
		my $condition = $fake =~ /\,/ ? "IN ($fake)" : '=' . $fake;
	
		foreach my $table (split /\,/, $options -> {fake}) {
			$where .= "$table.fake $condition AND ";
		}	
		
		$sql =~ s{where}{$where}i;
			
	}

	if ($_REQUEST {xls} && $conf -> {core_unlimit_xls} && !$_REQUEST {__limit_xls}) {
		$sql =~ s{\bLIMIT\b.*}{}ism;
		my $result = sql_select_all ($sql, @params, $options);
		my $cnt = ref $result eq ARRAY ? 0 + @$result : -1;
		return ($result, $cnt);
	}

	if ((!$conf -> {core_infty} && $_REQUEST {__infty}) || ($conf -> {core_infty} && !$_REQUEST {__no_infty})) {
		
		$sql =~ s{LIMIT\s+(\d+)\s*\,\s*(\d+)}{LIMIT $1, @{[$2 + 1]}}ism;
		
		my ($start, $portion) = ($1, $2);
				
		my $result = sql_select_all ($sql, @params, $options);
		my $cnt = ref $result eq ARRAY ? 0 + @$result : 0;
				
		if (0 + @$result <= $portion) {
			return ($result, $start + $cnt);
		}
		else {
			pop @$result;
			return ($result, -1);
		}
		
		
	}
	
	if ($SQL_VERSION -> {number_tokens} -> [0] > 3) {	
		$sql =~ s{SELECT}{SELECT SQL_CALC_FOUND_ROWS}i;
	}
	
	$sql .= " # type='$_REQUEST{type}', id='$_REQUEST{id}', action='$_REQUEST{action}', user=$_USER->{id}, process=$$";

	my $st = $db -> prepare ($sql);
	$st -> execute (@params);
	
	return $st if $options -> {no_buffering};
	
	my $result = $st -> fetchall_arrayref ({});	
	$st -> finish;

	my $cnt = 0;	

	if ($SQL_VERSION -> {number_tokens} -> [0] > 3) {
	
		$cnt = $db -> selectrow_array ("select found_rows()");
		
	}
	else {
	
		$sql =~ s{SELECT.*?FROM}{SELECT COUNT(*) FROM}ism;
		if ($sql =~ s{\bLIMIT\b.*}{}ism) {
#			pop @params;
		}

		$sql .= " # type='$_REQUEST{type}', id='$_REQUEST{id}', action='$_REQUEST{action}', user=$_USER->{id}, process=$$";

		$st = $db -> prepare ($sql);
		$st -> execute (@params);

		if ($sql =~ /GROUP\s+BY/i) {
			$cnt++ while $st -> fetch ();
		}
		else {
			$cnt = $st -> fetchrow_array ();
		}
		
	}
	
	return ($result, $cnt);

}

################################################################################

sub sql_select_all {

	my ($sql, @params) = @_;

	$sql =~ s{^\s+}{};
		
	my $options = {};
	if (@params > 0 and ref ($params [-1]) eq HASH) {
		$options = pop @params;
	}
	
	if ($options -> {fake}) {
	
		my $where = 'WHERE ';
		my $fake  = $_REQUEST {fake} || 0;
		my $condition = $fake =~ /\,/ ? "IN ($fake)" : '=' . $fake;
	
		foreach my $table (split /\,/, $options -> {fake}) {
			$where .= "$table.fake $condition AND ";
		}	
		
		$sql =~ s{where}{$where}i;
			
	}
	
	$sql .= " # type='$_REQUEST{type}', id='$_REQUEST{id}', action='$_REQUEST{action}', user=$_USER->{id}, process=$$";

	my $st = $db -> prepare ($sql);
	$st -> execute (@params);

	return $st if $options -> {no_buffering};

	my $result = $st -> fetchall_arrayref ({});	
	$st -> finish;
	
	$_REQUEST {__benchmarks_selected} += @$result;
	
	return $result;	

}

################################################################################

sub sql_select_all_hash {

	my ($sql, @params) = @_;
	
	$sql =~ s{^\s+}{};

	$sql =~ /GROUP\s+BY/i or $sql .= ' GROUP BY 1';

	my $options = {};
	if (@params > 0 and ref ($params [-1]) eq HASH) {
		$options = pop @params;
	}
	
	if ($options -> {fake}) {
	
		my $where = 'WHERE ';
		my $fake  = $_REQUEST {fake} || 0;
		my $condition = $fake =~ /\,/ ? "IN ($fake)" : '=' . $fake;
	
		foreach my $table (split /\,/, $options -> {fake}) {
			$where .= "$table.fake $condition AND ";
		}	
		
		$sql =~ s{where}{$where}i;
			
	}
	
	my $result = {};
	
	$sql .= " # type='$_REQUEST{type}', id='$_REQUEST{id}', action='$_REQUEST{action}', user=$_USER->{id}, process=$$";

	my $st = $db -> prepare ($sql);
	$st -> execute (@params);
	
	while (my $r = $st -> fetchrow_hashref) {
		$result -> {$r -> {id}} = $r;
	}
	
	$st -> finish;
	
	return $result;

}

################################################################################

sub sql_select_col {

	my ($sql, @params) = @_;

	$sql =~ s{^\s+}{};
		
	$sql .= " # type='$_REQUEST{type}', id='$_REQUEST{id}', action='$_REQUEST{action}', user=$_USER->{id}, process=$$";

	my @result = ();
	my $st = $db -> prepare ($sql);
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
		
	if ($sql_or_table_name !~ /^\s*(SELECT|HANDLER)/i) {
	
		my $id = $_REQUEST {id};
		
		if (@params) {
			$id = ref $params [0] eq HASH ? $params [0] -> {id} : $params [0];
		}
	
		@params = ({}) if (@params == 0);
		
		$_REQUEST {__the_table} ||= $sql_or_table_name;
		
		return sql_select_hash ("SELECT * FROM $sql_or_table_name WHERE id = ?", $id);
		
	}	

	$sql_or_table_name =~ s{^\s+}{};
	
	if (!$_REQUEST {__the_table} && $sql_or_table_name =~ /\s+FROM\s+(\w+)/sm) {
	
		$_REQUEST {__the_table} = $1;
	
	}
	
	$sql_or_table_name .= " # type='$_REQUEST{type}', id='$_REQUEST{id}', action='$_REQUEST{action}', user=$_USER->{id}, process=$$";

	my $st = $db -> prepare ($sql_or_table_name);
	$st -> execute (@params);
	my $result = $st -> fetchrow_hashref ();
	$st -> finish;

	return $result;

}

################################################################################

sub sql_select_array {

	my ($sql, @params) = @_;
	$sql =~ s{^\s+}{};

	$sql .= " # type='$_REQUEST{type}', id='$_REQUEST{id}', action='$_REQUEST{action}', user=$_USER->{id}, process=$$";

	my $st = $db -> prepare ($sql);
	$st -> execute (@params);
	my @result = $st -> fetchrow_array ();
	$st -> finish;

	return wantarray ? @result : $result [0];

}

################################################################################

sub sql_select_scalar {

	my ($sql, @params) = @_;
	$sql =~ s{^\s+}{};

	my $options = {};
	if (@params > 0 and ref ($params [-1]) eq HASH) {
		$options = pop @params;
	}
	
	if ($options -> {fake}) {
	
		my $where = 'WHERE ';
		my $fake  = $_REQUEST {fake} || 0;
		my $condition = $fake =~ /\,/ ? "IN ($fake)" : '=' . $fake;
	
		foreach my $table (split /\,/, $options -> {fake}) {
			$where .= "$table.fake $condition AND ";
		}	
		
		$sql =~ s{where}{$where}i;
			
	}

	$sql .= " # type='$_REQUEST{type}', id='$_REQUEST{id}', action='$_REQUEST{action}', user=$_USER->{id}, process=$$";

	my $st = $db -> prepare ($sql);
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
	
	$options -> {filter} = " AND $options->{filter}"
		if $options->{filter};
	my @ids = ($id);
	
	while (TRUE) {
	
		my $ids = join ',', @ids;
	
		my @new_ids = sql_select_col ("SELECT id FROM $table_name WHERE fake = 0 AND parent IN ($ids) AND id NOT IN ($ids) $options->{filter}");
		
		last unless @new_ids;
	
		push @ids, @new_ids;
	
	}
	
	return @ids;

}

################################################################################

sub sql_last_insert_id {
	return $__last_insert_id || sql_select_scalar ("SELECT LAST_INSERT_ID()") || 0;
}

################################################################################

sub sql_do_insert {

	my ($table_name, $pairs) = @_;
		
	my $fields = '';
	my $args   = '';
	my @params = ();

	$pairs -> {fake} = $_REQUEST {sid} unless exists $pairs -> {fake};
	
	my $statement = 'INSERT';

	if (is_recyclable ($table_name)) {
	
		assert_fake_key ($table_name);

		### all orphan records are now mine

		sql_do (<<EOS, $_REQUEST {sid});
			UPDATE
				$table_name
				LEFT JOIN $conf->{systables}->{sessions} ON $table_name.fake = $conf->{systables}->{sessions}.id
			SET	
				$table_name.fake = ?
			WHERE
				$table_name.fake > 0
				AND $conf->{systables}->{sessions}.id_user IS NULL
EOS

		### get my least fake id (maybe ex-orphan, maybe not)

		$__last_insert_id = sql_select_scalar ("SELECT id FROM $table_name WHERE fake = ? ORDER BY id LIMIT 1", $_REQUEST {sid});
		
		if ($__last_insert_id) {
			$pairs -> {id} = $__last_insert_id;
			$statement = 'REPLACE';
		}
	
	}

	foreach my $field (keys %$pairs) {
		my $value = $pairs -> {$field};
		my $comma = @params ? ', ' : '';
		$fields .= "$comma $field";
		$args   .= "$comma ?";
		push @params, $value;
	}

	sql_do ("$statement INTO $table_name ($fields) VALUES ($args)", @params);

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

	$options -> {id} ||= $_REQUEST {id};

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
		
	sql_do ("UPDATE $$options{table} SET $tail WHERE id = ?", @params, $options -> {id});
	
	return $uploaded;
	
}

################################################################################

sub keep_alive {
	my $sid = shift;
	sql_do ("UPDATE $conf->{systables}->{sessions} SET ts = NULL WHERE id = ? ", $sid);
}

################################################################################

sub select__table_data {

	exit if $_REQUEST {table} eq $conf -> {systables} -> {sessions};
	
	my $table = $DB_MODEL -> {tables} -> {$_REQUEST {table}} or exit;
	
	my $columns = join ', ', sort ('id', 'fake', keys %{$table -> {columns}});
	
	my $fn = '/i/upload/images/' . $_REQUEST {table} . '.txt';
	
	my $filename = $r -> document_root () . $fn;
	
	unlink $filename if -f $filename;
	
	sql_do ("SELECT $columns FROM $_REQUEST{table} INTO OUTFILE '$filename'");
	
	redirect ($fn);
	
}

################################################################################

sub download_table_data {

	my ($options) = @_;
	
	my $table = $DB_MODEL -> {tables} -> {$options -> {table}} or exit;
	
	my $columns = join ', ', sort ('id', 'fake', keys %{$table -> {columns}});

	my $filename = $r -> document_root () . '/i/upload/images/_' . $options -> {table} . '.txt';
	
	unlink $filename if -f $filename;
	
	lrt_print ("Downloading " . $options -> {table} . '...');
	
	require LWP;
	require LWP::UserAgent;
	
	my $ua = new LWP::UserAgent ();
	$ua -> env_proxy;

	my $url = "$$options{host}/?__login=$$options{login}&__password=$$options{password}&type=_table_data&table=$$options{table}";

	my $request = HTTP::Request -> new (GET => $url);
	my $response = $ua -> request ($request, $filename);
	my $code = $response -> code;

	if (HTTP::Status::is_error ($code)) {
		lrt_ok (HTTP::Status::status_message ($code) . " ($url)", 1);
		return;	
	}
	
	open (F, $filename);
	my $line = <F>;
	close F;
	
	if ($line =~ /\s+\<html/) {
		lrt_ok (' :-( ', 1);
#		unlink $filename;
		return;
	}

	chmod 0777, $filename;
	
	lrt_ok ();
	
	lrt_print ("Truncating " . $options -> {table} . '...');
	
	sql_do ("TRUNCATE TABLE $$options{table}");
	
	lrt_ok ();
	
	lrt_print ("Loading " . $options -> {table} . '...');
		
	sql_do ("LOAD DATA INFILE '$filename' INTO TABLE $$options{table} ($columns)");

#	unlink $filename;

	lrt_ok ();

}
################################################################################

sub sql_select_loop {

	my ($sql, $coderef, @params) = @_;
	$sql =~ s{^\s+}{};

	$sql .= " # type='$_REQUEST{type}', id='$_REQUEST{id}', action='$_REQUEST{action}', user=$_USER->{id}, process=$$";

	my $st = $db -> prepare ($sql);
	$st -> execute (@params);
	
	local $i;
	while ($i = $st -> fetchrow_hashref) {
		&$coderef ();
	}
	
	$st -> finish ();

}

################################################################################

sub sql_lock {

	sql_do ("LOCK TABLES $_[0] WRITE, $conf->{systables}->{sessions} WRITE");

}

################################################################################

sub sql_unlock {

	sql_do ("UNLOCK TABLES");

}

################################################################################

sub _sql_ok_subselects { 0 }

################################################################################

sub get_sql_translator_ref { 0 }

1;
