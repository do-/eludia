no strict;
no warnings;

#use DBD::Oracle qw(:ora_types);

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

	my $ids = sql_select_ids ("SELECT id FROM $conf->{systables}->{sessions} WHERE ts < sysdate - ? / 1440", $timeout);
	
	sql_do ("DELETE FROM $conf->{systables}->{sessions} WHERE id IN ($ids)");

	$ids = sql_select_ids ("SELECT id FROM $conf->{systables}->{sessions}");

	sql_do ("DELETE FROM $conf->{systables}->{__access_log} WHERE id_session NOT IN ($ids)");
	
	sql_do ("UPDATE $conf->{systables}->{sessions} SET ts = sysdate WHERE id = ? ", $_REQUEST {sid});
	

}

################################################################################

sub sql_prepare {

	my ($sql) = @_;

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

	my $st;

	$sql = mysql_to_oracle($sql) if($conf -> {core_auto_oracle});

	eval {$st = $db  -> prepare ($sql, {
		ora_auto_lob => ($sql !~ /for\s+update\s*/ism),
	})};
	
	if ($@) {
		my $msg = "sql_prepare: $@ (SQL = $sql)\n";
		print STDERR $msg;
		die $msg;
	}
	
	
	return $st;

}

################################################################################

sub sql_do {

	my ($sql, @params) = @_;

	my $st = sql_prepare ($sql);

#	eval {
		$st -> execute (@params);
		$st -> finish;	
#	};

#	if ($@ && $@ =~ /ORA\-02292/) {	
#		$_REQUEST {error} = 'Нарушено ограничение целостности. Операция недопустима.';	
#	} 
#	elsif ($@) {
#		die $@;
#	}
	
}

################################################################################

sub sql_execute_procedure {

	my ($sql, @params) = @_;
	
	$sql .= ';' unless $sql =~ /;[\n\r\s]*$/;
	
	my $st = sql_prepare ($sql);

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
		$sql =~ s{LIMIT.*}{}ism;
		my $result = sql_select_all ($sql, @params, $options);
		my $cnt = ref $result eq ARRAY ? 0 + @$result : -1;
		return ($result, $cnt);
	}

	my $st = sql_prepare ($sql);


	$st -> execute (@params);
	my $cnt = 0;	
	my @result = ();
	
	while (my $i = $st -> fetchrow_hashref ()) {
	
		$cnt++;
		
		$cnt > $start or next;
		$cnt <= $start + $portion or last;
			
		push @result, lc_hashref ($i);
	
	}
	
	$st -> finish;



	$sql =~ s{ORDER BY.*}{}ism;


	my $cnt = 0;

	if ($sql =~ /(\s+GROUP\s+BY|\s+UNION\s+)/i) {
		my $temp = sql_select_all($sql, @params);
		$cnt = (@$temp + 0);
	}
	else {
		$sql =~ s/SELECT.*FROM/SELECT COUNT(*) FROM/igsm;
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
	
	if ($options -> {fake}) {
	
		my $where = 'WHERE ';
		my $fake  = $_REQUEST {fake} || 0;
		my $condition = $fake =~ /\,/ ? "IN ($fake)" : '=' . $fake;
	
		foreach my $table (split /\,/, $options -> {fake}) {
			$where .= "$table.fake $condition AND ";
		}	
		
		$sql =~ s{where}{$where}i;
			
	}


	if ($sql =~ s{LIMIT\s+(\d+)\s*\,\s*(\d+).*}{}ism) {

		my @temp_result = ();
		my ($start, $portion) = ($1, $2);

		($start, $portion) = (0, $start) unless ($portion);
		my $st = sql_prepare ($sql);
		$st -> execute (@params);
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
		my $st = sql_prepare ($sql);

		$st -> execute (@params);

		return $st if $options -> {no_buffering};

		$result = $st -> fetchall_arrayref ({});	

		$st -> finish;
        }
	
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

	$sql = mysql_to_oracle($sql) if($conf -> {core_auto_oracle});

	my $st = $db -> prepare ($sql);
	$st -> execute (@params);

	while (my $r = $st -> fetchrow_hashref) {
		lc_hashref ($r);		                       	
		$result -> {$r -> {id}} = $r;
	}
	
	$st -> finish;

	return $result;

}


################################################################################

sub sql_select_col {

	my ($sql, @params) = @_;

	my @result = ();

	if ($sql =~ m/\bLIMIT\s+\d+\s*$/igsm) {
		$sql =~ s/\bLIMIT\s+(\d+)\s*$/LIMIT 0,$1/igsm;
	}

	if ($sql =~ s{LIMIT\s+(\d+)\s*\,\s*(\d+).*}{}ism) {
		my ($start, $portion) = ($1, $2);

		($start, $portion) = (0, $start) unless ($portion);
	
		my $st = sql_prepare ($sql);
		$st -> execute (@params);
		my $cnt = 0;	
 	
		while (my @r = $st -> fetchrow_array ()) {
	
			$cnt++;
		
			$cnt > $start or next;
			$cnt <= $start + $portion or last;
			
			push @result, @r;
	
		}
	
		$st -> finish;

	} else {

		my $st = sql_prepare ($sql);
		$st -> execute (@params);
		while (my @r = $st -> fetchrow_array ()) {
			push @result, @r;
		}
		$st -> finish;
	}
	
	return @result;

}

################################################################################

sub lc_hashref {

	my ($hr) = @_;
	
	return undef unless (defined $hr);	

	if ($conf -> {core_auto_oracle}) {	
		foreach my $key (keys %$hr) {
		        my $old_key = $key;
			$key =~ s/RewbfhHHkgkglld/user/igsm;
			$key =~ s/NbhcQQehgdfjfxf/level/igsm;
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
	
	my $st = sql_prepare ($sql_or_table_name);
	$st -> execute (@params);
	my $result = $st -> fetchrow_hashref ();
	$st -> finish;		
	
	return lc_hashref ($result);

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

	my @result;

	if ($sql =~ m/\bLIMIT\s+\d+\s*$/igsm) {
		$sql =~ s/\bLIMIT\s+(\d+)\s*$/LIMIT 0,$1/igsm;
	}

	if ($sql =~ s{LIMIT\s+(\d+)\s*\,\s*(\d+).*}{}ism) {

		my ($start, $portion) = ($1, $2);

		($start, $portion) = (0, $start) unless ($portion);
	
		my $st = sql_prepare ($sql);
		$st -> execute (@params);
		my $cnt = 0;	
	
		while (my @r = $st -> fetchrow_array ()) {
	
			$cnt++;
		
			$cnt > $start or next;
			$cnt <= $start + $portion or last;
			
			push @result, @r;
			last;
	
		}
	
		$st -> finish;

	} else {

		my $st = sql_prepare ($sql);

		$st -> execute (@params);
		@result = $st -> fetchrow_array ();
		$st -> finish;
	}
	
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

	my $id_value;

	foreach my $field (keys %$pairs) { 
		my $comma = @params ? ', ' : '';	
		unless (exists($DB_MODEL->{tables}->{$table_name}->{columns}->{$field}->{NULLABLE})) {
			$fields .= "$comma $field";
			$args   .= "$comma ?";
			if (exists($DB_MODEL->{tables}->{$table_name}->{columns}->{$field}->{COLUMN_DEF}) && !($pairs -> {$field})) {
				push @params, $DB_MODEL->{tables}->{$table_name}->{columns}->{$field}->{COLUMN_DEF};
			}
			else {
				push @params, $pairs -> {$field};	
			}
			$id_value = $pairs -> {$field} if (uc $field eq 'ID');
 		}
	}

	if ($conf -> {core_voc_replacement_use}) {	
		my $seq_name ='SEQ_';
		my $curval;

		if ($id_value) {
			$seq_name .= sql_select_scalar("SELECT id FROM $conf->{systables}->{__voc_replacements} WHERE table_name='$table_name' and object_type=2");
			$curval = sql_select_scalar("SELECT LAST_NUMBER FROM user_sequences WHERE SEQUENCE_NAME='$seq_name'");
			my $step = $id_value - $curval;
	 		if ($step > 1) {
				sql_do("ALTER SEQUENCE $seq_name INCREMENT BY $step");
			        sql_select_scalar("SELECT $seq_name.nextval FROM DUAL");
				sql_do("ALTER SEQUENCE $seq_name INCREMENT BY 1");
	 		}

		}
	}

	my $st = sql_prepare ("INSERT INTO $table_name ($fields) VALUES ($args) RETURNING id INTO ?");

	my $i = 1; 
	$st -> bind_param ($i++, $_)
		foreach (@params);
		
	my $id;		
	$st -> bind_param_inout ($i, \$id, 20);
	
	$st -> execute;
	$st -> finish;	

	return $id;
		
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

sub keep_alive {
	my $sid = shift;
	sql_do ("UPDATE $conf->{systables}->{sessions} SET ts = sysdate WHERE id = ? ", $sid);
}

################################################################################

sub sql_select_loop {

	my ($sql, $coderef, @params) = @_;
	$sql =~ s{^\s+}{};

	$sql = mysql_to_oracle($sql) if($conf -> {core_auto_oracle});

	my $st = $db -> prepare ($sql);
	$st -> execute (@params);
	
	our $i;
	while ($i = $st -> fetchrow_hashref) {
		lc_hashref ($i)
			if (exists $$_PACKAGE {'lc_hashref'});
		&$coderef ();
	}
	
	$st -> finish ();

}

#################################################################################

sub mysql_to_oracle {

my ($sql) = @_;

my (@items,@group_by_values_ref,@group_by_fields_ref);
my ($pattern,$need_group_by);
my $sc_in_quotes=0;

#warn "~~~ MYSQL TO ORACLE IN: <$sql>\n";

############### Заменяем неразрешенные в запросах слова на ключи (обратно восстанавливаем в lc_hashref())
$sql =~ s/([^\W]\s*\b)user\b(?!\.)/\1RewbfhHHkgkglld/igsm;
$sql =~ s/([^\W]\s*\b)level\b(?!\.)/\1NbhcQQehgdfjfxf/igsm;

############### Делаем из выражений в скобках псевдофункции чтобы шаблон свернулся
while ($sql =~ s/([^\w\s]+?\s*)(\()/\1VGtygvVGVYbbhyh\2/ism) {};

############### Вырезаем и запоминаем все что внутри кавычек, помечая эти места.
while ($sql =~ /(''|'.*?[^\\]')/ism)
{	
	my $temp = $1;
	# Скобки и запятые внутри кавычек прячем чтобы не мешались при анализе и замене функций 
	$temp =~ s/\(/JKghsdgfweftyfd/igsm;
	$temp =~ s/\)/RTYfghhfFGhhjJg/igsm;
	$temp =~ s/\,/DFgpoUUYTJjkgJj/igsm;
	$in_quotes[++$sc_in_quotes]=$temp;
	$sql =~ s/''|'.*?[^\\]'/POJJNBhvtgfckjh$sc_in_quotes/ism;
}
############### Это убираем

$sql =~ s/\bBINARY\b//igsm; 
$sql =~ s/\bAS\b//igsm;
$sql =~ s/(.*?)#.*?\n/\1\n/igsm; 		 				# Убираем закомментированные строки
$sql =~ s/(\s+)STRAIGHT_JOIN(\s+)/\1\2/igsm;					
$sql =~ s/(\s+)FORCE\s+INDEX(\s+)\(.*?\)/\1\2/igsm;             		


############### Вырезаем функции начиная с самых вложенных и совсем не вложенных
# места помечаем ключем с номером, а сами функции с аргументами запоминаем в @items
# до тех пор пока всё не вырежем
while ($sql =~m/((\b\w+\s*\((?!.*\().*?)\))/igsm)
{	
	$items[++$sc]=$1;
	$sql =~s/((\b\w+\s*\((?!.*\().*?)\))/NJNJNjgyyuypoht$sc/igsm;
}

$pattern = $sql;
$need_group_by=1 if ( $sql =~ m/\s+GROUP\s+BY\s+/igsm);

if ($need_group_by) {

	# Запоминаем значения из GROUP BY до UNION или ORDER BY
	# Также формируем массив хранящий ссылки на массивы значений для каждого SELECT
	my $sc=0;
	while ($sql =~ s/\s+GROUP\s+BY\s+(.*?)(\s+UNION\s+|\s+ORDER\s+BY\s+|$)/VJkjn;lohggff\2/ism) {
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
	$items[$i] =~ s/\bIFNULL\s*(\(.*?\))/NVL\1/igsm;
	$items[$i] =~ s/\bFLOOR\s*(\(.*?\))/CEIL\1/igsm;
	$items[$i] =~ s/\bCONCAT\s*\((.*?)\)/join('||',split(',',$1))/iegsm;
	$items[$i] =~ s/\bLEFT\s*\((.+?),(.+?)\)/SUBSTR\(\1,1,\2\)/igsm;
	$items[$i] =~ s/\bRIGHT\s*\((.+?),(.+?)\)/SUBSTR\(\1,LENGTH\(\1\)-\(\2\)+1,LENGTH\(\1\)\)/igsm;
	####### DATE_FORMAT
	if ($items[$i] =~ m/\bDATE_FORMAT\s*\((.+?),(.+?)\)/igsm) {
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
	if ($items[$i] =~ m/(\bSUBDATE|\bDATE_SUB)\s*\((.+?),\s*\w*?\s*(\d+)\s*(\w+)\)/igsm) {
		my $temp = $4;
		if ($temp =~ m/DAY|HOUR|MINUTE|SECOND/igsm) {
			$items[$i] =~ s/(\bSUBDATE|\bDATE_SUB)\s*\((.+?),\s*\w*?\s*(\d+)\s*(\w+)\)/TO_DATE(\2)-NUMTODSINTERVAL\(\3,'$4')/igsm; 	
		}
		if ($temp =~ m/YEAR|MONTH/igsm)  {
			$items[$i] =~ s/(\bSUBDATE|\bDATE_SUB)\s*\((.+?),\s*\w*?\s*(\d+)\s*(\w+)\)/TO_DATE(\2)-NUMTOYMINTERVAL\(\3,'$4')/igsm; 		
		}
	}
	######## ADDDATE() и DATE_ADD()
	if ($items[$i] =~ m/(\bADDDATE|\bDATE_ADD)\s*\((.+?),\s*\w*?\s*(\d+)\s*(\w+)\)/igsm) {
		my $temp = $4;
		if ($temp =~ m/DAY|HOUR|MINUTE|SECOND/igsm) {
			$items[$i] =~ s/(\bADDDATE|\bDATE_ADD)\s*\((.+?),\s*\w*?\s*(\d+)\s*(\w+)\)/TO_DATE(\2)+NUMTODSINTERVAL\(\3,'$4')/igsm; 	
		}
		if ($temp =~ m/YEAR|MONTH/igsm)  {
			$items[$i] =~ s/(\bADDDATE|\bDATE_ADD)\s*\((.+?),\s*\w*?\s*(\d+)\s*(\w+)\)/TO_DATE(\2)+NUMTOYMINTERVAL\(\3,'$4')/igsm; 		
		}
	}
	######## NOW()
	$items[$i] =~ s/\bNOW\s*\(.*?\)/TO_CHAR(CURRENT_TIMESTAMP, 'YYYY-MM-DD HH24:MI:SS')/igsm; 	
	######## CURDATE()
	$items[$i] =~ s/\bCURDATE\s*\(.*?\)/SYSDATE/igsm; 		
	######## YEAR, MONTH, DAY
	$items[$i] =~ s/(\bYEAR\b|\bMONTH\b|\bDAY\b)\s*\((.*?)\)/EXTRACT\(\1 FROM \2\)/igsm; 		
	######## TO_DAYS()
	$items[$i] =~ s/\bTO_DAYS\s*\((.+?)\)/EXTRACT\(DAY FROM TO_TIMESTAMP\(\1,'YYYY-MM-DD HH24:MI:SS'\) - TO_TIMESTAMP\('0001-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS'\) + NUMTODSINTERVAL\( 364 , 'DAY' \)\)/igsm; 			
	######## DAYOFYEAR()
	$items[$i] =~ s/\bDAYOFYEAR\s*\((.+?)\)/TO_CHAR(TO_DATE\(\1\),'DDD')/igsm;
	######## LOCATE(), POSITION()  
	if ($items[$i] =~ m/(\bLOCATE\s*\((.+?),(.+?)\)|\bPOSITION\s*\((.+?)\s+IN\s+(.+?)\))/igsm) {
		$items[$i] =~ s/'\0'/'00'/;		
		$items[$i] =~ s/\bLOCATE\s*\((.+?),(.+?)\)/INSTR\(\2,\1\)/igsm;
		$items[$i] =~ s/\bPOSITION\s*\((.+?)\s+IN\s+(.+?)\)/INSTR\(\2,\1\)/igsm;
	}
	######## IF() 
	$items[$i] =~ s/\bIF\s*\((.+?),(.+?),(.+?)\)/(CASE WHEN \1 THEN \2 ELSE \3 END)/igms;
	##############################################################################
	# Заполняем шаблон верхнего уровня ранее запомненными и измененными items 
	# в помеченных местах
	##############################################################################
	$sql =~ s/NJNJNjgyyuypoht$i/$items[$i]/igsm;
	# Просматриваем поля и заменяем если в них есть текущий шаблон (для дальнейшей замены GROUP BY 1,2,3 ...)
	if ($need_group_by) {
		for (my $x = 0; $x <= $#group_by_fields_ref; $x++) {
			for (my $y = 0; $y <= $#{@{$group_by_fields_ref[$x]}}; $y++) {
				$group_by_fields_ref [$x] -> [$y] =~ s/NJNJNjgyyuypoht$i/$items[$i]/igsm;
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
			if ($index =~ m/\d+/igsm) {
				push @result,$group_by_fields_ref[$x]->[$index-1];				
			}
			# иначе - то что стояло
			else {
				push @result,$group_by_values_ref[$x]->[$y];			
			}

		}
		# Формируем GROUP BY для каждого SELECT
		$group_by = join(',',@result);
		$sql =~ s/VJkjn;lohggff/\n GROUP BY $group_by /ism; 
		@result=();
	}
}


############### Делаем регистронезависимый LIKE 
$sql =~ s/([\w\'\?\.\%\_]*?\s+)LIKE(\s+[\w\'\?\.\%\_]*?[\s\)]+)/ UPPER\(\1\) LIKE UPPER\(\2\) /igsm;
############### Удаляем псевдофункции
$sql =~ s/VGtygvVGVYbbhyh//igsm;
# Восстанавливаем то что было внутри кавычек НЕ в аргументах функций
$sql =~ s/POJJNBhvtgfckjh(\d+)/$in_quotes[$1]/igsm;			
# Восстанавливаем скобки и запятые в кавычках
$sql =~ s/JKghsdgfweftyfd/\(/igsm;
$sql =~ s/RTYfghhfFGhhjJg/\)/igsm;
$sql =~ s/DFgpoUUYTJjkgJj/\,/igsm;
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

#warn "~~~ MYSQL TO ORACLE OUT: <$sql>\n";

return $sql;	

}

################################################################################

sub sql_select_ids {
	my ($sql, @params) = @_;

	my @ids = grep {$_ > 0} sql_select_col ($sql, @params);
	push @ids, -1;

	foreach my $parameter (@params) {
		$sql =~ s/\?/'$parameter'/ism;
	}

	return wantarray ? (join(',', @ids), $sql) : join(',', @ids);
}

1;