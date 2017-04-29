no strict;
no warnings;

################################################################################

sub sql_version {

	$db -> {pg_enable_utf8} = 1;
	$db -> {pg_errorlevel}  = 2;

	my $version = $SQL_VERSION;
	
	$version -> {strings} = [ sql_select_col ('SELECT version()') ];
	
	$version -> {string} = $version -> {strings} -> [0];
	
	($version -> {number}) = $version -> {string} =~ /([\d\.]+)/;
	
	my @t = split /\./, $version -> {number};
	
	$version -> {number_tokens} = \@t;
	
	$version -> {n} = 0 + (join '.', grep {$_} @t [0 .. 1]);
	
	$version -> {features} -> {'idx.partial'} = ($version -> {n} > 7.1);
	
	return $version;
	
}

################################################################################

sub sql_execute {
	
	my ($sql, @params) = @_;

	__profile_in ('sql.prepare_execute');
	
	my $st = sql_prepare ($sql);

	my $affected = $st -> execute (@params);

	__profile_out ('sql.prepare_execute', {label => $st -> {Statement} . ' ' . (join ', ', map {$db -> quote ($_)} @params)});

	return wantarray ? ($st, $affected) : $st;

}

################################################################################

sub sql_prepare {

	my ($sql) = @_;
	
	my $st;
	
	eval {$st = $db  -> prepare ($sql, {})};
	
	$@ or return $st;

	warn "$sql\n";
	
	die $@;

}

################################################################################

sub sql_do {

#	darn \@_ if $preconf -> {core_debug_sql_do};

	my ($sql, @params) = @_;
	
	my $st;
	
	eval { ($st, $affected) = sql_execute ($sql, @params) };
	
	my $err = $@;
	
	eval { $st -> finish } if $st;

	$err or return;
	
	$err =~ /23505:/ and die "UNIQUE VIOLATION\n$err";
	
	die $err;
	
}

################################################################################

sub sql_select_all_cnt {

	my ($sql, @params) = @_;

	$sql =~ s{LIMIT\s+(\d+)\s*\,\s*(\d+).*}{LIMIT $2 OFFSET $1}ism;

	my $options = {};

	if (@params > 0 and ref ($params [-1]) eq HASH) {
		$options = pop @params;
	}
	
	$sql = sql_adjust_fake_filter ($sql, $options);
	
	if ($_REQUEST {xls} && $conf -> {core_unlimit_xls} && !$_REQUEST {__limit_xls}) {
		$sql =~ s{\bLIMIT\b.*}{}ism;
		my $result = sql_select_all ($sql, @params, $options);
		my $cnt = ref $result eq ARRAY ? 0 + @$result : -1;
		return ($result, $cnt);
	}

	my $time = time;	

	my $st = sql_execute ($sql, @params);
	
	my @result = ();

	__profile_in ('sql.fetch');
	
	while (my $i = $st -> fetchrow_hashref ()) {			
		push @result, $i;	
	}
	
	__profile_out ('sql.fetch', {label => $st -> rows});

	$st -> finish;

	$sql =~ s{ORDER BY.*}{}ism;
	$sql =~ s/SELECT.*?[\n\s]+FROM[\n\s]+/SELECT COUNT(*) FROM /ism;
	my $cnt = sql_select_scalar ($sql, @params);
			
	return (\@result, $cnt);

}

################################################################################

sub sql_select_all {

	my ($sql, @params) = @_;

	$sql =~ s{LIMIT\s+(\d+)\s*\,\s*(\d+).*}{LIMIT $2 OFFSET $1}ism;

	my $options = {};

	if (@params > 0 and ref ($params [-1]) eq HASH) {
		$options = pop @params;
	}
	
	$sql = sql_adjust_fake_filter ($sql, $options);

	my $time = time;	
	
	my $st = sql_execute ($sql, @params);

	return $st if $options -> {no_buffering};

	my @result = ();
	
	__profile_in ('sql.fetch');

	while (my $i = $st -> fetchrow_hashref ()) {			
		push @result, $i;	
	}

	__profile_out ('sql.fetch', {label => $st -> rows});

	$st -> finish;
	
	$_REQUEST {__benchmarks_selected} += @result;
	
	return \@result;

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

	__profile_in ('sql.fetch');

	while (my $r = $st -> fetchrow_hashref) {
		$result -> {$r -> {id}} = $r;
	}

	__profile_out ('sql.fetch', {label => $st -> rows});
	
	$st -> finish;

	return $result;

}

################################################################################

sub sql_select_col {

	my ($sql, @params) = @_;

	my @result = ();

	$sql =~ s{LIMIT\s+(\d+)\s*\,\s*(\d+).*}{LIMIT $2 OFFSET $1}ism;

	my $time = time;	

	my $st = sql_execute ($sql, @params);

	__profile_in ('sql.fetch');

	while (my @r = $st -> fetchrow_array ()) {
		push @result, @r;
	}

	__profile_out ('sql.fetch', {label => $st -> rows});

	$st -> finish;
	
	return @result;

}

################################################################################

sub sql_select_hash {

	my ($sql_or_table_name, @params) = @_;

	$sql =~ s{LIMIT\s+(\d+)\s*\,\s*(\d+).*}{LIMIT $2 OFFSET $1}ism;
	
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

	my $time = time;	

	my $st = sql_execute ($sql_or_table_name, @params);

	__profile_in ('sql.fetch');

	my $result = $st -> fetchrow_hashref ();

	__profile_out ('sql.fetch', {label => $st -> rows});

	$st -> finish;		
	
	return $result;

}

################################################################################

sub sql_select_array {

	my ($sql, @params) = @_;

	$sql =~ s{LIMIT\s+(\d+)\s*\,\s*(\d+).*}{LIMIT $2 OFFSET $1}ism;

	my $time = time;	

	my $st = sql_execute ($sql, @params);

	__profile_in ('sql.fetch');

	my @result = $st -> fetchrow_array ();

	__profile_out ('sql.fetch', {label => $st -> rows});

	$st -> finish;
	
	return wantarray ? @result : $result [0];

}

################################################################################

sub sql_select_scalar {

	my ($sql, @params) = @_;

	my @result;

	$sql =~ s{LIMIT\s+(\d+)\s*\,\s*(\d+).*}{LIMIT $2 OFFSET $1}ism;

	my $time = time;	

	my $st = sql_execute ($sql, @params);

	__profile_in ('sql.fetch');

	@result = $st -> fetchrow_array ();

	__profile_out ('sql.fetch', {label => $st -> rows});

	$st -> finish;
	
	return $result [0];

}

################################################################################
	
sub sql_select_path {
	
	my ($table_name, $id, $options) = @_;
	
	$id or return [];
	
	my $columns = $DB_MODEL -> {tables} -> {$table_name} -> {columns};
	
	$options -> {name}     ||= $columns -> {name} ? 'name' : 'label';
	$options -> {type}     ||= $table_name;
	$options -> {id_param} ||= 'id';

	my $parent = $id;

	my @path = ();
	
	my $st = $db -> prepare ("SELECT id, parent, $$options{name}, $$options{name} as name, '$$options{type}' as type, '$$options{id_param}' as id_param FROM $table_name WHERE id = ?");

	__profile_in ('sql.fetch');

	while ($parent) {	
		$st -> execute ($parent);
		my ($r) = $st -> fetchrow_hashref ();
		$st -> finish ();
		$r -> {cgi_tail} = $options -> {cgi_tail},
		unshift @path, $r;		
		$parent = $r -> {parent};	
	}
	
	__profile_out ('sql.fetch', {label => 0 + @path});

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

sub sql_do_insert {

	my ($table, $data) = @_;
		
	exists $data -> {fake} or $data -> {fake} = $_REQUEST {sid};

	my ($fields, $args, @params) = ('', '');

	while (my ($k, $v) = each %$data) {

		defined $v or next;
		
		if (@params) {
			$fields .= ', ';
			$args   .= ', ';
		}

		$fields .= $k;
		$args   .= '?';
		push @params, $v;
 
	}
	
	my $sql = "INSERT INTO $table ($fields) VALUES ($args)";
	
	if ($data -> {id}) {
	
		sql_do ($sql, @params);	
		
		sql_check_seq ($table);

	}
	else {
	
		$data -> {id} = sql_select_scalar ("$sql RETURNING id", @params);

	}

	return $data -> {id};

}

################################################################################

sub sql_check_seq {

	my ($table) = @_;

	sql_select_scalar ("SELECT setval('${table}_id_seq', (SELECT MAX(id) FROM $table))");

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
	
	my $item = sql_select_hash ("SELECT * FROM $$options{table} WHERE id = ?", $_REQUEST {id});
	$options -> {size} = $item -> {$options -> {size_column}};
	$options -> {path} = $item -> {$options -> {path_column}};
	$options -> {type} = $item -> {$options -> {type_column}};
	$options -> {file_name} = $item -> {$options -> {file_name_column}};	

	if ($options -> {body_column}) {
	
		my $auto_commit = $db -> {AutoCommit};
		$db -> {AutoCommit} = 0;
				
		$oid = $item -> {$options -> {body_column}};

		my $ofd = $db -> pg_lo_open ($oid, $db -> {pg_INV_READ});
		defined $ofd or die "Can't get file descritor for OID $oid";

		my $chunk_size = 1034;
		my $buffer;
		
		download_file_header (@_);
		while (my $read = $db -> pg_lo_read ($ofd, $buffer, $chunk_size)) {
			$r -> print (substr ($buffer, 0, $read));
		}

		$db -> pg_lo_close ($ofd) or die "Cannot close OFD $ofd (OID $oid)";
		
		$db -> {AutoCommit} = $auto_commit;

	}
	else {
		download_file ($options);
	}

}

################################################################################

sub sql_store_file {

	my ($options) = @_;

	open F, $options -> {real_path} or die "Can't open $options->{real_path}: $!\n";
	binmode F;
	
	$db -> {AutoCommit} = 0;

	my $st = $db -> prepare ("SELECT $options->{body_column} FROM $options->{table} WHERE id = ?");

	$st -> execute ($options -> {id});
	(my $oid) = $st -> fetchrow_array ();
	$st -> finish ();

	if ($oid) {
		$db -> pg_lo_unlink ($oid) or die "Cannot unlink OID $oid";
	}
	
	$oid = $db -> pg_lo_creat ($db -> {pg_INV_WRITE}) or die "Cannot create an OID to store a LOB";		
	
	$options -> {chunk_size} ||= 4096; 
	my $buffer = '';		
		
	my $ofd = $db -> pg_lo_open ($oid, $db -> {pg_INV_WRITE});	
	defined $ofd or die "Can't get file descritor for OID $oid";
		
	while (my $read = read (F, $buffer, $options -> {chunk_size})) {
		my $written = $db -> pg_lo_write ($ofd, $buffer, $read) or die "Cannot wite to OFD $ofd (OID $oid)";
	}

	close F;
	
	$db -> pg_lo_close ($ofd) or die "Cannot close OFD $ofd (OID $oid)";

	sql_do (
		"UPDATE $$options{table} SET $options->{body_column} = ?, $options->{size_column} = ?, $options->{type_column} = ?, $options->{file_name_column} = ? WHERE id = ?",
		$oid,
		-s $options -> {real_path},
		$options -> {type},
		$options -> {file_name},
		$options -> {id},
	);

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
	sql_do ("UPDATE $conf->{systables}->{sessions} SET ts = now() WHERE id = ? ", $sid);
}

################################################################################

sub sql_select_loop {

	my ($sql, $coderef, @params) = @_;
	
	my $time = time;

	my $st = sql_execute ($sql, @params);
	
	our $i;
	
	__profile_in ('sql.fetch');

	while ($i = $st -> fetchrow_hashref) {
		&$coderef ();
	}
	
	__profile_out ('sql.fetch', {label => $st -> rows});

	$st -> finish ();

}

################################################################################

sub sql_lock {

	sql_do ("LOCK TABLE $_[0] IN ROW EXCLUSIVE MODE");

}

################################################################################

sub sql_unlock {

	# do nothing, wait for commit/rollback

}

################################################################################

sub _sql_ok_subselects { 1 }


################################################################################

sub sql_do_upsert {

	my ($table, $data) = @_;
	
	exists $data -> {id} and die "sql_do_upsert called with id defined\n";

	exists $data -> {fake} or $data -> {fake} = $_REQUEST {sid};
	
	my $def = $DB_MODEL -> {tables} -> {$table} or die "Can't find $table definition in model\n";

	my $keys = $def -> {keys} or die "$table definition have no keys at all\n";

	my @uniq = grep {/\!\s*$/} values %$keys;

	@uniq > 0 or die "$table definition have no partially unique keys\n";

	@uniq < 2 or die "$table definition have more than one partially unique key\n";
	
	my ($uniq) = @uniq;
	
	$uniq =~ s{\!\s*$}{};
	
	my %uniq_fields = map {$_ => 1} split /\W/, $uniq [0];

	my ($fields, $args, $set, @params) = ('', '', '');

	while (my ($k, $v) = each %$data) {

		defined $v or next;
		
		if (@params) {
			$fields .= ', ';
			$args   .= ', ';
		}

		$fields .= $k;
		$args   .= '?';
		push @params, $v;
		
		unless ($uniq_fields {$k}) {

			$set .= ', ' if length $set;

			$set .= "$k = EXCLUDED.$k";

		}

	}
	
	my $sql = "INSERT INTO $table ($fields) VALUES ($args) ON CONFLICT ($uniq) WHERE fake = 0 DO UPDATE SET $set RETURNING id";
	
	$data -> {id} = sql_select_scalar ("$sql ", @params);

	return $data -> {id};

}

1;
