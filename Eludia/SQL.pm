no warnings;

use Eludia::SQL::TheSqlFunction;

################################################################################

sub lc_hashref {}

################################################################################

sub add_vocabularies {

	my ($item, @items) = @_;

	while (@items) {
	
		my $name = shift @items;
		
		my $options = {};
		
		if (@items > 0 && ref $items [0] eq HASH) {
		
			$options = shift @items;
		
		}
		
		next
			if $options -> {off};
		
		$options -> {item} = $item;
		
		my $table_name = $options -> {name} || $name;
		
		$item -> {$name} = sql_select_vocabulary ($table_name, $options);
		
		if ($options -> {ids}) {
			
			ref $options -> {ids} eq HASH or $options -> {ids} = {table => $options -> {ids}};
			
			$options -> {ids} -> {from}  ||= 'id_' . en_unplural ($_REQUEST {type});
			$options -> {ids} -> {to}    ||= 'id_' . en_unplural ($table_name);
			
			$options -> {ids} -> {name}  ||= $options -> {ids} -> {to};
			
			$_REQUEST {"__checkboxes_$options->{ids}->{to}"} = "$options->{ids}->{table}.$options->{ids}->{from}";
		
			$item -> {$options -> {ids} -> {name}} = [sql_select_col ("SELECT $options->{ids}->{to} FROM $options->{ids}->{table} WHERE fake = 0 AND $options->{ids}->{from} = ?", $item -> {id})];
		
		}
		
	}
	
	return $item;

}

################################################################################

sub sql_weave_model {

	my ($db_model) = @_;

	my @tables = grep {$_ ne $conf -> {systables} -> {log}} map {lc} get_tables ();
		
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
			
			$column_name =~ /^ids?_(.*)/ || $column_name eq 'parent' or next;
			
			my $target2 = $column_name eq 'parent' ? $def -> {name} : $1;
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
		__update_exec_log
		__queries
		__defaults
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

	sql_version ();

	$model_update -> {core_ok} = 1;
			
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

sub sql_ping {

	my $r;

	eval {
	
		my $st = $db -> prepare ('SELECT 1');
		
		$st -> execute;
		
		$r = $st -> fetchrow_arrayref;
	
	};
	
	return @$r == 1 && $r -> [0] == 1 ? 1 : 0;

}

################################################################################

sub sql_reconnect {

	__profile_in ('core.sql.reconnect');

	our $db, $model_update, $SQL_VERSION;

	if ($db && ($preconf -> {no_model_update} || ($model_update && $model_update -> {core_ok}))) {

		if (sql_ping ()) {
		
			unless ($db -> {AutoCommit}) {
				$db -> rollback;
				$db -> {AutoCommit} = 1;
			}
		
			__profile_out ('core.sql.reconnect', {label => 'ping OK'});
		
			return;
		
		}
		
	}
	
	local $ENV {MOD_PERL} = undef;
	local $ENV {GATEWAY_INTERFACE} = undef;
	
	__profile_in ('core.sql.connect', {label => $preconf -> {db_dsn}});
	
	my $d = $preconf -> {db};

	$db = DBI -> connect ($d -> {dsn}, $d -> {user}, $d -> {password}, {
		PrintError  => 0, 
		RaiseError  => 1, 
		AutoCommit  => 1,
		LongReadLen => 1000000,
		LongTruncOk => 1,
		InactiveDestroy => 0,
		mysql_enable_utf8 => 1,
	});
	
	if ($preconf -> {db_cache_statements}) {

		require Eludia::Content::Tie::LRUHash;
		
		my %cache;

		tie %cache, 'Eludia::Content::Tie::LRUHash', {size => 300};

		$db -> {CachedKids} = \%cache;

	}

	__profile_out ('core.sql.connect');

	unless ($INC_FRESH {db_driver}) {

		__profile_in ('core.sql.driver');

		my $driver_name = $db -> get_info ($GetInfoType {SQL_DBMS_NAME});
	
		$driver_name =~ s{\W}{}gsm;

		my $path = __FILE__;
	
		$path =~ s{(.)SQL\.pm$}{${1}SQL$1Dialect$1${driver_name}.pm};

		do $path;
		
		die $@ if $@;

		$INC_FRESH {db_driver} = time;

		$SQL_VERSION = {driver => $driver_name};

		__profile_out ('core.sql.driver', {label => $driver_name});

	}
	
	delete $SQL_VERSION -> {_};
	
	sql_version ();
	
	if (my $f = $conf -> {sql_features}) {
	
		foreach (@$f) {
		
			next if $SQL_VERSION -> {features} -> {$_};
			
			warn ("This application cannot run on $SQL_VERSION->{string}, the missing feature is $_\n");
			
			CORE::exit (1);
		
		}
	
	}

	unless ($preconf -> {no_model_update}) {
		
		if ($model_update) {
		
			$model_update -> {db} = $db;
		
		}
		else {
	
			$model_update = $_NEW_PACKAGE -> new (
				$db, 
				before_assert		=> $conf -> {'db_temporality'} ? \&sql_temporality_callback : undef,
				schema			=> $preconf -> {db_schema},
			);

		}

	}

	__profile_out ('core.sql.reconnect', {label => $SQL_VERSION -> {string}});

}   	

################################################################################

sub sql_disconnect {

	eval { $db -> disconnect };

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
	
	$limit = "LIMIT $options->{limit}" if $options -> {limit};

	$options -> {label} ||= 'label';
	if ($options -> {label} ne 'label') {
		$options -> {label} =~ s/ AS.*//i;
		$options -> {label} .= ' AS label';
	}
	
	$options -> {label} .= ', parent' if $options -> {tree};
	
	my @list;
	
	tie @list, 'Eludia::Tie::Vocabulary', {
	
		sql      => "SELECT id, $$options{label}, fake FROM $table_name WHERE $filter ORDER BY $$options{order} $limit",
		
		params   => \@params,
		
		_REQUEST => \%_REQUEST,
		
		package  => current_package (),
		
		tree     => $options -> {tree},
		
	};
		
	return \@list;
			
}

################################################################################

sub sql_select_id {

	my ($table, $values, @lookup_field_sets) = @_;

	my $result = {};

	my $table_safe = sql_table_name ($table);

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
	
	my $options = ref $lookup_field_sets [-1] eq HASH ? pop @lookup_field_sets : {};
	
	my $record = {};
	
	my $auto_commit = $db -> {AutoCommit};
	
	eval { $db -> {AutoCommit} = 0; };
	
	sql_lock ($table);

	eval {

	foreach my $lookup_fields (@lookup_field_sets) {
	
		if (ref $lookup_fields eq CODE) {		
			next if &$lookup_fields ();
			return 0;		
		}

		my $sql = "SELECT * FROM $table_safe WHERE 1=1";
		
		$forced -> {fake} or $sql .= " AND fake <= 0";
		
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

	unless ($_REQUEST {_no_search_merged_record}) {
		while (my $id = ($record -> {is_merged_to} || $record -> {id_merged_to})) {
			$record = sql_select_hash ($table, $id);
		}
	}

	if ($record -> {id}) {
	
		my @keys   = ();
		my @values = ();

		foreach my $key (keys %$values) {

			($forced -> {$key} && $values -> {$key} ne $record -> {$key}) or $record -> {$key} eq '' or next;

			$result -> {update} -> {$key} = {old => $record -> {$key}, new => $values -> {$key}};

			push @keys,   $key;
			push @values, $values -> {$key};

		}

		if (@keys) {

			sql_do ('UPDATE ' . $table_safe . ' SET ' . (join ', ', map {"$_ = ?"} @keys) . ' WHERE id = ?', @values, $record -> {id});

		}
	
	}
	
	unless ($record -> {id}) {
	
		$record -> {id} = sql_do_insert ($table, $values);
		
		$result -> {insert} = $values;
	
	}

	
	};
	
	warn $@ if $@;

	sql_unlock ($table);
	
	if ($auto_commit) {
	
		eval { 
			$db -> commit;
			$db -> {AutoCommit} = 1; 
		};

	}
	
	return $options -> {show_diff} && wantarray ? ($record -> {id}, $result) : $record -> {id};

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
	
	$table_name ||= $_REQUEST {type};

	return if ($_REQUEST {__delete_fakes} -> {$table_name} ||= is_recyclable ($table_name));

	sql_do ("DELETE FROM $table_name WHERE fake > 0 AND fake NOT IN (SELECT * FROM $conf->{systables}->{sessions})");
	
	$_REQUEST {__delete_fakes} -> {$table_name} = 1;

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
				$value =~ s{\\\'}{\'}gsm; #'
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
	
	sql_do ("UPDATE $table SET fake = -1 WHERE $field = ?", $options -> {id}) unless $_REQUEST {"__$options->{name}_file_no_del"};

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

sub new {

	my ($package_name, $db, @options) = @_;
	
	my $driver_name = $db -> get_info ($GetInfoType {SQL_DBMS_NAME});
	
	$driver_name =~ s{\s}{}gsm;
	
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

		next if $definition -> {columns} -> {id};

		foreach my $dc_name (keys %$default_columns) {

			$definition -> {columns} -> {$dc_name} ||= Storable::dclone $default_columns -> {$dc_name};

		}

	}
	
	return $needed_tables;

}

################################################################################

sub assert {

	my ($self, %params) = @_;

	local $preconf -> {core_debug_sql_do} = 1;
	
	my $tables = sql_assert_default_columns (Storable::dclone ($params {tables}), \%params);
			
	my $objects = [\my @tables, \my @views];

	while (my ($name, $object) = each %$tables) {
	
		next if $object -> {off};
	
		$object -> {name} = $name;

		push @{$objects -> [$object -> {sql} ? 1 : 0]}, $object;

	}
	
	if (@tables > 0) {

		wish (tables => Storable::dclone \@tables, {});
		
		my $col_options = {};
		my $key_options = {};

		foreach my $table (@tables) {
					
			if (exists $table -> {columns}) {

				$col_options -> {table} = $table -> {name};

				wish (table_columns => [map {{name => $_, %{$table -> {columns} -> {$_}}}} (keys %{$table -> {columns}})], $col_options);

			}

			if (exists $table -> {keys}) {

				$key_options -> {table}     = $table -> {name};
				$key_options -> {table_def} = $table;
				
				wish (table_keys => [map {{name => $_, parts => $table -> {keys} -> {$_}}} (keys %{$table -> {keys}})], $key_options);

			}

			if (exists $table -> {data} && ref $table -> {data} eq ARRAY && @{$table -> {data}} > 0) {

				wish (table_data => $table -> {data}, {

					table => $table -> {name},

					key   => exists $table -> {data} -> [0] -> {id} ? 'id' : 'name',

				});

			}

		}
	
	}
	
	if (@views > 0) {

		wish (views => \@views, {});
	
	}

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

sub sql_clone {

	my ($table, $data, %fields) = @_;

	my $clone = {%$data, %fields};

	delete $clone -> {id};

	$clone -> {id} = sql_do_insert ($table => $clone);

	return $clone;

}

#############################################################################

sub require_wish ($) {

	return if $INC_FRESH {"Wish::$_[0]"};
	
	foreach my $key (map {"Eludia/SQL$_/Wish/$_[0].pm"} ('', '/Dialect/' . $SQL_VERSION -> {driver})) {
	
		eval {require $key};
		
		delete $INC {$key};

	}

	$INC_FRESH {"Wish::$_[0]"} = 1;

}

#############################################################################

sub wish {

	my ($type, $items, $options) = @_;

	require_wish $type;

	&{"wish_to_adjust_options_for_$type"} ($options);
		
	foreach my $i (@$items) { &{"wish_to_clarify_demands_for_$type"} ($i, $options) }
	
	my @key = @{$options -> {key}};
	
	my @layers = ();
	
	my %key_cnt = ();
	
	foreach my $i (@$items) {
	
		my $key = join '_', @$i {@key};
		
		$layers [$key_cnt {$key} ++] -> {$key} = $i;
	
	}
	
	my $is_virgin = 1;
	@layers > 0 or @layers = ({});

	foreach my $layer (@layers) {
	
		my $existing = &{"wish_to_explore_existing_$type"} ($options);

		my $todo = {};

		while (my ($key, $new) = each %$layer) {
		
			my $old = delete $existing -> {$key} or (push @{$todo -> {create}}, $new) and next;

			&{"wish_to_update_demands_for_$type"} ($old, $new, $options);

			next if Dumper ($new) eq Dumper ($old);

			&{"wish_to_schedule_modifications_for_$type"} ($old, $new, $todo, $options);		
		
		}	
		
		if ($is_virgin) {
	
			&{"wish_to_schedule_cleanup_for_$type"} ($existing, $todo, $options);
			
			$is_virgin = 0;
		
		}

		foreach my $action (keys %$todo) { &{"wish_to_actually_${action}_${type}"} ($todo -> {$action}, $options) }

	}

}

#############################################################################

sub get_tables {

	my ($self, $table) = @_;

	require_wish 'tables';
		
	return sort keys %{wish_to_explore_existing_tables ()};

}

#############################################################################

sub get_columns {

	my ($self, $table) = @_;

	require_wish 'table_columns';
	
	wish_to_adjust_options_for_table_columns (my $options = {table => $table});
	
	return wish_to_explore_existing_table_columns ($options);

}

#############################################################################

sub get_keys {

	my ($self, $table) = @_;
	
	require_wish 'table_keys';
	
	wish_to_adjust_options_for_table_keys (my $options = {table => $table});
	
	my %keys = ();
		
	foreach my $i (values %{wish_to_explore_existing_table_keys ($options)}) {		
		
		if ($i -> {global_name} =~ /.*?$options->{table}_/i) {
		
			$i -> {global_name} = $';
		
		}
			
		$keys {lc $i -> {global_name}} = join ', ', @{$i -> {parts}}

	}
		
	return \%keys;

}

#############################################################################

sub sql_table_name {$_[0]}

################################################################################

sub sql_do_update {

	my ($table, $data, $id) = @_;
	
	$id ||= delete $data -> {id} or die 'Wrong argument for sql_do_update: ' . Dumper (\@_);
	
	$data -> {fake} //= 0;
	
	my (@q, @p) = ();
	
	while (my ($k, $v) = each %$data) {	
		push @q, $db -> quote_identifier ($k) . " = ?";
		push @p, $v;	
	}
	
	sql_do ("UPDATE " . $db -> quote_identifier ($table) . " SET " . (join ', ', @q) . " WHERE id = ?", @p, $id);

}

################################################################################

sub sql_check_seq {}

1;