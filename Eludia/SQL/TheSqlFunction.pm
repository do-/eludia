################################################################################

sub _sql_list_fields {

	my ($src, $table, $table_alias) = @_;
	
	$table_alias ||= $table; 
	
	my @fields = ();

	$src = '*' if $src eq '';
	
	if ($src eq '*') {
	
		my $def = $DB_MODEL -> {tables} -> {$table};
		
		$def and $def -> {columns} or return ();
				
		my %h = ();
		
		$h {$_} ||= 1 foreach keys %{$DB_MODEL -> {default_columns}};

		my $c = $def -> {columns};

		$h {$_} ||= 1 foreach grep {$c -> {$_} -> {TYPE_NAME} ne 'blob'} keys %$c;
					
		return map {{
			src   => "$table_alias.$_", 
			alias => $_,
			table => $table,
		}} keys %h;
		
	}	
	
	my $buffer   = '';
	my $level    = 0;
	my $is_group = 0;
		
	foreach my $token ("$src," =~ m((
	
		'.*?(?:(?:''){1,}'|(?<!['\\])'(?!')|\\'{2})

		| \s+

		| [\(\,\)]

		| [a-z][a-z_\d]*\.[a-z][a-z_\d]*

		| [a-z][a-z_\d]*
		
		| [^\s\(\,\)]+
		
	))gsmx) {

		if ($token =~ /^[\'\s]/) {

			$buffer .= $token;            next;
		
		}

		if ($token eq '(') {

			$buffer .= $token; $level ++; next;
		
		}

		if ($token eq ')') {

			$buffer .= $token; $level --; next;
		
		}
		
		if ($token =~ /^[a-z][a-z_\d]*$/) {

			$buffer .= "$table_alias.$token";   next;

		}

		if ($token eq ',' && !$level) {
		
			my $alias = '';
			
			if ($buffer =~ /^\s*\w+\.(\w+)\s*$/sm) {
			
				$alias  = $1;
			
			}
			elsif ($buffer =~ /\s+AS\s+\w+\.(\w+)\s*$/sm) {
			
				$alias  = $1;
				$buffer = $`;
			
			}
			
			$buffer =~ s{^\s+}{}sm;
			
			$alias ||= join '_', map {lc} ($buffer =~ /\w+/g);
			
			push @fields, {
				src      => $buffer,
				alias    => $alias,
				is_group => $is_group,
				table    => $table,
			};
			
			$buffer   = '';
			$is_group = 0;
			
			next;
		
		}

		if (1) {

			$is_group ||= 1 if $token =~ /^(AVG|COUNT|GROUP_CONCAT|MAX|MIN|STDEV|SUM)$/;
			$buffer    .= $token;            next;

		}

	}

	return @fields;

}

################################################################################

sub _sql_filters {

	my ($root, $filters) = @_;

	my $have_id_filter = 0;
	my $cnt_filters    = 0;
	my $where          = '';
	my $having         = '';
	my $order;
	my $limit;
	my @where_params   = ();
	my @having_params  = ();

	foreach my $filter (@$filters) {

		if (ref $filter eq ARRAY and @$filter == 1 and $filter -> [0] =~ /^-?1\s/) {
		
			$filter = [LIMIT => [$filter -> [0]]];
			
		}

		ref $filter or $filter = [$filter, $_REQUEST {$filter}];

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
		
		my $was_array = ref $values eq ARRAY or $values = [$values];

		my $first_value = $values -> [0];

		my $tied;

		if (ref $first_value eq SCALAR) {

			$tied = tied $$first_value;

		}

		unless ($tied) {

			next if $first_value eq '' or $first_value eq '0000-00-00';

		}
		
		if (($tied or $was_array) && $field =~ /^([a-z][a-z0-9_]*)$/) {
		
			$field .= ' IN';
		
		}

		$cnt_filters ++;

		$have_id_filter = 1 if $field eq 'id';
		
		my @fields = _sql_list_fields ($field, $root);
		
		@fields == 1 or die "Incorrect filtering expression for $root: '$field'\n";
		
		$field     = $fields [0] -> {src};
		
		my ($buffer, $params) = $fields [0] -> {is_group} ? 
			(\$having, \@having_params) : 
			(\$where,  \@where_params ) ;

		if ($field =~ /\s+IN\s*$/sm) {

											# ['id_org IN' => sql_select_ids (...)] => "users.id_org IN (SELECT ...)"
											# ['id_org IN' => sql ('orgs(id)' => [[id_kind => 1]])] => "users.id_org IN (SELECT ...)"

			if ($tied) {							

				if (_sql_ok_subselects ()) {

					$$buffer .= "\n  AND ($field ($tied->{sql}))";

					push @$params, @{$tied -> {params}};

				}
				else {

					$$buffer .= "\n  AND ($field ($$first_value))";

				}

			}
			else {								# ['id_org IN' => [0, undef, 1]] => "users.id_org IN (-1, 1)"

				$$buffer .= "\n  AND ($field (-1";

				foreach (grep {/\d/} @$values) { $where .= ", $_"}

				$$buffer .= "))";

			}

		}
		else {

			$field =~ /^\s*[a-z]\w*(\.[a-z]\w*)\s*$/ and $field .= ' = ';		# 'id_org'           --> 'id_org = '
			$field =~ /\?/  or $field .= ' ? '; 				# 'id_org LIKE '     --> 'id_org LIKE ?'

			if ($field =~ s{\<\+}{\<}) {					# 'dt <+ 2008-09-30' --> 'dt < 2008-10-01'
				my @ymd = split /\-/, $first_value;				
				$values -> [0] = dt_iso (Date::Calc::Add_Delta_Days (@ymd, 1));
			}
			
			my @tokens = split /(LIKE\s+\%?\?\%)/, $field;
			
			$$buffer .= "\n AND (";
			
			foreach my $token (@tokens) {
			
				if ($token =~ /LIKE\s+(\%?)\?(\%)/) {

					$$buffer .= ' LIKE ?';
					my $v = shift @$values;
					push @$params, "$1$v$2";

				}
				else {
				
					$$buffer .= $token;
					
					foreach (1 .. $token =~ y/?/?/) {
					
						push @$params, shift @$values;
					
					}
				
				}
			
			}			

			$$buffer .= ")";

		}


	}
	
	if (ref $limit eq ARRAY) {
	
		if (@$limit == 1 && $limit -> [0] =~ /^(.+?)\s*\,\s*(.+)$/) {
		
			$limit = [$1, $2];
		
		}
		
		if ($limit -> [0] =~ /^[a-z]\w*$/) {
		
			$limit -> [0] = 0 + $_REQUEST {$limit -> [0]};
		
		}
	
		if ($limit -> [-1] =~ s{\s+BY\s+(.*)}{}) {
		
			$order = $1;
		
		}
		
		if ($limit -> [-1] < 0) {
		
			$limit -> [-1] *= -1;
			
			$order .= ' DESC';
		
		}

	}
	
	return {
		have_id_filter => $have_id_filter,
		cnt_filters    => $cnt_filters,
		order          => $order,
		limit          => $limit,
		where          => $where,
		having         => $having,
		where_params   => \@where_params,
		having_params  => \@having_params,
	};

}

################################################################################

sub _sql_unwrap_record {

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
	
	$root_table =~ /^\w+/ or die "Invalid table definition: '$root_table'\n";

	my $root = $&;
	
	my $tail = $' || "(*)";
		
	$tail =~ /^\s*\((.*?)\)\s*$/ or die "Invalid table definition: '$root_table'\n";	
	
	my @columns = _sql_list_fields ($1, $root);
	
	my $from   = "\nFROM\n $root";
	my $where  = "\nWHERE  1=1";
	my $having = "\nHAVING 1=1";
	my $order;
	my $limit;
	my @join_params   = ();
	my @where_params  = ();
	my @having_params = ();

	if (@other == 0) {								# sql ('users')   --> sql ('users' => ['id'])
	
		@other = (['id']);
	
	}

	if (!ref $other [0]) {
	
		$other [0] = [[id => $other [0]]];					# sql (users => 1) --> sql ('users' => ['id' => 1])
	
	}
		
	my ($filters, @tables) = @other;
	
	my $sql_filters = _sql_filters ($root, $filters);
	
	$where        .= $sql_filters -> {where};
	@where_params  = @{$sql_filters -> {where_params}};
	
	$having       .= $sql_filters -> {having};
	@having_params = @{$sql_filters -> {having_params}};
	
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
		
		my $on = '';

		if ($table =~ /\s+ON\s+/) {

			$table = $`;
			$on    = $';

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
		
		if ($on && $on !~ /\s/) {
		
			$on = "$on = $alias.id";
		
		}

		$table = {
		
			src     => $table,
			name    => $name,
			columns => $columns,
			single  => en_unplural ($alias),
			alias   => $alias,
			on      => $on,
			filters => $filters,
			join    => $minus ? 'INNER JOIN' : 'LEFT JOIN',
			
		};
		
		$table -> {single} =~ s{ie$}{y};

	}	
	
	my @cols = ();
	my $cols_cnt = 0;	
			
	foreach my $table (@tables) {

		my $found = 0;
		
		if ($table -> {on}) {
		
			$from .= "\n $table->{join} $table->{name}";
			$from .= " AS $table->{alias}" if $table -> {name} ne $table -> {alias};
			$from .= " ON ($table->{on})";
				
			$found = 1;
		
		}
		
		if (!$found && $table -> {filters}) {
		
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

				my $sql_filters = _sql_filters ($table -> {alias}, $table -> {filters});

				$from .= "\n $table->{join} $table->{name}";
				$from .= " AS $table->{alias}" if $table -> {name} ne $table -> {alias};
				$from .= " ON ($table->{alias}.$referring_field_name = $t->{name}.id $sql_filters->{where})";
				
				push @join_params, @{$sql_filters -> {where_params}};
				
				if ($sql_filters -> {having_params}) {
					
					$having .= $sql_filters -> {having};
					push @having_params, @{$sql_filters -> {having_params}};
				
				}

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
					my $sql_filters = _sql_filters ($table -> {alias}, $table -> {filters});
					$from .= " ON ($t->{alias}.$referring_field_name = $table->{alias}.id $sql_filters->{where})";
					push @join_params, @{$sql_filters -> {where_params}};
					
					if ($sql_filters -> {having_params}) {

						$having .= $sql_filters -> {having};
						push @having_params, @{$sql_filters -> {having_params}};

					}
					
				}
				else {
					$from .= " ON $t->{alias}.$referring_field_name = $table->{alias}.id";
				}

				$found = 1;

				last;

			}		

		}		

		$found or die "Referrer for $table->{alias} not found\n";
				
		foreach my $column (_sql_list_fields (($table -> {columns} || $default_columns), $table -> {name}, $table -> {alias})) {

			$cols [$cols_cnt] = [en_unplural ($table -> {alias}), $column -> {alias}];

			$column -> {alias} = "gfcrelf$cols_cnt";

			push @columns, $column;

			$cols_cnt ++;

		}
			
	}
	
	my $columns_by_grouping = [[], []];

	foreach my $column (@columns) {

		push @{$columns_by_grouping -> [$column -> {is_group}]}, $column;
	
	}

	my $is_first = $limit && @$limit == 1 && $limit -> [0] == 1;
	
	my $is_ids = @{$columns_by_grouping -> [0]} == 1 && @{$columns_by_grouping -> [1]} == 0 ? 1 : 0;
	
	my $is_only_grouping = @{$columns_by_grouping -> [0]} == 0 ? 1 : 0;

	my $is_only_grouping_1 = $is_only_grouping && @{$columns_by_grouping -> [1]} == 1 ? 1 : 0;

	!$is_ids or $cnt_filters or $is_first or return undef;

	my @params = (@join_params, @where_params, @having_params);

	my $sql = "SELECT\n "
	
		. (join "\n, ", 
		
			map {"$_->{src} AS $_->{alias}"} (
				@{$columns_by_grouping -> [0]}, 
				@{$columns_by_grouping -> [1]},
			)
		)
		
		. $from
		
		. $where
		
	;
	
	if (@{$columns_by_grouping -> [1]} > 0 && @{$columns_by_grouping -> [0]} > 0) {
	
		my $grouping_fields = join "\n ,", map {"$_->{src}"} @{$columns_by_grouping -> [0]};
		
		$order ||= $grouping_fields;
		
		$sql .= "\nGROUP BY\n $grouping_fields";
	
	}

	if (@having_params > 0) {
			
		$sql .= $having;
	
	}

	if ((!$have_id_filter && !$is_ids && !$is_only_grouping) || $is_first) {
		
		$order ||= [$root . ($DB_MODEL -> {tables} -> {$root} -> {columns} -> {label} ? '.label' : '.id')];
			
		$order = order (@$order) if ref $order eq ARRAY;

		$order = order ($order)  if $order !~ /\W/;
		
		$order =~ s{(?<!\.)\b([a-z][a-z0-9_]*)\b(?!\.)}{${root}.$1}gsm;
		
		$sql .= "\nORDER BY\n $order";

	}
	
	my @result;
	my $records;
	
	if ($preconf -> {core_debug_sql}) {
	
		warn Dumper ({args => $_args, sql => $sql, params => \@params});
	
	}
	
	if ($have_id_filter || $is_first || $is_only_grouping_1) {
	
		return sql_select_scalar ($sql, @params) if $is_ids || $is_only_grouping_1;

		@result = (sql_select_hash ($sql, @params));

		$records = [$result [0]];

	}
	elsif ($sub) {
	
		return sql_select_loop (
			
			$sql, 
			
			sub {
			
				_sql_unwrap_record ($i, \@cols);
				
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
							
				$sql =~ s{^SELECT}{SELECT DISTINCT};

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
	
		_sql_unwrap_record ($record, \@cols);
	
	}
	
	return wantarray ? @result : $result [0];

}

1;