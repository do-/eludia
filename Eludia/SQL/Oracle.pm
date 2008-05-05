no strict;
no warnings;

#use DBD::Oracle qw(:ora_types);
#use Carp qw(cluck);

################################################################################

sub sql_version {

	my $version = {	strings => [ sql_select_col ('SELECT * FROM V$VERSION') ] };
	
	$version -> {string} = $version -> {strings} -> [0];
	
	($version -> {number}) = $version -> {string} =~ /([\d\.]+)/;
	
	$version -> {number_tokens} = [split /\./, $version -> {number}];
	
	return $version;
	
}

################################################################################

sub sql_do_refresh_sessions {

	my $timeout = $conf -> {session_timeout} || 30;

	if ($preconf -> {core_auth_cookie} =~ /^\+(\d+)([mhd])/) {
		$timeout = $1;
		$timeout *= 
			$2 eq 'h' ? 60 :
			$2 eq 'd' ? 1440 :
			1;
	}
	
	my $ids = sql_select_ids ("SELECT id FROM $conf->{systables}->{sessions} WHERE ts < sysdate - ?", $timeout / 1440);

	if ($ids ne '-1') {

		sql_do ("DELETE FROM $conf->{systables}->{sessions} WHERE id IN ($ids)") ;

		$ids = sql_select_ids ("SELECT DISTINCT id_session FROM $conf->{systables}->{__access_log} MINUS SELECT id FROM $conf->{systables}->{sessions}");

		sql_do ("DELETE FROM $conf->{systables}->{__access_log} WHERE id_session IN ($ids)") if $ids ne '-1';

	}	

	sql_do ("UPDATE $conf->{systables}->{sessions} SET ts = sysdate WHERE id = ?", $_REQUEST {sid});

}

################################################################################

sub sql_execute {
	
	my ($st, @params) = sql_prepare (@_);

	my $affected = $st -> execute (@params);
	
	return wantarray ? ($st, $affected) : $st;

}

################################################################################

sub sql_prepare {

	my ($sql, @params) = @_;

	$sql =~ s{^\s+}{};
	
#print STDERR "sql_prepare (pid=$$): $sql\n";
	
	my $qoute = '"';

	if ($sql =~ /^(\s*SELECT.*FROM\s+)(.*)$/is) {
	
		my ($head, $tables_reference, $tail) = ($1, $2);
		
		if ($tables_reference =~ /^(.*)((WHERE|GROUP|ORDER).*)$/is) {
			($tables_reference, $tail) = ($1, $2);
		}
#		print "head: $head\ntables_reference: $tables_reference\ntail: $tail\n\n";
		my @table_names;
		if ($tables_reference =~ s/^(_\w+)/$qoute$1$qoute/) {
			push (@table_names, $1);
		}
		push (@table_names, $1) while ($tables_reference =~ s/,\s*(_\w+)/, $qoute$1$qoute/ig);
		push (@table_names, $1) while ($tables_reference =~ s/JOIN\s*(_\w+)/JOIN $qoute$1$qoute/ig);
		$sql = $head . $tables_reference . $tail;
		foreach my $table_name (@table_names) {
#			print "table_name: $table_name\n";
			$sql =~ s/(\W)($table_name)\./$1$qoute$2$qoute\./g;
		}
	} 
	
	$sql =~ s/^(\s*UPDATE\s+)(_\w+)/$1$qoute$2$qoute/is;
	$sql =~ s/^(\s*INSERT\s+INTO\s+)(_\w+)/$1$qoute$2$qoute/is;
	$sql =~ s/^(\s*DELETE\s+FROM\s+)(_\w+)/$1$qoute$2$qoute/is;

	if ($sql =~ /\bIF\s*\((.+?),(.+?),(.+?)\s*\)/igsm) {
		
		$sql = mysql_to_oracle ($sql) if $conf -> {core_auto_oracle};

		($sql, @params) = sql_extract_params ($sql, @params) if ($conf -> {core_sql_extract_params} && $sql =~ /^\s*(SELECT|INSERT|UPDATE|DELETE)/i);

	} else {

		($sql, @params) = sql_extract_params ($sql, @params) if ($conf -> {core_sql_extract_params} && $sql =~ /^\s*(SELECT|INSERT|UPDATE|DELETE)/i);

		$sql = mysql_to_oracle ($sql) if $conf -> {core_auto_oracle};

	}
	
	my $st;

	eval {$st = $db  -> prepare_cached ($sql, {
		ora_auto_lob => ($sql !~ /for\s+update\s*/ism),
	}, 4)};
	
	if ($@) {
		my $msg = "sql_prepare: $@ (SQL = $sql)\n";
		print STDERR $msg;
		die $msg;
	}
		
	return ($st, @params);

}

################################################################################

sub sql_do {

	my ($sql, @params) = @_;
	
	my $time = time;

	(my $st, $affected) = sql_execute ($sql, @params);

	$st -> finish;	

	__log_sql_profilinig ({time => $time, sql => $sql, selected => $affected});	
	
}

################################################################################

sub sql_execute_procedure {

	my ($sql, @params) = @_;

	my $time = time;	

	$sql .= ';' unless $sql =~ /;[\n\r\s]*$/;
	
	(my $st, @params) = sql_prepare ($sql, @params);

	my $i = 1;
	while (@params > 0) {
		my $val = shift (@params);
		if (ref $val eq 'SCALAR') {
			$st -> bind_param_inout ($i, $val, shift (@params));
		} else {
			$st -> bind_param ($i, $val);
		}
		$i ++; 
	}
	
	eval {
		$st -> execute;
	};
	

	if ($@) {
		local $SIG {__DIE__} = 'DEFAULT';
		if ($@ =~ /ORA-\d+:(.*)/) {
			die "$1\n";
	  } else {
			die $@;
		}
		
	}

	$st -> finish;	

	__log_sql_profilinig ({time => $time, sql => $sql, selected => 0});	
	
}

################################################################################

sub sql_select_all_cnt {

	my ($sql, @params) = @_;

	if ($sql =~ m/\bLIMIT\s+\d+\s*$/igsm) {
		$sql =~ s/\bLIMIT\s+(\d+)\s*$/LIMIT 0,$1/igsm;
	}

	unless ($sql =~ s{LIMIT\s+(\d+)\s*\,\s*(\d+).*}{}ism) {
		return sql_select_all ($sql, @params);
	}

	my ($start, $portion) = ($1, $2);

	my $options = {};
	if (@params > 0 and ref ($params [-1]) eq HASH) {
		$options = pop @params;
	}
	
	$sql = sql_adjust_fake_filter ($sql, $options);
	
	if ($_REQUEST {xls} && $conf -> {core_unlimit_xls} && !$_REQUEST {__limit_xls}) {
		$sql =~ s{LIMIT.*}{}ism;
		my $result = sql_select_all ($sql, @params, $options);
		my $cnt = ref $result eq ARRAY ? 0 + @$result : -1;
		return ($result, $cnt);
	}

	my $time = time;	

	my $st = sql_execute ($sql, @params);
	
	my $cnt = 0;	
	my @result = ();
	
	while (my $i = $st -> fetchrow_hashref ()) {
	
		$cnt++;
		
		$cnt > $start or next;
		$cnt <= $start + $portion or last;
			
		push @result, lc_hashref ($i);
	
	}
	
	$st -> finish;

	__log_sql_profilinig ({time => $time, sql => $sql, selected => @result + 0});	


	$sql =~ s{ORDER BY.*}{}ism;


	my $cnt = 0;

	if ($sql =~ /(\s+GROUP\s+BY|\s+UNION\s+)/i) {
		my $temp = sql_select_all($sql, @params);
		$cnt = (@$temp + 0);
	}
	else {
		$sql =~ s/SELECT.*?[\n\s]+FROM[\n\s]+/SELECT COUNT(*) FROM /ism;
		$cnt = sql_select_scalar ($sql, @params);
	}
			
	return (\@result, $cnt);

}


################################################################################

sub sql_select_all {

	my ($sql, @params) = @_;
	my $result;

	if ($sql =~ m/\bLIMIT\s+\d+\s*$/igsm) {
		$sql =~ s/\bLIMIT\s+(\d+)\s*$/LIMIT 0,$1/igsm;
	}

	my $options = {};
	if (@params > 0 and ref ($params [-1]) eq HASH) {
		$options = pop @params;
	}
	
	$sql = sql_adjust_fake_filter ($sql, $options);

	my $time = time;	

	if ($sql =~ s{LIMIT\s+(\d+)\s*\,\s*(\d+).*}{}ism) {

		my @temp_result = ();
		my ($start, $portion) = ($1, $2);

		($start, $portion) = (0, $start) unless ($portion);
		my $st = sql_execute ($sql, @params);
		my $cnt = 0;	
 	
		while (my $r = $st -> fetchrow_hashref) {
	
			$cnt++;
		
			$cnt > $start or next;
			$cnt <= $start + $portion or last;
			
			push @temp_result, $r;
	
		}
		
		$result = \@temp_result;
	
		$st -> finish;
	}
	else {
	
		my $st = sql_execute ($sql, @params);

		return $st if $options -> {no_buffering};

		$result = $st -> fetchall_arrayref ({});	

		$st -> finish;

        }
	
	__log_sql_profilinig ({time => $time, sql => $sql, selected => @$result + 0});	

	foreach my $i (@$result) {
		lc_hashref ($i);
	}

	$_REQUEST {__benchmarks_selected} += @$result;
	
	return $result;

}

################################################################################

sub sql_select_all_hash {

	my ($sql, @params) = @_;

	my $options = {};
	if (@params > 0 and ref ($params [-1]) eq HASH) {
		$options = pop @params;
	}
	
	$sql = sql_adjust_fake_filter ($sql, $options);

	my $result = {};
	my $time = time;	

	my $st = sql_execute ($sql, @params);

	while (my $r = $st -> fetchrow_hashref) {
		lc_hashref ($r);		                       	
		$result -> {$r -> {id}} = $r;
	}
	
	$st -> finish;
	__log_sql_profilinig ({time => $time, sql => $sql, selected => (keys %$result) + 0});	

	return $result;

}


################################################################################

sub sql_select_col {

	my ($sql, @params) = @_;

	my @result = ();

	if ($sql =~ m/\bLIMIT\s+\d+\s*$/igsm) {
		$sql =~ s/\bLIMIT\s+(\d+)\s*$/LIMIT 0,$1/igsm;
	}

	my $time = time;	

	if ($sql =~ s{LIMIT\s+(\d+)\s*\,\s*(\d+).*}{}ism) {

		my ($start, $portion) = ($1, $2);

		($start, $portion) = (0, $start) unless ($portion);
	
		my $st = sql_execute ($sql, @params);

		my $cnt = 0;	
 	
		while (my @r = $st -> fetchrow_array ()) {
	
			$cnt++;
		
			$cnt > $start or next;
			$cnt <= $start + $portion or last;
			
			push @result, @r;
	
		}
	
		$st -> finish;

	} else {

		my $st = sql_execute ($sql, @params);

		while (my @r = $st -> fetchrow_array ()) {
			push @result, @r;
		}

		$st -> finish;

	}

	__log_sql_profilinig ({time => $time, sql => $sql, selected => @result + 0});	
	
	return @result;

}

################################################################################

sub lc_hashref {

	my ($hr) = @_;
	
	return undef unless (defined $hr);	

	if ($conf -> {core_auto_oracle}) {	
		foreach my $key (keys %$hr) {
		        my $old_key = $key;
			$key =~ s/RewbfhHHkgkglld/user/gsm;
			$key =~ s/NbhcQQehgdfjfxf/level/gsm;
			$key =~ s/Iuhjdwxsttebnmn/minus/gsm;
			$hr -> {lc $key} = $hr -> {$old_key};
			delete $hr -> {uc $key};
		}
	}
	else {
		foreach my $key (keys %$hr) {
			$hr -> {lc $key} = $hr -> {$key};
			delete $hr -> {uc $key};
		}
	}

	delete $hr -> {REWBFHHHKGKGLLD};
	delete $hr -> {NBHCQQEHGDFJFXF};
	delete $hr -> {IUHJDWXSTTEBNMN};

	return $hr;

}

################################################################################

sub sql_select_hash {

	my ($sql_or_table_name, @params) = @_;

	$sql_or_table_name =~ s/\bLIMIT.*//igsm;		
	
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
	
	my $time = time;	

	my $st = sql_execute ($sql_or_table_name, @params);

	my $result = $st -> fetchrow_hashref ();

	$st -> finish;		

	__log_sql_profilinig ({time => $time, sql => $sql_or_table_name, selected => 1});	
	
	return lc_hashref ($result);

}

################################################################################

sub sql_select_array {

	my ($sql, @params) = @_;

	$sql =~ s/\bLIMIT\s+\d+\s*$//igsm;

	my $time = time;	

	my $st = sql_execute ($sql, @params);

	my @result = $st -> fetchrow_array ();

	$st -> finish;

	__log_sql_profilinig ({time => $time, sql => $sql_or_table_name, selected => 1});	
	
	return wantarray ? @result : $result [0];

}

################################################################################

sub sql_select_scalar {

	my ($sql, @params) = @_;

	my @result;

	if ($sql =~ m/\bLIMIT\s+\d+\s*$/igsm) {
		$sql =~ s/\bLIMIT\s+(\d+)\s*$/LIMIT 0,$1/igsm;
	}

	my $time = time;	

	if ($sql =~ s{LIMIT\s+(\d+)\s*\,\s*(\d+).*}{}ism) {

		my ($start, $portion) = ($1, $2);

		($start, $portion) = (0, $start) unless ($portion);
	
		my $st = sql_execute ($sql, @params);

		my $cnt = 0;	
	
		while (my @r = $st -> fetchrow_array ()) {
	
			$cnt++;
		
			$cnt > $start or next;
			$cnt <= $start + $portion or last;
			
			push @result, @r;
			last;
	
		}
	
		$st -> finish;

	} 
	else {

		my $st = sql_execute ($sql, @params);

		@result = $st -> fetchrow_array ();

		$st -> finish;

	}
	
	__log_sql_profilinig ({time => $time, sql => $sql, selected => 1});	

	return $result [0];

}

################################################################################

sub sql_select_path {
	
	my ($table_name, $id, $options) = @_;
	
	$options -> {name}     ||= 'name';
	$options -> {type}     ||= $table_name;
	$options -> {id_param} ||= 'id';

	my ($parent) = $id;

	my @path = ();

	sql_select_loop (
		
		"SELECT id, parent, $options->{name} AS name FROM $table_name START WITH id = ? CONNECT BY PRIOR parent = id",
		
		sub { foreach (qw(type id_param cgi_tail)) { $i -> {$_} = $options -> {$_}}; push @path, $i },
		
		$id,
		
	);
	
	if ($options -> {root}) {
		push @path, {
			id => 0, 
			parent => 0, 
			name => $options -> {root}, 
			type => $options -> {type}, 
			id_param => $options -> {id_param},
			cgi_tail => $options -> {cgi_tail},
		};
	}

	return [reverse @path];

}

################################################################################

sub sql_select_subtree {

	my ($table_name, $id, $options) = @_;
	
	return sql_select_col ("SELECT id FROM $table_name START WITH id IN ($id) CONNECT BY PRIOR id = parent");
	
}

################################################################################

sub sql_do_update {

	my ($table_name, $field_list, $options) = @_;
	
	ref $options eq HASH or $options = {
		stay_fake => $options,
		id        => $_REQUEST {id},
	};
	
	$options -> {id} ||= $_REQUEST {id};
		
#	my %lobs = map {$_ => 1} @{$options -> {lobs}};
	
#	my @field_list = grep {!$lobs {$_}} @$field_list;
                      
	if (@$field_list > 0) {
		my $sql = join ', ', map {"$_ = ?"} @$field_list;
		$options -> {stay_fake} or $sql .= ', fake = 0';
		$sql = "UPDATE $table_name SET $sql WHERE id = ?";	

		my @params = @_REQUEST {(map {"_$_"} @$field_list)};	
		push @params, $options -> {id};
		sql_do ($sql, @params);

	}
	

}

################################################################################

sub sql_increment_sequence {

	my ($seq_name, $step) = @_;
	
	sql_do            ("ALTER SEQUENCE $seq_name INCREMENT BY $step");
	my $id = sql_select_scalar ("SELECT $seq_name.nextval FROM DUAL");
	sql_do            ("ALTER SEQUENCE $seq_name INCREMENT BY 1");
	
	return $id;

}

################################################################################

sub sql_do_insert {

	my ($table_name, $pairs) = @_;
		
	my $fields = '';
	my $args   = '';
	my @params = ();

	$pairs -> {fake} = $_REQUEST {sid} unless exists $pairs -> {fake};

	if (is_recyclable ($table_name)) {
	
		assert_fake_key ($table_name);

		### all orphan records are now mine

		sql_do (<<EOS, $_REQUEST {sid});
			UPDATE
				$table_name
			SET	
				$table_name.fake = ?
			WHERE
				$table_name.fake > 0
			AND
				$table_name.fake NOT IN (SELECT id FROM $conf->{systables}->{sessions})
EOS

		### get my least fake id (maybe ex-orphan, maybe not)

		$__last_insert_id = sql_select_scalar ("SELECT id FROM $table_name WHERE fake = ? ORDER BY id LIMIT 1", $_REQUEST {sid});
		
		if ($__last_insert_id) {
			sql_do ("DELETE FROM $table_name WHERE id = ?", $__last_insert_id);
			$pairs -> {id} = $__last_insert_id;
		}

	}
	
	my $seq_name;
	
	if ($conf -> {core_voc_replacement_use}) {
		my $id = sql_select_scalar ("SELECT id FROM $conf->{systables}->{__voc_replacements} WHERE table_name='$table_name' and object_type=2");
		$seq_name ='SEQ_' . $id if $id;
	}
	
	$seq_name ||= $table_name . '_SEQ';	
	
	my $nextval;
	
	eval {$nextval = sql_select_scalar ("SELECT $seq_name.nextval FROM DUAL")};
	
	if ($@) {
	
		if (sql_select_scalar ("SELECT trigger_body FROM user_triggers WHERE table_name = ? AND triggering_event like '%INSERT%'", uc $table_name) =~ /(\S+)\.nextval/ism) {
		
			$seq_name = $1;
			
			$nextval = sql_select_scalar ("SELECT $seq_name.nextval FROM DUAL");
		
		}
		
		else {
			die $@;
		}
	
	}
	
	while (1) {
	
		my $max = sql_select_scalar ("SELECT MAX(id) FROM $table_name");
		
		last if $nextval > $max;
		
		$nextval = sql_increment_sequence ($seq_name, $max + 1 - $nextval);
	
	}

	if ($pairs -> {id}) {
		
		if ($pairs -> {id} > $nextval) {
		
			my $step = $pairs -> {id} - $nextval;

			sql_increment_sequence ($seq_name, $pairs -> {id} - $nextval);

		}
	
	}
	else {
		
		$pairs -> {id} = $nextval;
		
	}
	
	foreach my $field (keys %$pairs) { 
	
		my $comma = @params ? ', ' : '';	
		
		$fields .= "$comma $field";
		$args   .= "$comma ?";

		if (exists($DB_MODEL->{tables}->{$table_name}->{columns}->{$field}->{COLUMN_DEF}) && !($pairs -> {$field})) {
			push @params, $DB_MODEL->{tables}->{$table_name}->{columns}->{$field}->{COLUMN_DEF};
		}
		else {
			push @params, $pairs -> {$field};	
		}
 		
	}

	my $time = time;
	
	if ($pairs -> {id}) {
	
		my $sql = "INSERT INTO $table_name ($fields) VALUES ($args)";

		sql_do ($sql, @params);
	
		__log_sql_profilinig ({time => $time, sql => $sql, selected => 1});	

		return $pairs -> {id};

	}
	else {

		my $sql = "INSERT INTO $table_name ($fields) VALUES ($args) RETURNING id INTO ?";

		my $st = $db -> prepare ($sql);

		my $i = 1; 
		$st -> bind_param ($i++, $_) foreach (@params);

		my $id;		
		$st -> bind_param_inout ($i, \$id, 20);

		$st -> execute;
		$st -> finish;	

		__log_sql_profilinig ({time => $time, sql => $sql, selected => 1});	

		return $id;

	}

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
	
	my $item = sql_select_hash ("SELECT * FROM $$options{table} WHERE id = ?", $_REQUEST {id});
	$options -> {size} = $item -> {$options -> {size_column}};
	$options -> {path} = $item -> {$options -> {path_column}};
	$options -> {type} = $item -> {$options -> {type_column}};
	$options -> {file_name} = $item -> {$options -> {file_name_column}};	
	
	if ($options -> {body_column}) {

		my $time = time;
		
		my $sql = "SELECT $options->{body_column} FROM $options->{table} WHERE id = ?";
		my $st = $db -> prepare ($sql, {ora_auto_lob => 0});
		$st -> execute ($_REQUEST {id});
		(my $lob_locator) = $st -> fetchrow_array ();

		my $chunk_size = 1034;
		my $offset = 1 + download_file_header (@_);
		
		while (my $data = $db -> ora_lob_read ($lob_locator, $offset, $chunk_size)) {
		      $r -> print ($data);
		      $offset += $chunk_size;
		}

		$st -> finish ();

		__log_sql_profilinig ({time => $time, sql => $sql, selected => 1});	

	}
	else {
		download_file ($options);
	}

}

################################################################################

sub sql_store_file {

	my ($options) = @_;

	my $st = $db -> prepare ("SELECT $options->{body_column} FROM $options->{table} WHERE id = ? FOR UPDATE", {ora_auto_lob => 0});

	$st -> execute ($options -> {id});
	(my $lob_locator) = $st -> fetchrow_array ();
	$st -> finish ();
	
	$db -> ora_lob_trim ($lob_locator, 0);

	$options -> {chunk_size} ||= 4096; 
	my $buffer = '';		
		
	open F, $options -> {real_path} or die "Can't open $options->{real_path}: $!\n";
		
	while (read (F, $buffer, $options -> {chunk_size})) {
		$db -> ora_lob_append ($lob_locator, $buffer);
	}

	sql_do (
		"UPDATE $$options{table} SET $options->{size_column} = ?, $options->{type_column} = ?, $options->{file_name_column} = ? WHERE id = ?",
		-s $options -> {real_path},
		$options -> {type},
		$options -> {file_name},
		$options -> {id},
	);

	close F;

}

################################################################################

sub sql_upload_file {
	
	my ($options) = @_;
	
	$options -> {id} ||= $_REQUEST {id};

	my $uploaded = upload_file ($options) or return;
	
	$options -> {body_column} or sql_delete_file ($options);
						
	if ($options -> {body_column}) {
	
		$options -> {real_path} = $uploaded -> {real_path};
		
		sql_store_file ($options);
	
		unlink $uploaded -> {real_path};

		delete $uploaded -> {real_path};

	}
	
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

	if (@fields) {
	
		my $tail = join ', ', @fields;

		sql_do ("UPDATE $$options{table} SET $tail WHERE id = ?", @params, $options -> {id});
	
	}
	
	return $uploaded;
	
}

################################################################################

sub keep_alive {
	my $sid = shift;
	sql_do ("UPDATE $conf->{systables}->{sessions} SET ts = sysdate WHERE id = ? ", $sid);
}

################################################################################

sub sql_select_loop {

	my ($sql, $coderef, @params) = @_;
	
	my $time = time;

	my $st = sql_execute ($sql, @params);
	
	our $i;
	
	while ($i = $st -> fetchrow_hashref) {
		lc_hashref ($i) if exists $$_PACKAGE {lc_hashref};
		&$coderef ();
	}
	
	$st -> finish ();

	__log_sql_profilinig ({time => $time, sql => $sql, selected => 1});	

}

#################################################################################

sub mysql_to_oracle {

my ($sql) = @_;

### Убираем пробелы перед скобками
$sql =~ s/\s*(\(|\))/\1/igsm;

our $mysql_to_oracle_cache;

my $cached = $mysql_to_oracle_cache -> {$sql};

my $src_sql = $sql;

return $cached if $cached;

my (@items,@group_by_values_ref,@group_by_fields_ref);
my ($pattern,$need_group_by);
my $sc_in_quotes=0;

#warn "ORACLE IN: <$sql>\n";

############### Заменяем неразрешенные в запросах слова на ключи (обратно восстанавливаем в lc_hashref())
$sql =~ s/([^\W]\s*\b)user\b(?!\.)/\1RewbfhHHkgkglld/igsm;
$sql =~ s/([^\W]\s*\b)level\b(?!\.)/\1NbhcQQehgdfjfxf/igsm;
$sql =~ s/([^\W]\s*\b)minus\b(?!\.)/\1Iuhjdwxsttebnmn/igsm;

############### Вырезаем и запоминаем все что внутри кавычек, помечая эти места.
while ($sql =~ /(''|'.*?[^\\]')/ism)
{	
	my $temp = $1;
	# Скобки и запятые внутри кавычек прячем чтобы не мешались при анализе и замене функций 
	$temp =~ s/\(/JKghsdgfweftyfd/gsm;
	$temp =~ s/\)/RTYfghhfFGhhjJg/gsm;
	$temp =~ s/\,/DFgpoUUYTJjkgJj/gsm;
	$in_quotes[++$sc_in_quotes]=$temp;
	$sql =~ s/''|'.*?[^\\]'/POJJNBhvtgfckjh$sc_in_quotes/ism;
}
############### Делаем из выражений в скобках псевдофункции чтобы шаблон свернулся
while ($sql =~ s/([^\w\s]+?\s*)(\()/\1VGtygvVGVYbbhyh\2/ism) {};

############### Это убираем

$sql =~ s/\bBINARY\b//igsm; 
$sql =~ s/\bAS\b\s+(?!\bSELECT\b)//igsm;
$sql =~ s/(.*?)#.*?\n/\1\n/igsm; 		 				# Убираем закомментированные строки
$sql =~ s/STRAIGHT_JOIN//igsm;					
$sql =~ s/FORCE\s+INDEX\(.*?\)//igsm;             		


############### Вырезаем функции начиная с самых вложенных и совсем не вложенных
# места помечаем ключем с номером, а сами функции с аргументами запоминаем в @items
# до тех пор пока всё не вырежем
while ($sql =~m/((\b\w+\((?!.*\().*?)\))/igsm)
{	
	$items[++$sc]=$1;
	$sql =~s/((\b\w+\((?!.*\().*?)\))/NJNJNjgyyuypoht$sc/igsm;
}

$pattern = $sql;

my @order_by;

if ($sql =~ /\s+ORDER\s+BY\s+(.*)/igsm) {
      
    @order_by = split ',',$1;
         
    foreach my $field (@order_by) {
	next if ($field =~ m/NULLS\s+(\bFIRST\b|\bLAST\b)/igsm); 
        $field .= ($field =~ m/\bDESC\b/igsm) ? ' NULLS LAST ' : ' NULLS FIRST ' ; 	
    }
			     
    $new_order_by = join ',',@order_by;
			      
    $sql =~ s/(\s+ORDER\s+BY\s+)(.*)/\1$new_order_by/igsm;
}

$need_group_by=1 if ( $sql =~ m/\s+GROUP\s+BY\s+/igsm);

if ($need_group_by) {

	# Запоминаем значения из GROUP BY до UNION или ORDER BY или HAVING
	# Также формируем массив хранящий ссылки на массивы значений для каждого SELECT
	my $sc=0;
	while ($sql =~ s/\s+GROUP\s+BY\s+(.*?)(\s+HAVING\s+|\s+UNION\s+|\s+ORDER\s+BY\s+|$)/VJkjn;lohggff\2/ism) {
		my @group_by_values = split(',',$1);                                            
		$group_by_values_ref[$sc++]=\@group_by_values;
	}

	my $sc=0;
	# Разбиваем шаблон от SELECT до FROM на поля для дальнейшего раздельного наполнения
	# и подстановки в GROUP BY вместо цифр
	while ($pattern =~ s/\bSELECT(.*?)\bFROM\b//ism) {
		my @group_by_fields = split (',',$1);
		# Удаляем алиасы
		for (my $i = 0; $i <= $#group_by_fields; $i++) {
			$group_by_fields[$i] =~ s/^\s*//igsm;
			$group_by_fields[$i] =~ s/\s+.*//igsm;
		}
		$group_by_fields_ref[$sc++]=\@group_by_fields;	
	}
}

# Если в шаблоне нет FROM - взводим флаг чтобы после замен добавить FROM DUAL 
# Делаем так потому что внутри ORACLE функции EXTRACT есть FROM
my $need_from_dual=1 if ($sql =~ m/^\s*SELECT\b/igsm && not ($sql =~ m/\bFROM\b/igsm));

# Делаем замену и собираем исходный SQL начиная с нижних уровней
for(my $i = $#items; $i >= 1; $i--) {
	# Восстанавливаем то что было внутри кавычек в аргументах функций 
	$items[$i] =~ s/POJJNBhvtgfckjh(\d+)/$in_quotes[$1]/igsm;			
	######################### Блок замен SQL синтаксиса #########################
	$items[$i] =~ s/\bIFNULL(\(.*?\))/NVL\1/igsm;
	$items[$i] =~ s/\bFLOOR(\(.*?\))/CEIL\1/igsm;
	$items[$i] =~ s/\bCONCAT\((.*?)\)/join('||',split(',',$1))/iegsm;
	$items[$i] =~ s/\bLEFT\((.+?),(.+?)\)/SUBSTR\(\1,1,\2\)/igsm;
	$items[$i] =~ s/\bRIGHT\((.+?),(.+?)\)/SUBSTR\(\1,LENGTH\(\1\)-\(\2\)+1,LENGTH\(\1\)\)/igsm;
	if ($model_update -> {characterset} =~ /UTF/i) {
		$items[$i] =~ s/\bHEX(\(.*?\))/RAWTONHEX\1/igsm;
	}
	else {
		$items[$i] =~ s/\bHEX(\(.*?\))/RAWTOHEX\1/igsm;	
	}
	####### DATE_FORMAT
	if ($items[$i] =~ m/\bDATE_FORMAT\((.+?),(.+?)\)/igsm) {
		my $expression = $1;
		my $format = $2;
		$format =~ s/%Y/YYYY/igsm;
		$format =~ s/%y/YY/igsm;
		$format =~ s/%d/DD/igsm;
		$format =~ s/%m/MM/igsm;
		$format =~ s/%H/HH24/igsm;
		$format =~ s/%h/HH12/igsm;
		$format =~ s/%i/MI/igsm;
		$format =~ s/%s/SS/igsm;
		$items[$i] = "TO_CHAR ($expression,$format)";
	}
	######## SUBDATE() и DATE_SUB()
	if ($items[$i] =~ m/(\bSUBDATE|\bDATE_SUB)\((.+?),\s*\w*?\s*(\d+)\s*(\w+)\)/igsm) {
		my $temp = $4;
		if ($temp =~ m/DAY|HOUR|MINUTE|SECOND/igsm) {
			$items[$i] =~ s/(\bSUBDATE|\bDATE_SUB)\((.+?),\s*\w*?\s*(\d+)\s*(\w+)\)/TO_DATE(\2)-NUMTODSINTERVAL\(\3,'$4')/igsm; 	
		}
		if ($temp =~ m/YEAR|MONTH/igsm)  {
			$items[$i] =~ s/(\bSUBDATE|\bDATE_SUB)\((.+?),\s*\w*?\s*(\d+)\s*(\w+)\)/TO_DATE(\2)-NUMTOYMINTERVAL\(\3,'$4')/igsm; 		
		}
	}
	######## ADDDATE() и DATE_ADD()
	if ($items[$i] =~ m/(\bADDDATE|\bDATE_ADD)\((.+?),\s*\w*?\s*(\d+)\s*(\w+)\)/igsm) {
		my $temp = $4;
		if ($temp =~ m/DAY|HOUR|MINUTE|SECOND/igsm) {
			$items[$i] =~ s/(\bADDDATE|\bDATE_ADD)\((.+?),\s*\w*?\s*(\d+)\s*(\w+)\)/TO_DATE(\2)+NUMTODSINTERVAL\(\3,'$4')/igsm; 	
		}
		if ($temp =~ m/YEAR|MONTH/igsm)  {
			$items[$i] =~ s/(\bADDDATE|\bDATE_ADD)\((.+?),\s*\w*?\s*(\d+)\s*(\w+)\)/TO_DATE(\2)+NUMTOYMINTERVAL\(\3,'$4')/igsm; 		
		}
	}
	######## NOW()
	$items[$i] =~ s/\bNOW\(.*?\)/LOCALTIMESTAMP/igsm; 	
	######## CURDATE()
	$items[$i] =~ s/\bCURDATE\(.*?\)/SYSDATE/igsm; 		
	######## YEAR, MONTH, DAY
	$items[$i] =~ s/(\bYEAR\b|\bMONTH\b|\bDAY\b)\((.*?)\)/EXTRACT\(\1 FROM \2\)/igsm; 		
	######## TO_DAYS()
	$items[$i] =~ s/\bTO_DAYS\((.+?)\)/EXTRACT\(DAY FROM TO_TIMESTAMP\(\1,'YYYY-MM-DD HH24:MI:SS'\) - TO_TIMESTAMP\('0001-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS'\) + NUMTODSINTERVAL\( 364 , 'DAY' \)\)/igsm; 			
	######## DAYOFYEAR()
	$items[$i] =~ s/\bDAYOFYEAR\((.+?)\)/TO_CHAR(TO_DATE\(\1\),'DDD')/igsm;
	######## LOCATE(), POSITION()  
	if ($items[$i] =~ m/(\bLOCATE\((.+?),(.+?)\)|\bPOSITION\((.+?)\s+IN\s+(.+?)\))/igsm) {
		$items[$i] =~ s/'\0'/'00'/;		
		$items[$i] =~ s/\bLOCATE\((.+?),(.+?)\)/INSTR\(\2,\1\)/igsm;
		$items[$i] =~ s/\bPOSITION\((.+?)\s+IN\s+(.+?)\)/INSTR\(\2,\1\)/igsm;
	}
	######## IF() 
	$items[$i] =~ s/\bIF\((.+?),(.+?),(.+?)\)/(CASE WHEN \1 THEN \2 ELSE \3 END)/igms;
	##############################################################################
	# Заполняем шаблон верхнего уровня ранее запомненными и измененными items 
	# в помеченных местах
	##############################################################################
	$sql =~ s/NJNJNjgyyuypoht$i/$items[$i]/gsm;
	# Просматриваем поля и заменяем если в них есть текущий шаблон (для дальнейшей замены GROUP BY 1,2,3 ...)
	if ($need_group_by) {
		for (my $x = 0; $x <= $#group_by_fields_ref; $x++) {
			for (my $y = 0; $y <= $#{@{$group_by_fields_ref[$x]}}; $y++) {
				$group_by_fields_ref [$x] -> [$y] =~ s/NJNJNjgyyuypoht$i/$items[$i]/gsm;
			}
		}  
	}
}

################ Меняем GROUP BY 1,2,3 ...

if ($need_group_by) {
	my (@result,$group_by);

	for (my $x = 0; $x <= $#group_by_values_ref; $x++) {
		for (my $y = 0; $y <= $#{@{group_by_values_ref[$x]}}; $y++) {
			my $index = $group_by_values_ref [$x] -> [$y];
			# Если в GROUP BY стояла цифра - заменяем на значение
			if ($index =~ m/\b\d+\b/igsm) {
				push @result,$group_by_fields_ref[$x]->[$index-1];				
			}
			# иначе - то что стояло
			else {
				push @result,$group_by_values_ref[$x]->[$y];			
			}

		}
		# Формируем GROUP BY для каждого SELECT
		$group_by = join(',',@result);
		$sql =~ s/VJkjn;lohggff/\n GROUP BY $group_by /sm; 
		@result=();
	}
}


############### Делаем регистронезависимый LIKE 
$sql =~ s/([\w\'\?\.\%\_]*?\s+)(NOT\s+)*LIKE(\s+[\w\'\?\.\%\_]*?[\s\)]+)/ UPPER\(\1\) \2 LIKE UPPER\(\3\) /igsm;
############### Удаляем псевдофункции
$sql =~ s/VGtygvVGVYbbhyh//gsm;
# Восстанавливаем то что было внутри кавычек НЕ в аргументах функций
$sql =~ s/POJJNBhvtgfckjh(\d+)/$in_quotes[$1]/gsm;			
# Восстанавливаем скобки и запятые в кавычках
$sql =~ s/JKghsdgfweftyfd/\(/gsm;
$sql =~ s/RTYfghhfFGhhjJg/\)/gsm;
$sql =~ s/DFgpoUUYTJjkgJj/\,/gsm;
# добавляем FROM DUAL если в SELECT не задано FROM
if ($need_from_dual) {
	$sql =~ s/\n//igsm;
	$sql .= " FROM DUAL\n";	
}

################# Эти замены необходимо делать только после всех преобразований
# , потому что сборка идет с верхнего уровня и мы заранее не знаем что будет стоять
# в параметрах этих функций после всех замен
#################
# Делаем из (TO_TIMESTAMP(CURRENT_TIMESTAMP)) просто CURRENT_TIMESTAMP
$sql =~ s/TO_TIMESTAMP\(CURRENT_TIMESTAMP,'YYYY-MM-DD HH24:MI:SS'\)/CURRENT_TIMESTAMP/igsm;
#################
# В случае если у нас данные хранятся в Unicode и есть явно заданные литералы
# внутри CASE ... END - передаем литералы  в UNISTR()
################################################################################### 
if ($model_update -> {characterset} =~ /UTF/i) {

	my $new_sql;
	while ($sql =~ m/\bCASE\s+(.*?WHEN\s+.*?THEN\s+.*?ELSE\s+.*?END)/ism) {
		$new_sql .= $`;
		$sql = $';
		my $temp = $1;
		$temp =~ s/('.*?')/UNISTR\(\1\)/igsm;
		$new_sql .= " CASE $temp ";
	}
	$new_sql .= $sql;
	$sql = $new_sql;
}



#warn "ORACLE OUT: <$sql>\n";

$mysql_to_oracle_cache -> {$src_sql} = $sql if ($src_sql !~ /\bIF\((.+?),(.+?),(.+?)\)/igsm);

return $sql;	

}

################################################################################

sub sql_select_ids {

	my ($sql, @params) = @_;
	
	my $ids = '-1';
	
	my $st = sql_execute ($sql, @params);
		
	while ((my $id) = $st -> fetchrow_array) {
		$id > 0 or next;
		$ids .= ',';
		$ids .= $id;
	}
	
	$st -> finish ();
	
	wantarray or return $ids;

	foreach my $parameter (@params) {
		$sql =~ s/\?/'$parameter'/ism;
	}

	return ($ids, $sql);

}

1;
