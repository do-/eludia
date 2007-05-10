no warnings;

################################################################################

sub sql_weave_model {

	my ($db_model) = @_;

	my @tables = ();
	
	foreach my $table_name ($db -> tables) {	
		$table_name =~ s{\W}{}gsm;
		next if $table_name eq 'log';
		push @tables, $table_name;
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

sub sql_assert_core_tables {

my $time = time;

print STDERR "sql_assert_core_tables [$$] started...\n";

	my $q = $SQL_VERSION -> {quote};

	my %defs = (
	
		_script_checksums => {
		
			columns => {
				name     => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255, _PK => 1},
				ts       => {TYPE_NAME => 'timestamp'},
				checksum => {TYPE_NAME => 'char', COLUMN_SIZE => 22},
			}

		},

		__access_log => {
		
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
		
		__moved_links => {
		
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
		
		__required_files => {
		
			columns => {
				unix_ts   => {TYPE_NAME => 'bigint'},
				file_name => {TYPE_NAME => 'varchar', COLUMN_SIZE  => 255},
			},
			
			keys => {
				ix => 'file_name',
			},

		},

		__last_update => {
		
			columns => {
				pid 	  => {TYPE_NAME => 'int'},
				unix_ts   => {TYPE_NAME => 'bigint'},
			},
			
		},

		sessions => {
		
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

		roles => {

			columns => {
				id   => {TYPE_NAME  => 'int', _EXTRA => 'auto_increment', _PK => 1},
				fake => {TYPE_NAME  => 'bigint', COLUMN_DEF => 0, NULLABLE => 0},
				name  => {TYPE_NAME    => 'varchar', COLUMN_SIZE  => 255},
				label => {TYPE_NAME    => 'varchar', COLUMN_SIZE  => 255},
			},

		},

		users => {

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

		log => {

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
				params => {TYPE_NAME => 'text'},
				dt     => {TYPE_NAME => 'timestamp'},
				mac    => {TYPE_NAME  => 'varchar', COLUMN_SIZE => 17},
			}

		},	
	
	);
	
	$conf -> {core_cache_html} and $defs {cache_html} = {
		columns => {
			uri     => {TYPE_NAME  => 'varchar', COLUMN_SIZE  => 255, _PK    => 1},
			ts      => {TYPE_NAME  => 'timestamp'},
		}
	};
	
	$preconf -> {core_debug_profiling} == 2 and $defs {"__benchmarks"} = {

		columns => {
			id       => {TYPE_NAME  => 'int'    , _EXTRA => 'auto_increment', _PK => 1},
			fake     => {TYPE_NAME  => 'bigint' , COLUMN_DEF => 0, NULLABLE => 0},
			label    => {TYPE_NAME  => 'varchar', COLUMN_SIZE  => 255},
			cnt      => {TYPE_NAME  => 'bigint' , COLUMN_DEF => 0, NULLABLE => 0},
			ms       => {TYPE_NAME  => 'bigint' , COLUMN_DEF => 0, NULLABLE => 0},
			mean     => {TYPE_NAME  => 'bigint' , COLUMN_DEF => 0, NULLABLE => 0},
			selected => {TYPE_NAME  => 'bigint' , COLUMN_DEF => 0, NULLABLE => 0},
			mean     => {TYPE_NAME  => 'bigint' , COLUMN_DEF => 0, NULLABLE => 0},
			mean_selected => {TYPE_NAME  => 'bigint' , COLUMN_DEF => 0, NULLABLE => 0},
		},
		
		keys => {
			label => 'label',
		},
		
	};

	$conf -> {core_screenshot} and $defs {__screenshots} = {
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

	$model_update -> assert (tables => \%defs);
	
	$model_update -> {core_ok} = 1;
	
	sql_select_scalar ("SELECT unix_ts FROM ${q}__last_update${q}") or sql_do ("INSERT INTO ${q}__last_update${q} (unix_ts, pid) VALUES (?, ?)", time (), $$);
		
print STDERR "sql_assert_core_tables [$$] finished:" . (time - $time) . " ms\n";	
	
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


	if ($db && $model_update && $model_update -> {core_ok}) {
		my $ping = $db -> ping;
		return if $ping;
	}
	
	$conf = {%$conf, %$preconf};

#   	$conf -> {dbf_dsn} and our $dbf = DBI -> connect ($conf -> {dbf_dsn}, {RaiseError => 1});

	our $db  = DBI -> connect ($conf -> {'db_dsn'}, $conf -> {'db_user'}, $conf -> {'db_password'}, {
		RaiseError  => 1, 
		AutoCommit  => 1,
		LongReadLen => 100000000,
		LongTruncOk => 1,
		InactiveDestroy => 0,
	});

	my $driver_name = $db -> get_info ($GetInfoType {SQL_DBMS_NAME});

	eval "require Eludia::SQL::$driver_name";

	print STDERR $@ if $@;
	
	our $SQL_VERSION = sql_version ();
	$SQL_VERSION -> {driver} = $driver_name;
	$SQL_VERSION -> {quote} = $db -> get_info ($GetInfoType {SQL_IDENTIFIER_QUOTE_CHAR});

	delete $INC {"Eludia/SQL/${driver_name}.pm"};

	unless ($preconf -> {no_model_update}) {
	
		our $model_update = DBIx::ModelUpdate -> new (		
			$db, 
			dump_to_stderr => 1,
			before_assert	=> $conf -> {'db_temporality'} ? \&sql_temporality_callback : undef,
			schema			=> $preconf -> {db_schema},
		);

		sql_assert_core_tables (); # unless $driver_name eq 'Oracle';
		
		$preconf -> {no_model_update} = 1;
		
	}
		
	our %sts = ();

}   	

################################################################################

sub sql_disconnect {
	if ($db) { $db -> disconnect; }
	undef $db;
	undef %sts;	
}

################################################################################

sub sql_select_vocabulary {

	my ($table_name, $options) = @_;	
	
	$options -> {order} ||= 'label';
	
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

	if ($preconf -> {subset} && $table_name eq 'roles') {
		
		$filter .= " AND name IN ('-1'";
		
		foreach my $name (keys %{$preconf -> {subset_names}}) {			
			$filter .= ", '";
			$filter .= $name;
			$filter .= "'";
		}
		
		$filter .= ")";
		
	}
	
	$limit = "LIMIT $options->{limit}" if $options -> {limit};
	
	return sql_select_all ("SELECT id, label FROM $table_name WHERE $filter ORDER BY $$options{order} $limit");
	
}

################################################################################

sub sql_select_ids {
	my ($sql, @params) = @_;
	my @ids = grep {$_ > 0} sql_select_col ($sql, @params);
	push @ids, -1;
	return join ',', @ids;
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

	my ($table_name, $old_ids, $new_id) = @_;
	
	sql_weave_model ($DB_MODEL);

#warn Dumper ($DB_MODEL -> {aliases} -> {$table_name});
	
	ref $old_ids eq ARRAY or $old_ids = [$old_ids];
	
	my $column_name = '';
	$column_name = 'is_merged_to' if $DB_MODEL -> {tables} -> {$table_name} -> {columns} -> {is_merged_to};
	$column_name = 'id_merged_to' if $DB_MODEL -> {tables} -> {$table_name} -> {columns} -> {id_merged_to};
	
	my $record = sql_select_hash ($table_name, $new_id);
	my @empty_fields = ();
	foreach my $key (keys %$record) {
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
					INSERT INTO $SQL_VERSION->{quote}__moved_links$SQL_VERSION->{quote}
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
					INSERT INTO $SQL_VERSION->{quote}__moved_links$SQL_VERSION->{quote}
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
			
warn Dumper ($DB_MODEL -> {tables} -> {$table_name});
warn Dumper ($DB_MODEL -> {tables} -> {$table_name} -> {references});

	foreach my $old_id (@$old_ids) {
	
warn "undo relink $table_name: $old_id";

		my $record = sql_select_hash ($table_name, $old_id);
		
		foreach my $column_def (@{$DB_MODEL -> {tables} -> {$table_name} -> {references}}) {

			my $from = <<EOS;
				FROM
					__moved_links
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
				$old_id = $old_id . ',';
				sql_do ("UPDATE $$column_def{table_name} SET $$column_def{name} = CONCAT($$column_def{name}, ?) WHERE id IN ($ids)", $old_id);
			}

		}
		
	}
	
	delete $DB_MODEL -> {aliases};
	
}

################################################################################

sub assert_fake_key {

	$DB_MODEL or return;
	
	my ($table_name) = @_;

	return if $DB_MODEL -> {tables} -> {$table_name} -> {keys} -> {fake};
	
	$model_update -> assert (tables => {
	
		$table_name => {
			keys => {fake => 'fake'},
		}
	
	});

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
			LEFT JOIN sessions ON $table_name.fake = sessions.id
		WHERE
			$table_name.fake > 0
			AND sessions.id_user IS NULL
EOS
			
	sql_do ("DELETE FROM $table_name WHERE id IN ($ids)");

}

################################################################################
	
sub sql_select_loop {

	my ($sql, $coderef, @params) = @_;
	$sql =~ s{^\s+}{};
	
	my $st = $db -> prepare ($sql);
	$st -> execute (@params);
	
	our $i;
	while ($i = $st -> fetchrow_hashref) {
		&$coderef ();
	}
	
	$st -> finish ();

}

1;