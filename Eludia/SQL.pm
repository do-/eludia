no warnings;

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
				
				core_voc_replacement_use => $conf -> {core_voc_replacement_use}
				
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
			core_voc_replacement_use => $conf -> {core_voc_replacement_use}
		);
	
	}

$time = __log_profilinig ($time, ' <sql_assert_core_tables>: 136');

	my %defs = (
	
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

	$model_update -> assert (tables => \%defs, core_voc_replacement_use => $conf -> {core_voc_replacement_use});

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
	
	$driver_name =~ s{\W}{}gsm;

	eval "require Eludia::SQL::$driver_name";

	die $@ if $@;
	
	our $SQL_VERSION = sql_version ();
	$SQL_VERSION -> {driver} = $driver_name;

	delete $INC {"Eludia/SQL/${driver_name}.pm"};

$time = __log_profilinig ($time, '  sql_reconnect: driver reloaded');

	unless ($preconf -> {no_model_update}) {
	
		our $model_update = DBIx::ModelUpdate -> new (		
			$db, 
			dump_to_stderr 		=> 1,
			before_assert		=> $conf -> {'db_temporality'} ? \&sql_temporality_callback : undef,
			schema			=> $preconf -> {db_schema},
			_db_model_checksums	=> $conf -> {systables} -> {_db_model_checksums}, 
			__voc_replacements	=> $conf -> {systables} -> {__voc_replacements}, 
			core_voc_replacement_use=> $conf -> {core_voc_replacement_use},
		);

#		$preconf -> {no_model_update} = 1;
		
	}

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

	tie @list, 'Eludia::Vocabulary', {
	
		sql => "SELECT id, $$options{label} FROM $table_name WHERE $filter ORDER BY $$options{order} $limit",
		
		_REQUEST => \%_REQUEST,
		
		package => __PACKAGE__,
		
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
	
	foreach my $lookup_fields (@lookup_field_sets) {

		my $sql = "SELECT * FROM $table WHERE fake <= 0";
		my @params = ();

		foreach my $lookup_field (@$lookup_fields) {
			$sql .= " AND $lookup_field = ?";
			push @params, $values -> {$lookup_field};
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

	return $record -> {id} || sql_do_insert ($table, $values);

}

################################################################################

sub sql_do_relink {

	my ($table_name, $old_ids, $new_id, $options) = @_;
	
	sql_weave_model ($DB_MODEL);

#warn Dumper ($DB_MODEL -> {aliases} -> {$table_name});
	
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
		
#warn Dumper ($DB_MODEL -> {tables} -> {$table_name});
#warn Dumper ($DB_MODEL -> {tables} -> {$table_name} -> {references});

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
					INSERT INTO $conf->{systables}->{__moved_links}
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
					INSERT INTO $conf->{systables}->{__moved_links}}
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
			
	foreach my $old_id (@$old_ids) {
		
		$old_id > 0 or next;

warn "undo relink $table_name: $old_id";

		my $record = sql_select_hash ($table_name, $old_id);
		
		foreach my $column_def (@{$DB_MODEL -> {aliases} -> {$table_name} -> {references}}) {

			my $from = <<EOS;
				FROM
					$conf->{systables}->{__moved_links}
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

	$DB_MODEL -> {tables} -> {$table_name} or return;
	
	my ($table_name) = @_;

	return if $DB_MODEL -> {tables} -> {$table_name} -> {keys} -> {fake};
	
	$model_update -> assert (tables => {
	
		$table_name => {
			keys => {fake => 'fake'},
		},
	
	},core_voc_replacement_use => $conf -> {core_voc_replacement_use});

}

################################################################################

sub delete_fakes {
	
	my ($table_name) = @_;
	
	$table_name    ||= $_REQUEST {type};

	return if is_recyclable ($table_name);
	
	assert_fake_key ($table_name,core_voc_replacement_use => $conf -> {core_voc_replacement_use});
	
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

	return 
		unless ($preconf -> {core_debug_profiling} > 2 && $model_update -> {core_ok});
		
	my $c = $r -> connection; 

	$_REQUEST {_id_request_log} = sql_do_insert ($conf -> {systables} -> {__request_benchmarks}, {
		id_user	=> $_USER -> {id}, 
		ip	=> $ENV {REMOTE_ADDR}, 
		ip_fw	=> $ENV {HTTP_X_FORWARDED_FOR},
		fake	=> 0,
		type	=> $_REQUEST {type},
		mac	=> (!$preconf -> {core_no_log_mac}) ? get_mac () : '',
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

sub sql {

	my ($root, @other) = @_;

	my $select = "SELECT\n $root.*";
	my $from   = "\nFROM\n $root";
	my $where  = "\nWHERE\n 1=1";
	my $order  = [$root . '.label'];
	my $limit;
	my @params = ();

	if (@other == 0) {								# sql ('users')   --> sql ('users' => ['id'])
	
		@other = (['id']);
	
	}

	if (!ref $other [0]) {
	
		$other [0] = [id => $other [0]];					# sql (users => 1) --> sql ('users' => ['id' => 1])
	
	}
		
	my ($filters, @tables) = @other;
	
	my $have_id_filter = 0;
		
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
			next;
		}

		ref $values or $values = [$values];
		
		next if $values -> [0] eq '' or $values -> [0] eq '0';
		
		$have_id_filter = 1 if $field eq 'id';

		$field =~ /\w / or $field =~ /\=/ or $field .= ' = ';			# 'id_org'       --> 'id_org = '
		$field =~ /\?/  or $field .= ' ? '; 					# 'id_org LIKE ' --> 'id_org LIKE ?'
		
		$field =~ s{([a-z][a-z0-9_]*)}{$root.$1}gsm;
			
		if ($field =~ / IN$/) {							# ['id_org IN' => [0, undef, 1]] => "users.id_org IN (-1, 1)"
			
			$where .= "\n  AND ($field (-1, ";
				
			foreach (grep {$_} @$values) { $where .= ", $_"}
								
			$where .= " ))";
			
		}
		else {

			$where .= "\n AND ($field)";
			push @params, @$values;
				
		}
			
	
	}
	
	my $default_columns = '*';
	
	unless ($have_id_filter) {
		
		$default_columns = 'id, label';
		
		$_REQUEST {fake} ||= '0';
		
		$where .= $_REQUEST {fake} =~ /\,/ ? "\n AND $root.fake IN ($_REQUEST{fake})" : "\n AND $root.fake = $_REQUEST{fake}";

	}	
	
	foreach my $table (@tables) {

		$table =~ s{\s}{}gsm;

		$table =~ /(\w+)(?:\((.*?)\))?/ or die "Invalid table definition: '$table'\n";

		my ($name, $columns) = ($1, $2);

		$name =~ /^(\w+?)s?$/;
		
		$table = {
		
			src     => $table,
			name    => $name,
			columns => $columns,
			single  => $1,
			
		}

	}	
		
	foreach my $table (@tables) {
			
		my $referrer;
		
		my $referring_field_name = 'id_' . $table -> {single};
		
		my $found = 0;
		
		foreach my $t ({name => $root}, @tables) {
				
			$DB_MODEL -> {tables} -> {$t -> {name}} -> {columns} -> {$referring_field_name} or next;
			
			$from .= "\n LEFT JOIN $table->{name} ON $t->{name}.$referring_field_name = $table->{name}.id";
			
			$found = 1;
			
			last;
		
		}		
		
		$found or die "Referrer $referring_field_name not found\n";

		$table -> {columns} ||= $default_columns;
		
		my @columns = ();
		
		if ($columns eq '*') {
		
			@columns = (id, @{$DB_MODEL -> {tables} -> {$table -> {name}} -> {columns}});
		
		}
		else {
		
			@columns = split /\s*\,\s*/, $table -> {columns};
		
		}
		
		foreach my $column (@columns) {
		
			$select .= "\n, $table->{name}.$column AS $model_update->{quote}$table->{name}.$column$model_update->{quote}"
		
		}
			
	}
	
	my $sql = $select . $from . $where;
	
	unless ($have_id_filter) {
	
		$sql .= "\nORDER BY\n ";
		$sql .= order (@$order);

	}
	
	my @result;
	my $records;
	
	if ($have_id_filter || ($limit && @$limit == 1 && $limit -> [0] == 1)) {

		@result = (sql_select_hash ($sql, @params));

		$records = [$result [0]];

	}
	else {
	
		if ($limit) {
		
			$sql .= "\nLIMIT\n " . (join ', ', @$limit);
			
			@result = (sql_select_all_cnt ($sql, @params));
	
			$records = $result [0];
	
		}
		else {

			@result = (sql_select_all ($sql, @params));
	
			$records = $result [0];
		
		}
	
	}	
	
	foreach my $record (@$records) {
		
		foreach my $key (keys %$record) {			
		
			$key =~ /(\w+?)s?\.(\w+)/ or next;						
						
			$record -> {$1} -> {$2} = delete $record -> {$key};
					
		}
	
	}
	
	return wantarray ? @result : $result [0];

}


1;