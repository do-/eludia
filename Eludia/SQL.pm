no warnings;

################################################################################

sub add_vocabularies {

	my ($item, @items) = @_;

	while (@items) {
	
		my $name = shift @items;
		
		my $options = {};
		
		if (@items > 0 && ref $items [0] eq HASH) {
		
			$options = shift @items;
		
		}
		
		$options -> {item} = $item;
		
		my $table_name = $options -> {name} || $name;
		
		$item -> {$name} = sql_select_vocabulary ($table_name, $options);
		
		if ($options -> {ids}) {
			
			ref $options -> {ids} eq HASH or $options -> {ids} = {table => $options -> {ids}};
			
			$options -> {ids} -> {from}  ||= 'id_' . en_unplural ($_REQUEST {type});
			$options -> {ids} -> {to}    ||= 'id_' . en_unplural ($table_name);
			
			$options -> {ids} -> {name}  ||= $options -> {ids} -> {to};
			
			$_REQUEST {"__checkboxes_$options->{ids}->{to}"} = $options -> {ids} -> {table};
		
			$item -> {$options -> {ids} -> {name}} = [sql_select_col ("SELECT $options->{ids}->{to} FROM $options->{ids}->{table} WHERE fake = 0 AND $options->{ids}->{from} = ?", $item -> {id})];
		
		}
		
	}
	
	return $item;

}

################################################################################

sub sql_export_json {

	my ($sql, $out, @params) = @_;
	
	my $cb = ref $out eq CODE ? $out : sub {print $out $_[0]};

	$_JSON or setup_json ();
	
	my $table;

	if ($sql =~ /^\s*DESC(?:RIBE)?\s+(\w+)\s*$/gism) {
	
		$table = $1;
		
		my $def = {
			name    => $table,
			columns => $model_update -> get_columns ($table),
		};
	
		my $keys = $model_update -> get_keys ($table, $conf -> {core_voc_replacement_use});
		
		foreach my $k (keys %$keys) {
			next if $k =~ /^pk/;
			$def -> {keys} -> {$k} = $keys -> {$k};
		}
				
		&$cb ($_JSON -> encode ($def) . "\n");
		
		return;
				
	}	
	
	if ($sql =~ /\bSELECT\s+(\w+)\.*/gism) {
		$table = $1;
	}
	elsif ($sql =~ /\bFROM\s+(\w+)/gism) {
		$table = $1;
	}
	
	$table or die "Invalid SQL (no table): $sql";
	
	sql_select_loop ($sql, sub {&$cb ($_JSON -> encode ([$table => $i]) . "\n")}, @params);

}

################################################################################

sub sql_import_json {

	my ($in, $cb) = @_;
	
	$_JSON or setup_json ();
	
	my $defs = {};
		
	while (my $line = <$in>) {
	
		my $r = $_JSON -> decode ($line);
		
		if (ref $r eq HASH) {
		
			$model_update -> assert (
				
				tables => {$r -> {name} => $r}, 
				
				default_columns => $DB_MODEL -> {default_columns},
				
				prefix => 'sql_import_json#',
				
			);
			
			next;
		
		}
	
		my %h = ();
		
		my $columns = ($defs -> {$r -> [0]} ||= $model_update -> get_columns ($r -> [0]));
				
		while (my ($k, $v) = each %{$r -> [1]}) {
		
			$columns -> {$k} or next;
		
			$k eq 'id' or $k = '-' . $k;
			
			foreach (split //, $v) {
			
				$h {$k} .= chr (ord ($_));

			}

		}
		
		sql_select_id ($r -> [0] => \%h, ['id']);
		
		&$cb ($r, \%h) if $cb;
	
	}

}

################################################################################

sub sql_weave_model {

	my ($db_model) = @_;

	my @tables = ();
	
	foreach my $table_name ($db -> tables) {	
		$table_name =~ s{.*?(\w+)\W*$}{$1}gsm;
		next if $table_name eq $conf -> {systables} -> {log};
		push @tables, lc $table_name;
	}
		
	foreach my $table_name (@tables) {
	
		my $def = $db_model -> {tables} -> {$table_name};

		$def -> {name} = $table_name;
			
		foreach my $column_name (keys %{$def -> {columns}}) {
			$def -> {columns} -> {$column_name} -> {name}       = $column_name;
			$def -> {columns} -> {$column_name} -> {table_name} = $table_name;
		}

		$db_model -> {aliases} -> {$table_name} = $def;
		
		foreach my $alias (@{$def -> {aliases}}) {
			$db_model -> {aliases} -> {$alias} = $def;
		}		
	
	}

	foreach my $table_name (@tables) {
	
		my $def = $db_model -> {aliases} -> {$table_name};

		foreach my $column_name (keys %{$def -> {columns}}) {

			my $column_def = $def -> {columns} -> {$column_name};
				
			$column_name =~ /^ids?_(.*)/ or next;
			
			my $target2 = $1;
			my $target1 = $target2;
		
			if ($target2 =~ /y$/) {
				$target1 =~ s{y$}{ies};
			}
			else {
				$target1 .= 's';
			}
			
			my $referenced_table_def = undef;
			
			if ($column_def -> {ref}) {
				$referenced_table_def = $db_model -> {aliases} -> {$column_def -> {ref}}
			}
			else {
				$referenced_table_def =
					$db_model -> {aliases} -> {$target1} ||
					$db_model -> {aliases} -> {$target2} ||
					$db_model -> {aliases} -> {'voc_' . $target1} ||
					$db_model -> {aliases} -> {'voc_' . $target2} ||
					undef;
			}

			$referenced_table_def or next;
			$referenced_table_def -> {references} ||= [];
			push @{$referenced_table_def -> {references}}, $column_def;
						
		}		
	
	}


}

################################################################################

sub check_systables {

	foreach (qw(
		__queries
		__defaults
		__voc_replacements	
		__access_log		
		__benchmarks		
		__request_benchmarks
		__last_update		
		__moved_links		
		__required_files	
		__screenshots		
		cache_html		
		log			
		roles			
		sessions		
		users			
	)) {
		$conf -> {systables} -> {$_} ||= $_;
	}

}

################################################################################

sub sql_assert_core_tables {
 
	$db or return;

	$model_update or die "\$db && !\$model_update ?!! Can't believe it.\n";

	return if $model_update -> {core_ok};

my $time = time;
	
	if ($conf -> {core_voc_replacement_use}) {
	
		$model_update -> assert (
		
			tables => {
			
				$conf -> {systables} -> {__voc_replacements} => {
					columns => {
						id          => {TYPE_NAME => 'bigint', _EXTRA => 'auto_increment', _PK => 1},
						table_name  => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
						object_name => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
						object_type => {TYPE_NAME => 'int', COLUMN_SIZE => 1},
					},
					keys => {
						ix => 'table_name',
						ix2 => 'object_name',
					},
				}
			},
						
			prefix => 'sql_assert_core_tables#',			

		);
	
	}

	my %defs = (
	
		$conf -> {systables} -> {__defaults} => {
		
			columns => {
				id          => {TYPE_NAME => 'int', _EXTRA => 'auto_increment', _PK => 1},
				fake        => {TYPE_NAME => 'bigint'},
				context     => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
				name        => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
				value       => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
			},
			
			keys => {
				context => 'context,name',
			},

		},

		$conf -> {systables} -> {__access_log} => {
		
			columns => {
				id         => {TYPE_NAME => 'bigint', _EXTRA => 'auto_increment', _PK => 1},
				id_session => {TYPE_NAME => 'bigint'},
				ts         => {TYPE_NAME => 'timestamp'},
				no         => {TYPE_NAME => 'int'},
				href       => {TYPE_NAME => 'text'},
			},
			
			keys => {
				ix => 'id_session,no',
				ix2 => 'id_session,href(255)',
			},

		},
		
		$conf -> {systables} -> {__moved_links} => {
		
			columns => {
				id          => {TYPE_NAME => 'bigint', _EXTRA => 'auto_increment', _PK => 1},
				table_name  => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
				column_name => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
				id_from     => {TYPE_NAME => 'int'},
				id_to       => {TYPE_NAME => 'int'},
			},
			
			keys => {
				id_to => 'id_to',
			},

		},
		
		$conf -> {systables} -> {__required_files} => {
		
			columns => {
				unix_ts   => {TYPE_NAME => 'bigint'},
				file_name => {TYPE_NAME => 'varchar', COLUMN_SIZE  => 255},
			},
			
			keys => {
				ix => 'file_name',
			},

		},

		$conf -> {systables} -> {__last_update} => {
		
			columns => {
				pid 	  => {TYPE_NAME => 'int'},
				unix_ts   => {TYPE_NAME => 'bigint'},
			},
			
		},

		$conf -> {systables} -> {sessions} => {
		
			columns => {

				id      => {TYPE_NAME  => 'bigint', _PK    => 1},
				id_user => {TYPE_NAME  => 'int'},
				id_role => {TYPE_NAME  => 'int'},
				ts      => {TYPE_NAME  => 'timestamp'},

				ip =>     {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
				ip_fw =>  {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
	
				peer_server => {TYPE_NAME    => 'varchar', COLUMN_SIZE  => 255},
				peer_id => {TYPE_NAME    => 'bigint'},
				
				tz_offset	=> {TYPE_NAME => 'tinyint', COLUMN_DEF => 0},
			}

		},

		$conf -> {systables} -> {roles} => {

			columns => {
				id   => {TYPE_NAME  => 'int', _EXTRA => 'auto_increment', _PK => 1},
				fake => {TYPE_NAME  => 'bigint', COLUMN_DEF => 0, NULLABLE => 0},
				name  => {TYPE_NAME    => 'varchar', COLUMN_SIZE  => 255},
				label => {TYPE_NAME    => 'varchar', COLUMN_SIZE  => 255},
			},

		},

		$conf -> {systables} -> {users} => {

			columns => {
				id   => {TYPE_NAME  => 'int', _EXTRA => 'auto_increment', _PK => 1},
				fake => {TYPE_NAME  => 'bigint', COLUMN_DEF => 0, NULLABLE => 0},
				name =>     {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
				login =>    {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
				label =>    {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
				password => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
				mail     => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
				id_role  =>  {TYPE_NAME => 'int'},

				peer_server => {TYPE_NAME    => 'varchar', COLUMN_SIZE  => 255},
				peer_id => {TYPE_NAME    => 'int'},
				
				subset => {TYPE_NAME    => 'varchar', COLUMN_SIZE  => 255},

			}

		},

		$conf -> {systables} -> {log} => {

			columns => {
				id   => {TYPE_NAME  => 'int', _EXTRA => 'auto_increment', _PK => 1},
				fake => {TYPE_NAME  => 'bigint', COLUMN_DEF => 0, NULLABLE => 0},
				id_user =>   {TYPE_NAME => 'int'},
				id_object => {TYPE_NAME => 'int'},
				ip =>     {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
				ip_fw =>  {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
				type =>   {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
				action => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
				error  => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
				params => {TYPE_NAME => 'longtext'},
				dt     => {TYPE_NAME => 'timestamp'},
				mac    => {TYPE_NAME  => 'varchar', COLUMN_SIZE => 17},
			}

		},	
	
	);
	
	
	$conf -> {core_store_table_order} and $defs {$conf -> {systables} -> {__queries}} = {

		columns => {
			id          => {TYPE_NAME => 'int', _EXTRA => 'auto_increment', _PK => 1},
			parent      => {TYPE_NAME => 'int'},
			fake        => {TYPE_NAME => 'bigint'},
			id_user     => {TYPE_NAME => 'int', COLUMN_DEF => 0, NULLABLE => 0},
			type        => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
			dump        => {TYPE_NAME => 'longtext'},
			label       => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
			order_context     => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
		},

		keys => {
			ix => 'id_user,type,label',
		},

	};
		
	$conf -> {core_cache_html} and $defs {$conf -> {systables} -> {cache_html}} = {

		columns => {
			uri     => {TYPE_NAME  => 'varchar', COLUMN_SIZE  => 255, _PK    => 1},
			ts      => {TYPE_NAME  => 'timestamp'},
		}

	};
	
	$preconf -> {core_debug_profiling} > 1 and $defs {$conf->{systables}->{__benchmarks}} = {

		columns => {
			id       => {TYPE_NAME  => 'int'    , _EXTRA => 'auto_increment', _PK => 1},
			fake     => {TYPE_NAME  => 'bigint' , COLUMN_DEF => 0, NULLABLE => 0},
			label    => {TYPE_NAME  => 'varchar', COLUMN_SIZE  => 255},
			cnt      => {TYPE_NAME  => 'bigint' , COLUMN_DEF => 0, NULLABLE => 0},
			ms       => {TYPE_NAME  => 'bigint' , COLUMN_DEF => 0, NULLABLE => 0},
			mean     => {TYPE_NAME  => 'bigint' , COLUMN_DEF => 0, NULLABLE => 0},
			selected => {TYPE_NAME  => 'bigint' , COLUMN_DEF => 0, NULLABLE => 0},
			mean_selected => {TYPE_NAME  => 'bigint' , COLUMN_DEF => 0, NULLABLE => 0},
		},
		
		keys => {
			label => 'label',
		},
		
	};

	$preconf -> {core_debug_profiling} > 2 and $defs {$conf->{systables}->{__request_benchmarks}} = {

		columns => {
			id	=> {TYPE_NAME  => 'int'    , _EXTRA => 'auto_increment', _PK => 1},
			fake	=> {TYPE_NAME  => 'bigint' , COLUMN_DEF => 0, NULLABLE => 0},
			id_user	=> {TYPE_NAME => 'int'},
			dt	=> {TYPE_NAME => 'timestamp'},
			params	=> {TYPE_NAME => 'longtext'},
			ip =>     {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
			ip_fw =>  {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
			type =>   {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
			mac    => {TYPE_NAME  => 'varchar', COLUMN_SIZE => 17},

			connection_id		=> {TYPE_NAME => 'int'},
			connection_no		=> {TYPE_NAME => 'int'},

			request_time		=> {TYPE_NAME => 'int'},
			application_time	=> {TYPE_NAME => 'int'},
			sql_time		=> {TYPE_NAME => 'int'},
			response_time		=> {TYPE_NAME => 'int'},
			
			bytes_sent		=> {TYPE_NAME => 'int'},
			is_gzipped		=> {TYPE_NAME => 'tinyint'}, 
		},

	};

	$conf -> {core_screenshot} and $defs {$conf -> {systables} -> {__screenshots}} = {

		columns => {
			id        => {TYPE_NAME  => 'int', _EXTRA => 'auto_increment', _PK => 1},
			subset    => {TYPE_NAME => 'varchar', COLUMN_SIZE  => 255},
			type      => {TYPE_NAME => 'varchar', COLUMN_SIZE  => 255},
			id_object => {TYPE_NAME => 'int'},
			id_user	  => {TYPE_NAME => 'int'},
			dt        => {TYPE_NAME => 'timestamp'},
			html      => {TYPE_NAME => 'text'},
			error     => {TYPE_NAME => 'tinyint', COLUMN_DEF => 0},
			gziped    => {TYPE_NAME => 'tinyint', COLUMN_DEF => 0},
			params    => {TYPE_NAME => 'text'},
		},

	};

	$model_update -> assert (
	
		tables => \%defs, 
				
		prefix => 'sql_assert_core_tables#',
		
	);

	$model_update -> {core_ok} = 1;
		
__log_profilinig ($time, ' <sql_assert_core_tables>');
	
}

################################################################################

sub sql_temporality_callback {
		
	my ($self, %params) = @_;
	
	my $needed_tables = $params {tables};
	
	foreach my $name (keys (%$needed_tables)) {

		sql_is_temporal_table ($name) or next;
		
		my $log_def = Storable::dclone ($needed_tables -> {$name});
		
		foreach my $key (keys %{$log_def -> {columns}}) {
			delete $log_def -> {columns} -> {$key} -> {_EXTRA};
			delete $log_def -> {columns} -> {$key} -> {_PK};
		}

		$log_def -> {columns} -> {id} -> {TYPE_NAME} ||= 'int';

		delete $log_def -> {data};

		$log_def -> {keys} ||= {};
		$log_def -> {keys} -> {__id} = 'id';

		$log_def -> {columns} -> {__dt} = {
			TYPE_NAME => 'datetime',
		};

		$log_def -> {columns} -> {__id} = {
			TYPE_NAME  => 'int', 
			_EXTRA => 'auto_increment', 
			_PK    => 1,
		};

		$log_def -> {columns} -> {__op} = {
			TYPE_NAME  => 'int', 
		};

		$log_def -> {columns} -> {__id_log} = {
			TYPE_NAME  => 'int', 
		};

		$log_def -> {columns} -> {__is_actual} = {
			TYPE_NAME  => 'tinyint', 
			NULLABLE => 0,
			COLUMN_DEF => 0,
		};

		$params {tables} -> {'__log_' . $name} = $log_def;			

	}
	
}

################################################################################

sub sql_is_temporal_table {

	if (ref $conf -> {db_temporality} eq ARRAY) {
		$conf -> {db_temporality} = {(map {$_ => 1} @{$conf -> {db_temporality}})};
	}

	my ($name) = @_;
	
	return 0 if $name =~ /^__log_/;

	if (ref $conf -> {db_temporality} eq HASH) {
		return $conf -> {db_temporality} -> {$name};
	}
	else {
		return $conf -> {db_temporality};
	}

}

################################################################################

sub sql_reconnect {

my $time = time;

	if ($db && $model_update && $model_update -> {core_ok}) {
		my $ping = $db -> ping;
$time = __log_profilinig ($time, '  sql_reconnect: ping');
		return if $ping;
	}
	
	check_systables ();

$time = __log_profilinig ($time, '  sql_reconnect: check_systables');

	our $db = DBI -> connect ($preconf -> {'db_dsn'}, $preconf -> {'db_user'}, $preconf -> {'db_password'}, {
		RaiseError  => 1, 
		AutoCommit  => 1,
		LongReadLen => 1000000,
		LongTruncOk => 1,
		InactiveDestroy => 0,
	});

$time = __log_profilinig ($time, '  sql_reconnect: connect');

	my $driver_name = $db -> get_info ($GetInfoType {SQL_DBMS_NAME});

$time = __log_profilinig ($time, '  sql_reconnect: driver name selected');
	
	$driver_name =~ s{\W}{}gsm;

	my $path = __FILE__;
	
	$path =~ s{(.)SQL\.pm$}{${1}SQL$1${driver_name}.pm};

	do $path;

$time = __log_profilinig ($time, '  sql_reconnect: driver reloaded');

	die $@ if $@;

$time = __log_profilinig ($time, '  sql_reconnect: driver version selected');

	unless ($preconf -> {no_model_update}) {
	
		our $model_update = $_NEW_PACKAGE -> new (
			$db, 
			dump_to_stderr 		=> 1,
			before_assert		=> $conf -> {'db_temporality'} ? \&sql_temporality_callback : undef,
			schema			=> $preconf -> {db_schema},
			__voc_replacements	=> $conf -> {systables} -> {__voc_replacements}, 
			core_voc_replacement_use=> $conf -> {core_voc_replacement_use},
		);
	
	}

	our $SQL_VERSION = sql_version ();

	$SQL_VERSION -> {driver} = $driver_name;

$time = __log_profilinig ($time, '  sql_reconnect: $model_update created');

}   	

################################################################################

sub sql_disconnect {
	if ($db) { $db -> disconnect; }
	undef $db;
}

################################################################################

sub sql_select_vocabulary {

	my ($table_name, $options) = @_;	
	
	$options -> {order} ||= '2';
	
	my $filter = '1=1';
	my $limit  = '';
	
	if ($_REQUEST {__read_only}) {
	
		if ($options -> {field} && $options -> {item}) {
			my $id = 0 + $options -> {item} -> {$options -> {field}};
			$filter .= ' AND id = ' . $id;
		}
		else {
			$filter .= ' AND fake <= 0';
		}
	
	}
	else {
		$filter .= ' AND fake = 0';
	}
	
	$filter .= " AND $options->{filter}" if $options -> {filter};
	
	my @params = ();
	
	if ($options -> {in}) {
	
		my $in = $options -> {in};
		
		my $ref = ref $in;
	
		if ($ref eq SCALAR) {
		
			my $tied = tied $$in;
		
			if (_sql_ok_subselects ()) {
				
				$filter .= " AND id IN ($tied->{sql})";

				push @params, @{$tied -> {params}};
				
			}
			else {

				$filter .= " AND id IN ($$in)";

			}

		}
		elsif ($ref eq ARRAY) {
		
			@$in > 0 or return [];
			
			$in = join ',', @$in;
			
			$filter .= " AND id IN ($in)";
		
		}
		elsif (!$ref) {
		
			$in =~ /\d/ or return [];

			$filter .= " AND id IN ($in)";
		
		}
		else {
			die "Wrong IN list";
		}
	
	}

	if ($options -> {not_in}) {
	
		my $in = $options -> {not_in};
		
		my $ref = ref $in;
	
		if ($ref eq SCALAR) {
		
			my $tied = tied $$in;
		
			if (_sql_ok_subselects ()) {
				
				$filter .= " AND id NOT IN ($tied->{sql})";

				push @params, @{$tied -> {params}};
				
			}
			else {

				$filter .= " AND id NOT IN ($$in)";

			}

		}
		elsif ($ref eq ARRAY) {
		
			@$in > 0 or return [];
			
			$in = join ',', @$in;
			
			$filter .= " AND id NOT IN ($in)";
		
		}
		elsif (!$ref) {
		
			$in =~ /\d/ or return [];

			$filter .= " AND id NOT IN ($in)";
		
		}
		else {
			die "Wrong [NOT] IN list";
		}
	
	}

	if ($preconf -> {subset} && $table_name eq $conf -> {systables} -> {roles}) {
		
		$filter .= " AND name IN ('-1'";
		
		foreach my $name (keys %{$preconf -> {subset_names}}) {			
			$filter .= ", '";
			$filter .= $name;
			$filter .= "'";
		}
		
		$filter .= ")";
		
	}
	
	$limit = "LIMIT $options->{limit}" if $options -> {limit};

	$options -> {label} ||= 'label';
	if ($options -> {label} ne 'label') {
		$options -> {label} =~ s/ AS.*//i;
		$options -> {label} .= ' AS label';
	}
	
	$options -> {label} .= ', parent' if $options -> {tree};
	
	my @list;
	
	my $package; # = __PACKAGE__;
	
	my ($_package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller (0);
	
	if ($subroutine =~ /^(\w+)\:\:/) {
	
		$package = $1;
	
	}
	else {
	
		$package = __PACKAGE__;
	
	}

	tie @list, 'Eludia::Tie::Vocabulary', {
	
		sql      => "SELECT id, $$options{label}, fake FROM $table_name WHERE $filter ORDER BY $$options{order} $limit",
		
		params   => \@params,
		
		_REQUEST => \%_REQUEST,
		
		package  => $package,
		
		tree     => $options -> {tree},
		
	};
		
	return \@list;
			
}

################################################################################

sub sql_select_id {

	my ($table, $values, @lookup_field_sets) = @_;

	my %values = ();
	
	my $forced = {};
	
	foreach my $key (keys %$values) {	

		$key =~ /^(\-?)(.*)$/;
		$forced -> {$2} = 1 if $1;
		$values {$2} = $values -> {$key};

	}
	
	$values = \%values;
	
	exists $values -> {fake} or $values -> {fake} = 0;
	
	@lookup_field_sets = (['label']) if @lookup_field_sets == 0;
	
	my $record = {};
	
	my $auto_commit = $db -> {AutoCommit};
	
	eval { $db -> {AutoCommit} = 0; };
	
	sql_lock ($table);

	foreach my $lookup_fields (@lookup_field_sets) {
	
		if (ref $lookup_fields eq CODE) {		
			next if &$lookup_fields ();
			return 0;		
		}

		my $sql = "SELECT * FROM $table WHERE fake <= 0";
		my @params = ();

		foreach my $lookup_field (@$lookup_fields) {
		
			my $value = $values -> {$lookup_field};
			
			if ($value eq '' && $SQL_VERSION -> {driver} eq 'Oracle') {
			
				$value = undef;
			
			}
			
			if (defined $value) {
			
				$sql .= " AND $lookup_field = ?";
				push @params, $values -> {$lookup_field};
				
			}
			else {

				$sql .= " AND $lookup_field IS NULL";

			}
		
		}

		$sql .= " ORDER BY fake DESC, id DESC";
		
		$record = sql_select_hash ($sql, @params);

		last if $record -> {id};

	}
		
	while (my $id = ($record -> {is_merged_to} || $record -> {id_merged_to})) {
		$record = sql_select_hash ($table, $id);
	}
	
	if ($record -> {id}) {
	
		my @keys   = ();
		my @values = ();

		foreach my $key (keys %$values) {

			($forced -> {$key} && $values -> {$key} ne $record -> {$key}) or $record -> {$key} eq '' or next;

			push @keys,   $key;
			push @values, $values -> {$key};

		}

		if (@keys) {

			sql_do ('UPDATE ' . $table . ' SET ' . (join ', ', map {"$_ = ?"} @keys) . ' WHERE id = ?', @values, $record -> {id});

		}
	
	}

	$record -> {id} ||= sql_do_insert ($table, $values);
	
	sql_unlock ($table);
	
	if ($auto_commit) {
	
		eval { 
			$db -> commit;
			$db -> {AutoCommit} = 1; 
		};

	}
	
	return $record -> {id};

}

################################################################################

sub sql_do_relink {

	my ($table_name, $old_ids, $new_id, $options) = @_;			
	
	sql_weave_model ($DB_MODEL);

	ref $old_ids eq ARRAY or $old_ids = [$old_ids];
	
	my $column_name = '';
	$column_name = 'is_merged_to' if $DB_MODEL -> {tables} -> {$table_name} -> {columns} -> {is_merged_to};
	$column_name = 'id_merged_to' if $DB_MODEL -> {tables} -> {$table_name} -> {columns} -> {id_merged_to};
	
	my $record = sql_select_hash ($table_name, $new_id);
	my @empty_fields = ();
	foreach my $key (keys %$record) {
		next if $options -> {no_update};
		next if $record -> {$key} . '' ne '';
		next if $key eq 'id';
		next if $key eq 'fake';
		next if $key eq 'is_merged_to';
		next if $key eq 'id_merged_to';
		push @empty_fields, $key;
	}
			
	my $table__moved_links;		
				
	if ($SQL_VERSION -> {driver} eq 'Oracle') {
		$table__moved_links = "\U$conf->{systables}->{__moved_links}";
	} else {
		$table__moved_links = $conf->{systables}->{__moved_links};
	}
	
	foreach my $old_id (@$old_ids) {
	
warn "relink $table_name: $old_id -> $new_id";

		my $record = sql_select_hash ($table_name, $old_id);
		
		foreach my $empty_field (@empty_fields) {
			$_REQUEST {'_' . $empty_field} ||= $record -> {$empty_field};
		}

		foreach my $column_def (@{$DB_MODEL -> {aliases} -> {$table_name} -> {references}}) {

warn "relink $$column_def{table_name} ($$column_def{name}): $old_id -> $new_id";

			if ($column_def -> {TYPE_NAME} =~ /int/) {
			
				sql_do (<<EOS, $old_id);
					INSERT INTO $model_update->{quote}$table__moved_links$model_update->{quote}
						(table_name, column_name, id_from, id_to)
					SELECT
						'$$column_def{table_name}' AS table_name,
						'$$column_def{name}' AS column_name,
						id AS id_from,
						'$old_id' AS id_to
					FROM
						$$column_def{table_name}
					WHERE
						$$column_def{name} = ?
EOS

				sql_do ("UPDATE $$column_def{table_name} SET $$column_def{name} = ? WHERE $$column_def{name} = ?", $new_id, $old_id);
				
			}
			else {
			
				my $_old_id = ',' . $old_id . ',';
				my $_new_id = ',' . $new_id . ',';
			
				sql_do (<<EOS, '%' . $old_id . '%');
					INSERT INTO $model_update->{quote}$table__moved_links$model_update->{quote}}
						(table_name, column_name, id_from, id_to)
					SELECT
						'$$column_def{table_name}' AS table_name,
						'$$column_def{name}' AS column_name,
						id AS id_from,
						'$_old_id' AS id_to
					FROM
						$$column_def{table_name}
					WHERE
						$$column_def{name} LIKE ?
EOS

				sql_do ("UPDATE $$column_def{table_name} SET $$column_def{name} = REPLACE($$column_def{name}, ?, ?) WHERE $$column_def{name} LIKE ?", $_old_id, $_new_id, '%' . $_old_id . '%');

			}

		}
				
		if ($column_name) {
			sql_do ("UPDATE $table_name SET fake = -1, $column_name = ? WHERE id = ?", $new_id, $old_id);
		}
		else {
			sql_do ("UPDATE $table_name SET fake = -1 WHERE id = ?", $old_id);
		}

	}

	sql_do_update ($table_name, \@empty_fields) if @empty_fields > 0;

	delete $DB_MODEL -> {aliases};

}

################################################################################

sub sql_undo_relink {

	sql_weave_model ($DB_MODEL);

	my ($table_name, $old_ids) = @_;

	ref $old_ids eq ARRAY or $old_ids = [$old_ids];

	my $table__moved_links; 
	
	if ($SQL_VERSION -> {driver} eq 'Oracle') {
		$table__moved_links = "\U$conf->{systables}->{__moved_links}";		
	} else {
		$table__moved_links = $conf->{systables}->{__moved_links};
	}

	foreach my $old_id (@$old_ids) {
		
		$old_id > 0 or next;

warn "undo relink $table_name: $old_id";

		my $record = sql_select_hash ($table_name, $old_id);
		
		foreach my $column_def (@{$DB_MODEL -> {aliases} -> {$table_name} -> {references}}) {

			my $from = <<EOS;
				FROM
					$model_update->{quote}$table__moved_links$model_update->{quote}
				WHERE
					table_name = '$$column_def{table_name}'
					AND column_name = '$$column_def{name}'
					AND id_to = $old_id
EOS
			my $ids = sql_select_ids ("SELECT id_from $from");
			sql_do ("DELETE $from");

warn "undo relink $$column_def{table_name} ($$column_def{name}): $old_id";

			if ($column_def -> {TYPE_NAME} =~ /int/) {
				sql_do ("UPDATE $$column_def{table_name} SET $$column_def{name} = ? WHERE id IN ($ids)", $old_id);
			}
			else {			
				$old_id_ = $old_id . ',';
				sql_do ("UPDATE $$column_def{table_name} SET $$column_def{name} = CONCAT($$column_def{name}, ?) WHERE id IN ($ids)", $old_id_);
			}

		}
		
	}
	
	delete $DB_MODEL -> {aliases};
	
}

################################################################################

sub assert_fake_key {

	my ($table_name) = @_;

	$DB_MODEL -> {tables} -> {$table_name} or return;
	
	return if $DB_MODEL -> {tables} -> {$table_name} -> {keys} -> {fake};
	
	$model_update -> assert (
	
		tables => {
	
			$table_name => {
				keys => {fake => 'fake'},
			},
	
		},
		
		prefix => 'assert_fake_key#',

	);

}

################################################################################

sub is_recyclable {

	my ($table_name) = @_;
	
	return 0 if $table_name eq $conf -> {systables} -> {log};
	return 0 if $table_name eq $conf -> {systables} -> {sessions};
	
	if (ref $conf -> {core_recycle_ids} eq ARRAY) {
		$conf -> {core_recycle_ids} = {map {$_ => 1} @{$conf -> {core_recycle_ids}}}
	}

	return 1 if $conf -> {core_recycle_ids} == 1 || $conf -> {core_recycle_ids} -> {$table_name};
	return 0;

}

################################################################################

sub delete_fakes {
	
	my ($table_name) = @_;
	
	$table_name    ||= $_REQUEST {type};

	return if is_recyclable ($table_name);
	
	assert_fake_key ($table_name);
	
	my $ids = sql_select_ids (<<EOS);
		SELECT
			$table_name.id
		FROM
			$table_name
			LEFT JOIN $conf->{systables}->{sessions} ON $table_name.fake = $conf->{systables}->{sessions}.id
		WHERE
			$table_name.fake > 0
			AND $conf->{systables}->{sessions}.id_user IS NULL
EOS
			
	sql_do ("DELETE FROM $table_name WHERE id IN ($ids)");

}

################################################################################
	
sub __log_sql_profilinig {
	
	my ($options) = @_;

	$_REQUEST {__sql_time} += 1000 * (time - $options -> {time});
	 
}

################################################################################

sub sql_extract_params {

	my ($sql, @params) = @_;

	return ($sql, @params) if $sql !~ /^\s*(SELECT|INSERT|UPDATE|DELETE)/i;

	my $sql1 = '';
	my @params1 = ();
	my $i = 0;
	my $flag = $sql =~ /SELECT/i ? 0 : 1;
	my $flag1 = 1;

	foreach my $token ( # stolen from http://search.cpan.org/src/IZUT/SQL-Tokenizer-0.09/lib/SQL/Tokenizer.pm

		$sql =~ m{
			(
			    (?:>=|<=|==)            # >=, <= and == operators
			    |
			    [\(\),=;]               # punctuation (parenthesis, comma)
			    |
			    \'\'(?!\')              # empty single quoted string
			    |
			    \"\"(?!\"")             # empty double quoted string #"
			    |
			    ".*?(?:(?:""){1,}"|(?<!["\\])"(?!")|\\"{2})
						    # anything inside double quotes, ungreedy
			    |
			    '.*?(?:(?:''){1,}'|(?<!['\\])'(?!')|\\'{2})
						    # anything inside single quotes, ungreedy.
			    |
			    --[\ \t\S]*             # comments
			    |
			    \#[\ \t\S]*             # mysql style comments
			    |
			    /\*[\ \t\n\S]*?\*/      # C style comments
			    |
			    [^\s\(\),=;]+           # everything that doesn't matches with above
			    |
			    \n                      # newline
			    |
			    [\t\ ]+                 # any kind of white spaces
			)
		    }smxgo

		) {


		$token =~ s{\s+}{ }gsm;

		if (
			$token =~ /^--\s/
			|| $token =~ /^\/\*\s*[^\+]/ || $token =~ /^\#*\s/
		) {
			$token = ' ';
		}
		else {
		
			$flag  = 1 if $token =~ /^FROM$/i;
			$flag1 = 1 if $token =~ /^END$/i;
			$flag  = 0 if $token =~ /^ORDER$/i || $token =~ /^GROUP$/i || $token =~ /^SELECT$/i;
			$flag1 = 0 if $token =~ /^CASE$/i;
			
		
			if ($token eq '?') {

				push @params1, $params [$i ++];

			}
			elsif (

				$token =~ /^0(\d+)$/

			) {
				$token = $1;
			}
			elsif (

				($flag && $flag1) && (
					$token =~ /^(\-?\d+)$/
					|| $token =~ /^\'(.*?)\'$/
				) 


			) {

				my $value = $1;
				$value =~ s{\\\'}{\'}gsm;
				push @params1, $value;
				$token = '?';

			}
		
		}

		$token =~ /^\"(.*?)\"$/ or $token = uc $token;

		$sql1 .= ' ';
		$sql1 .= $token;
		$sql1 .= ' ';

	}

	$sql1 =~ s{\s+$}{};
	$sql1 =~ s{^\s+}{};
	$sql1 =~ s{\s+}{ }g;
	
	$sql = $sql1;
	
	return ($sql1, @params1);

}

################################################################################

sub sql_adjust_fake_filter {

	my ($sql, $options) = @_;
	
	$options -> {fake} or return $sql;
	
	my $where    = 'WHERE ';
	my $fake      = $_REQUEST {fake} || 0;
	my $condition = $fake =~ /\,/ ? "IN ($fake)" : '=' . $fake;
	
	foreach my $table (split /\,/, $options -> {fake}) {
		$where .= "$table.fake $condition AND ";
	}	

	$sql =~ s{where}{$where}i;
	
	return $sql;

}

################################################################################

sub __log_request_profilinig {

	my ($request_time) = @_;

	return unless ($preconf -> {core_debug_profiling} > 2 && $model_update -> {core_ok});

	my $c = $r -> connection; 

	$_REQUEST {_id_request_log} = sql_do_insert ($conf -> {systables} -> {__request_benchmarks}, {
		id_user	=> $_USER -> {id}, 
		ip	=> $ENV {REMOTE_ADDR}, 
		ip_fw	=> $ENV {HTTP_X_FORWARDED_FOR},
		fake	=> 0,
		type	=> $_REQUEST {type},
		mac	=> get_mac (),
		request_time	=> int ($request_time),
		connection_id	=> $c -> id (),
		connection_no	=> $c -> keepalives (),
	});
	
	sql_do ("UPDATE $conf->{systables}->{__request_benchmarks} SET params = ? WHERE id = ?",
		Data::Dumper -> Dump ([\%_REQUEST], ['_REQUEST']), $_REQUEST {_id_request_log}); 

}

################################################################################
	
sub __log_request_finish_profilinig {

	my ($options) = @_;

	return 
		unless ($preconf -> {core_debug_profiling} > 2 && $model_update -> {core_ok}); 

	my $time = time;

	sql_do ("UPDATE $conf->{systables}->{__request_benchmarks} SET application_time = ?, sql_time = ?, response_time = ?, bytes_sent = ?, is_gzipped = ? WHERE id = ?",
		int ($options -> {application_time}), 
		int ($options -> {sql_time}), 
		$options -> {out_html_time} ? int (1000 * (time - $options -> {out_html_time})) : 0, 
		$r -> bytes_sent,
		$options -> {is_gzipped},		 
		$options -> {id_request_log},
	);
}

################################################################################

sub sql_filters {

	my ($root, $filters) = @_;
		
	my $have_id_filter = 0;
	my $cnt_filters    = 0;
	my $where          = '';
	my $order;
	my $limit;
	my @params = ();

	foreach my $filter (@$filters) {

		ref $filter or $filter = [$filter, $_REQUEST {$filter}];

											# 'id_org'       --> ['id_org' => $_REQUEST {id_org}]

		my ($field, $values) = @$filter;

		if ($field eq 'ORDER') {
			$order = $values;
			next;
		}

		if ($field eq 'LIMIT') {
			$limit = $values;
			ref $limit or $limit = [$limit];
			next;
		}

		ref $values eq ARRAY or $values = [$values];

		my $first_value = $values -> [0];

		my $tied;

		if (ref $first_value eq SCALAR) {

			$tied = tied $$first_value;

		}

		unless ($tied) {

			next if $first_value eq '' or $first_value eq '0000-00-00';

		}

		$cnt_filters ++;

		$have_id_filter = 1 if $field eq 'id';

		$field =~ s{([a-z][a-z0-9_]*)}{$root.$1}gsm;

		if ($field =~ /\s+IN\s*$/sm) {

											# ['id_org IN' => sql_select_ids (...)] => "users.id_org IN (SELECT ...)"
											# ['id_org IN' => sql ('orgs(id)' => [[id_kind => 1]])] => "users.id_org IN (SELECT ...)"

			if ($tied) {							

				if (_sql_ok_subselects ()) {

					$where .= "\n  AND ($field ($tied->{sql}))";

					push @params, @{$tied -> {params}};

				}
				else {

					$where .= "\n  AND ($field ($$first_value))";

				}

			}
			else {								# ['id_org IN' => [0, undef, 1]] => "users.id_org IN (-1, 1)"

				$where .= "\n  AND ($field (-1";

				foreach (grep {/\d/} @$values) { $where .= ", $_"}

				$where .= "))";

			}

		}
		else {

			$field =~ /\w / or $field =~ /\=/ or $field .= ' = ';		# 'id_org'           --> 'id_org = '
			$field =~ /\?/  or $field .= ' ? '; 				# 'id_org LIKE '     --> 'id_org LIKE ?'
#			$field =~ s{LIKE\s+\%\?\%}{LIKE CONCAT('%', ?, '%')}gsm;
#			$field =~ s{LIKE\s+\?\%}{LIKE CONCAT(?, '%')}gsm;		# 'dt <+ 2008-09-30' --> 'dt < 2008-10-01'

			if ($field =~ s{\<\+}{\<}) {			
				my @ymd = split /\-/, $first_value;				
				$values -> [0] = dt_iso (Date::Calc::Add_Delta_Days (@ymd, 1));
			}
			
			my @tokens = split /(LIKE\s+\%?\?\%)/, $field;
			
			$where .= "\n AND (";
			
			foreach my $token (@tokens) {
			
				if ($token =~ /LIKE\s+(\%?)\?(\%)/) {

					$where .= ' LIKE ?';
					my $v = shift @$values;
					push @params, "$1$v$2";

				}
				else {
				
					$where .= $token;
					
					foreach (1 .. $token =~ y/?/?/) {
					
						push @params, shift @$values;
					
					}
				
				}
			
			}			

			$where .= ")";

#			$where .= "\n AND ($field)";
#			push @params, @$values;

		}


	}
	
	return {
		have_id_filter => $have_id_filter,
		cnt_filters    => $cnt_filters,
		order          => $order,
		limit          => $limit,
		where          => $where,
		params         => \@params,
	};

}

################################################################################

sub sql {

	if (ref $_[0] eq HASH) {
	
		my ($data, $root, @other) = @_;

		my ($records, $cnt, $portion) = sql ($root, @other);
		
		if ($root =~ /^\w+/) {
			$data -> {$&} = $records;
		}
		else {
			die "Invalid table reference: '$root'\n";
		}
		
		if ($portion) {
		
			$data -> {cnt}     = $cnt;
			$data -> {portion} = $portion;
		
		}
		
		return $data;
	
	}
	
	check___query ();
	
	my $_args = $preconf -> {core_debug_sql} ? [(), @_] : undef;

	my ($root_table, @other) = @_;
	
	my $sub;
	
	if (@other > 0 && ref $other [-1] eq CODE) {
	
		$sub = pop @other;
	
	}
	
	$root_table =~ /(\w+)(?:\((.*?)\))?/ or die "Invalid table definition: '$table'\n";

	my ($root, $root_columns) = ($1, $2);
	
	$root_columns ||= '*';
		
	my @root_columns = split /\s*\,\s*/, $root_columns;

	if ($root_columns [0] eq '*') {
	
		my $def = $DB_MODEL -> {tables} -> {$root};
		
		if ($def && $def -> {columns}) {

			@root_columns = keys %{$DB_MODEL -> {default_columns}};
			
			foreach my $k (keys %{$def -> {columns}}) {
			
				next if $def -> {columns} -> {$k} -> {TYPE_NAME} eq 'blob';
				
				push @root_columns, $k;
			
			}
		
		}

	}

	my $select  = "SELECT\n ";
	$select .= join ', ', map {"$root.$_\n "} @root_columns;

	my $from   = "\nFROM\n $root";
	my $where  = "\nWHERE 1=1 \n";
	my $order  = [$root . '.label'];
	my $limit;
	my @join_params = ();
	my @params = ();

	if (@other == 0) {								# sql ('users')   --> sql ('users' => ['id'])
	
		@other = (['id']);
	
	}

	if (!ref $other [0]) {
	
		$other [0] = [[id => $other [0]]];					# sql (users => 1) --> sql ('users' => ['id' => 1])
	
	}
		
	my ($filters, @tables) = @other;
	
	my $sql_filters = sql_filters ($root, $filters);
	
	$where .= $sql_filters -> {where};
	@params = @{$sql_filters -> {params}};
	$limit  = $sql_filters -> {limit};
	$order  = $sql_filters -> {order} if $sql_filters -> {order};
	my $have_id_filter = $sql_filters -> {have_id_filter};
	my $cnt_filters    = $sql_filters -> {cnt_filters};

	my $default_columns = '*';
	
	unless ($have_id_filter) {
		
		$default_columns = 'id, label, fake';

		$where .= $_REQUEST {fake} =~ /\,/ ? "\n AND $root.fake IN ($_REQUEST{fake})" : "\n AND $root.fake = " . ($_REQUEST {fake} || 0);

	}	
		
	foreach my $table (@tables) {
	
		my $filters = undef;
	
		if (ref $table eq ARRAY) { 
			$filters = $table -> [1] || [];
			$table   = $table -> [0];
		}

		my $alias = '';
		
		if ($table =~ /\s+AS\s+(\w+)\s*$/) {
			$table = $`;
			$alias = $1;
		}

		$table =~ s{\s}{}gsm;

		$table =~ /(\-?)(\w+)(?:\((.*?)\))?/ or die "Invalid table definition: '$table'\n";

		my ($minus, $name, $columns) = ($1, $2, $3);

		$alias ||= $name;
		
		$table = {
		
			src     => $table,
			name    => $name,
			columns => $columns,
			single  => en_unplural ($alias),
			alias   => $alias,
			filters => $filters,
			join    => $minus ? 'INNER JOIN' : 'LEFT JOIN',
			
		};
		
		$table -> {single} =~ s{ie$}{y};

	}	
	
	my @cols = ();
	my $cols_cnt = 0;	
			
	foreach my $table (@tables) {

		my $found = 0;
		
		if ($table -> {filters}) {
		
			my $definition = $DB_MODEL -> {tables} -> {$table -> {name}};

			my $referring_columns = $definition -> {columns};
			
			my @t = ({name => $root, single => en_unplural ($root)});
			
			foreach my $t (@tables) {
			
				last if $t -> {alias} eq $table -> {alias};
				
				push @t, $t;
			
			}

			foreach my $t (reverse @t) {
			
				my $referring_field_name = 'id_' . $t -> {single};
				
				my $column = $referring_columns -> {$referring_field_name};
			
				unless ($column) {

					foreach my $k (keys %$referring_columns) {

						my $c = $referring_columns -> {$k};

						$c -> {ref} eq $t -> {name} or next;

						$column = $c;
						$referring_field_name = $k;

						last;

					}

				}

				$column or next;

				my $sql_filters = sql_filters ($table -> {alias}, $table -> {filters});

				$from .= "\n $table->{join} $table->{name}";
				$from .= " AS $table->{alias}" if $table -> {name} ne $table -> {alias};
				$from .= " ON ($table->{alias}.$referring_field_name = $t->{name}.id $sql_filters->{where})";
				
				push @join_params, @{$sql_filters -> {params}};

				$found = 1;

				last;

			}
					
		}
		
		if (!$found) {
		
			my $referring_field_name = 'id_' . $table -> {single};

			foreach my $t ({name => $root}, @tables) {

				my $referring_table = $DB_MODEL -> {tables} -> {$t -> {name}};

				my $column = $referring_table -> {columns} -> {$referring_field_name};

				unless ($column) {

					my $referring_columns = $referring_table -> {columns};

					foreach my $k (keys %$referring_columns) {

						my $c = $referring_columns -> {$k};

						$c -> {ref} eq $table -> {name} or next;

						$column = $c;
						$referring_field_name = $k;

						last;

					}

				}

				$column or next;

				$from .= "\n $table->{join} $table->{name}";
				$from .= " AS $table->{alias}" if $table -> {name} ne $table -> {alias};
				
				$t -> {alias} ||= $t -> {name};

				if ($table -> {filters}) {
					my $sql_filters = sql_filters ($table -> {alias}, $table -> {filters});
					$from .= " ON ($t->{alias}.$referring_field_name = $table->{alias}.id $sql_filters->{where})";
					push @join_params, @{$sql_filters -> {params}};
				}
				else {
					$from .= " ON $t->{alias}.$referring_field_name = $table->{alias}.id";
				}

				$found = 1;

				last;

			}		

		}		

		$found or die "Referrer for $table->{alias} not found\n";

		$table -> {columns} ||= $default_columns;
		
		my @columns = ();
		
		my $def = $DB_MODEL -> {tables} -> {$table -> {name}} -> {columns};
		
		if ($table -> {columns} eq '*' and $def) {
		
			@columns = ('id', 'fake', keys %$def);
		
		}
		else {
		
			@columns = split /\s*\,\s*/, $table -> {columns};
		
		}
		
		foreach my $column (@columns) {
		
			next if $def -> {$column} -> {TYPE_NAME} eq 'blob';
		
			$cols [$cols_cnt] = [en_unplural ($table -> {alias}), $column];
		
			$select .= "\n, $table->{alias}.$column AS gfcrelf$cols_cnt",

			$cols_cnt ++;
		
		}
			
	}
	
	my $sql = $select . $from . $where;
	
	@params = (@join_params, @params);

	my $is_ids = (@root_columns == 1 && $root_columns [0] ne '*') ? 1 : 0;
	
	!$is_ids or $cnt_filters or return undef;
	
	$sql =~ s{^SELECT}{SELECT DISTINCT} if $is_ids;

	if (!$have_id_filter && !$is_ids) {
	
		$order = order ($order)  if $order !~ /\W/;
		$order = order (@$order) if ref $order eq ARRAY;
		$order =~ s{(?<!\.)\b([a-z][a-z0-9_]*)\b(?!\.)}{${root}.$1}gsm;
		$sql .= "\nORDER BY\n $order";

	}

	my @result;
	my $records;
	
	if ($preconf -> {core_debug_sql}) {
	
		warn Dumper ({args => $_args, sql => $sql, params => \@params});
	
	}
	
	if ($have_id_filter || ($limit && @$limit == 1 && $limit -> [0] == 1)) {

		@result = (sql_select_hash ($sql, @params));

		$records = [$result [0]];

	}
	elsif ($sub) {
	
		return sql_select_loop (
			
			$sql, 
			
			sub {
			
				sql_unwrap_record ($i, \@cols);
				
				&$sub ($i);
				
			}, 
			
			@params
			
		);
	
	}
	else {
	
		if ($limit) {
		
			$sql .= "\nLIMIT\n " . (join ', ', @$limit);
			
			@result = (sql_select_all_cnt ($sql, @params), $limit -> [1]);
	
			$records = $result [0];
	
		}
		else {

			if ($is_ids) {
							
				my $ids;
				
				my $tied = tie $ids, 'Eludia::Tie::IdsList', {

					sql 			=> $sql,

					_REQUEST 		=> \%_REQUEST,

					package 		=> __PACKAGE__,

					params 			=> \@params,

					db 			=> $db,
			
					sql_translator_ref	=> get_sql_translator_ref(),

				};

				return \$ids;

			}
			else {

				@result = (sql_select_all ($sql, @params));

				$records = $result [0];

			}

		}
	
	}	

	foreach my $record (@$records) {
	
		sql_unwrap_record ($record, \@cols);
	
	}
	
	return wantarray ? @result : $result [0];

}

################################################################################

sub sql_unwrap_record {

	my ($record, $cols) = @_;

	foreach my $key (keys %$record) {
		
		if ($key =~ /^gfcrelf(\d+)$/) {
				
			my $def = $cols -> [$1];
				
			$record -> {$def -> [0]} -> {$def -> [1]} = delete $record -> {$key};
					
		}
		elsif ($key =~ /(\w+)\!(\w+)/) {

			my ($t, $f) = ($1, $2);

			$record -> {en_unplural ($t)} -> {$f} = delete $record -> {$key};

		}
					
	}

}

################################################################################

sub en_unplural {

	my ($s) = @_;

	if ($s =~ /status$/)                { return $s }
	if ($s =~ /goods$/)                 { return $s }
	if ($s =~ s{tives$}{tive})          { return $s }
	if ($s =~ s{ives$}{ife})            { return $s } # life, wife, knife
	if ($s =~ s{ves$}{f})               { return $s }
	if ($s =~ s{ies$}{y})               { return $s }
	if ($s =~ s{(\.)ice$}{$1ouse})      { return $s }
	if ($s =~ s{men$}{man})             { return $s }
	if ($s =~ s{eet(h?)$}{oot$1})       { return $s }
	if ($s =~ s{i$}{us})                { return $s }
	if ($s =~ s{a$}{um})                { return $s }
	if ($s =~ s{(o|ch|sh|ss|x)es$}{$1}) { return $s }
	$s =~ s{s$}{};
	return $s;

}

################################################################################

sub sql_select_ids {

	my ($sql, @params) = @_;	

	my $ids;

	my $tied = tie $ids, 'Eludia::Tie::IdsList', {
	
		sql 			=> $sql,
		
		_REQUEST 		=> \%_REQUEST,
		
		package 		=> __PACKAGE__,
		
		params 			=> \@params,
		
		db 			=> $db,

		sql_translator_ref	=> get_sql_translator_ref(),

		
	};
	
	return wantarray ? (
		$ids,
		wantarray && _sql_ok_subselects () ? $tied -> _sql : $ids,
	) : $ids;

}

################################################################################

sub sql_upload_files {

	my ($options) = @_;
	
	my @nos = ();
	
	foreach my $k (keys %_REQUEST) {

		$k =~ /^_$options->{name}_(\d+)$/ or next;
		
		$_REQUEST {$k} or next;
		
		push @nos, $1;

	}

	@nos > 0 or return;

	my ($table, $field) = split /\./, $_REQUEST {"__$options->{name}_file_field"};
	
	$options -> {id} ||= $_REQUEST {id};
	
	sql_do ("UPDATE $table SET fake = -1 WHERE $field = ?", $options -> {id});
	
	my $name = $options -> {name};
	
	my $id = $options -> {id};
	
	$options -> {table}            = $table;
	$options -> {file_name_column} = 'file_name';
	$options -> {size_column}      = 'file_size';
	$options -> {type_column}      = 'file_type';
	$options -> {path_column}      = 'file_path';
	$options -> {body_column}      = 'file_body' if $model_update -> get_columns ($table) -> {file_body};

	foreach my $no (sort {$a <=> $b} @nos) {
		
		$options -> {name} = "${name}_${no}";

		$options -> {id} = sql_do_insert ($table => {

			$field => $id,
			fake   => 0,
			
		});
		
		sql_upload_file ($options);
	
	}

	sql_select_loop ("SELECT * FROM $table WHERE $field = ? AND fake = -1", sub {
	
		my $path = $i -> {$options -> {path_column}} or return;
		
		unlink $r -> document_root . $path;
	
	}, $id);

	sql_do ("DELETE FROM $table WHERE $field = ? AND fake = -1", $id);

}

################################################################################
################################################################################

#package DBIx::ModelUpdate;

use DBI::Const::GetInfoType;

################################################################################

sub canonic_key_definition {

	my ($self, $s) = @_;
	
	$s =~ s{\s+}{}g;
	
	return $s;

}

################################################################################

sub do {

	my ($self, $sql, @params) = @_;

	warn $sql . (join ',', map {" '$_' "} @params) . "\n" if $self -> {dump_to_stderr};

	$self -> {db} -> do ($sql, undef, @params);

}

################################################################################

sub new {

	my ($package_name, $db, @options) = @_;
	
	my $driver_name = $db -> get_info ($GetInfoType {SQL_DBMS_NAME});
	
	$driver_name =~ s{\s}{}gsm;
		
#	$package_name .= "::$driver_name";
	
	die $@ if $@;

	my $self = bless ({
		db => $db, 
		driver_name => $driver_name,
		quote => $db -> get_info ($GetInfoType {SQL_IDENTIFIER_QUOTE_CHAR}),
		@options
	}, $package_name);
	
	if ($driver_name eq 'Oracle') {
  		$self -> {characterset} = sql_select_scalar ('SELECT VALUE FROM V$NLS_PARAMETERS WHERE PARAMETER = ?', 'NLS_CHARACTERSET');
  		$self -> {schema} ||= uc $db -> {Username};
  		$self -> {__voc_replacements} = "$self->{quote}$self->{__voc_replacements}$self->{quote}" if $self -> {__voc_replacements} =~ /^_/;
	}
	
	$self -> {schema} ||= '';

	return $self;

}

################################################################################

sub sql_assert_default_columns {

	my ($needed_tables, $params) = @_;

	my $default_columns = $params -> {default_columns} or return $needed_tables;

	foreach my $name (keys %$needed_tables) {
	
		my $definition = $needed_tables -> {$name};

		next if $definition -> {sql};

		foreach my $dc_name (keys %$default_columns) {

			$definition -> {columns} -> {$dc_name} ||= Storable::dclone $default_columns -> {$dc_name};

		}

	}
	
	return $needed_tables;

}

################################################################################

sub assert {

	my $time = time;

	my ($self, %params) = @_;

	&{$self -> {before_assert}} (@_) if ref $self -> {before_assert} eq CODE;
		
	my $needed_tables = sql_assert_default_columns (Storable::dclone $params {tables}, \%params);
		
	($needed_tables, my $new_checksums) = checksum_filter ('db_model', $params {prefix}, $needed_tables);
		
	%$needed_tables > 0 or warn "   DB model update: nothing to do\n" and return;
		
	my $existing_tables = {};	
	
	foreach my $table ($self -> {db} -> tables ('', $self -> {schema}, '%', "'TABLE'")) {
	
		$existing_tables -> {$self -> unquote_table_name ($table)} = {};

	}

	$time = __log_profilinig ($time, '   got existing_tables');
				
	foreach my $name (keys %$needed_tables) {
			
		my $definition = $needed_tables -> {$name};
		
		if ($definition -> {sql}) {
		
			$self -> assert_view ($name, $definition);
			
			delete $needed_tables -> {$name};
			
			next;
			
		}
		
		exists $existing_tables -> {$name} or next;

		$existing_tables -> {$name} -> {columns} = $self -> get_columns ($name);

	}

	$time = __log_profilinig ($time, '   got columns');
	
	
	
	foreach my $name (keys %$needed_tables) {
	
		my $definition = $needed_tables -> {$name};

		if ($existing_tables -> {$name}) {
		
			my $existing_columns = $existing_tables -> {$name} -> {columns};
			
			my $new_columns = {};
				
			foreach my $c_name (keys %{$definition -> {columns}}) {
			
				my $c_definition = $definition -> {columns} -> {$c_name};

				if ($existing_columns -> {$c_name}) {
				
					my $existing_column = $existing_columns -> {$c_name};										

					my $flag = $self -> update_column ($name, $c_name, $existing_column, $c_definition,,$conf -> {core_voc_replacement_use});

					$time = __log_profilinig ($time, "    $name.$c_name " . ($flag ? 'updated' : 'checked'));

				}
				else {
				
					$new_columns -> {$c_name} = $c_definition;
				
				}

			};
			
			if (keys %$new_columns) {

				$self -> add_columns ($name, $new_columns,,$conf -> {core_voc_replacement_use});

				$time = __log_profilinig ($time, "    columns added");

			}

		}
		else {

			$self -> create_table ($name, $definition, $conf -> {core_voc_replacement_use});
		
		}
		
		wish (table_keys => [map {{name => $_, parts => $definition -> {keys} -> {$_}}} (keys %{$definition -> {keys}})], {table => $name, table_def => $definition}) if exists $definition -> {keys};

		wish (table_data => $definition -> {data}, {table => $name}) if exists $definition -> {data};
		
	}
	
	checksum_write ('db_model', $new_checksums);

}

#############################################################################

sub sql_store_ids {

	my $options;
	
	if (@_ == 2 && !ref $_[0] && !ref $_[1]) {
	
		$options = {
			table => $_[0],
			key   => $_[1],
		}
	
	}
	elsif (ref $_[0] eq HASH) {
	
		$options = $_[0];
		
	}
	else {
	
		die "Wrong parameters for sql_store_ids: " . Dumper (\@_);
	
	}
	
	$options -> {root} ||= {'id_' . en_unplural ($_REQUEST {type}) => $_REQUEST {id}};
	
	wish (table_data =>	[map {{	fake => 0, $options -> {key} => $_ }} get_ids ($options -> {key})], $options);

}

#############################################################################

sub wish {

	my ($type, $items, $options) = @_;

	&{"wish_to_adjust_options_for_$type"} ($options);
		
	foreach my $i (@$items) { &{"wish_to_clarify_demands_for_$type"} ($i, $options) }
	
	my $existing = &{"wish_to_explore_existing_$type"} ($options);
	
	my $todo = {};
	
	foreach my $new (@$items) {

		my $old = delete $existing -> {@$new {@{$options -> {key}}}} or (push @{$todo -> {create}}, $new) and next;

		&{"wish_to_update_demands_for_$type"} ($old, $new, $options);

		next if Dumper ($new) eq Dumper ($old);

		&{"wish_to_schedule_modifications_for_$type"} ($old, $new, $todo, $options);		
		
	}
	
	&{"wish_to_schedule_cleanup_for_$type"} ($existing, $todo, $options);
		
	foreach my $action (keys %$todo) { &{"wish_to_actually_${action}_${type}"} ($todo -> {$action}, $options) }

}

#############################################################################

sub wish_to_adjust_options_for_table_data {	

	my ($options) = @_;
		
	$options -> {key} ||= 'id';
	$options -> {key}   = [split /\W/, $options -> {key}];
	
	$options -> {ids}   = -1;

}

#############################################################################

sub wish_to_clarify_demands_for_table_data {	

	my ($i, $options) = @_;

	foreach (keys (%{$options -> {root}})) { $i -> {$_} = $options -> {root} -> {$_} }

	$options -> {ids} .= ",$i->{id}" if defined $i -> {id};

}

#############################################################################

sub wish_to_explore_existing_table_data {	

	my ($options) = @_;
		
	my $sql = "SELECT * FROM $options->{table} WHERE 1=1";
	
	my @params = ();
	
	foreach my $i (keys %{$options -> {root}}) {
		
		$sql .= " AND $i = ?";
			
		push @params, $options -> {root} -> {$i};

	}
	
	$sql .= " AND id IN ($options->{ids})" if $options -> {ids} ne '-1';
	
	my $existing = {};

	sql_select_loop ($sql, sub { $existing -> {@$i {@{$options -> {key}}}} = $i }, @params);
	
	return $existing;

}

#############################################################################

sub wish_to_update_demands_for_table_data {

	my ($old, $new, $options) = @_;

	foreach (keys %$old) {exists  $new -> {$_} or $new -> {$_} = $old -> {$_}};

	foreach (keys %$new) {defined $new -> {$_} and $new -> {$_} .= ''};

}

#############################################################################

sub wish_to_schedule_modifications_for_table_data {	

	my ($old, $new, $todo, $options) = @_;

	push @{$todo -> {update}}, $new;

}

#############################################################################

sub wish_to_schedule_cleanup_for_table_data {	

	my ($existing, $todo, $options) = @_;
	
	%{$options -> {root}} > 0 and %$existing > 0 or return;
			
	$todo -> {'delete'} = [ values %$existing ];

}

#############################################################################

sub wish_to_actually_create_table_data {	

	my ($items, $options) = @_;

	@$items > 0 or return;

	my @cols = ();
	my @prms = ();
	
	foreach my $col (keys %{$items -> [0]}) {

		push @cols, $col;
		push @prms, [ map {$_ -> {$col}} @$items];
	
	}
		
	my $sth = $db -> prepare ("INSERT INTO $options->{table} (" . (join ', ', @cols) . ") VALUES (" . (join ', ', map {'?'} @cols) . ")");

	$sth -> execute_array ({}, @prms);
	
	$sth -> finish;
	
}

#############################################################################

sub wish_to_actually_update_table_data {	

	my ($items, $options) = @_;

	@$items > 0 or return;

	my @cols = ();
	my @prms = ();
	
	foreach my $col (grep {$_ ne 'id'} keys %{$items -> [0]}) {
		
		push @cols, "$col = ?";
		push @prms, [ map {$_ -> {$col}} @$items];
	
	}
	
	push @prms, [ map {$_ -> {id}} @$items];
		
	my $sth = $db -> prepare ("UPDATE $options->{table} SET " . (join ', ', @cols) . " WHERE id = ?");

	$sth -> execute_array ({}, @prms);
	
	$sth -> finish;

}

#############################################################################

sub wish_to_actually_delete_table_data {

	my ($items, $options) = @_;
	
	@$items > 0 or return;
	
	my $sth = $db -> prepare ("DELETE FROM $options->{table} WHERE id = ?");
	
	$sth -> execute_array ({}, [map {$_ -> {id}} @$items]);
	
	$sth -> finish;

}

#############################################################################

sub wish_to_adjust_options_for_table_keys {

	my ($options) = @_;
	
	$options -> {key} = ['global_name'];

}

#############################################################################

sub wish_to_update_demands_for_table_keys {}

#############################################################################

sub wish_to_schedule_modifications_for_table_keys {

	my ($old, $new, $todo, $options) = @_;

	push @{$todo -> {alter}}, $new;
	
}

#############################################################################

sub wish_to_schedule_cleanup_for_table_keys {}

#############################################################################

sub wish_to_actually_create_table_keys {	

	my ($items, $options) = @_;
	
	foreach my $i (@$items) {
	
		sql_do ("CREATE INDEX $i->{global_name} ON $options->{table} (@{[ join ', ', @{$i -> {parts}} ]})");
	
	}

	
}

#############################################################################

sub wish_to_actually_alter_table_keys {

	my ($items, $options) = @_;

	foreach my $i (@$items) {
	
		sql_do ("DROP INDEX $i->{global_name}");
	
	}
	
	wish_to_actually_create_table_keys (@_);

}

1;