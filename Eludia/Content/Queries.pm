
################################################################################

sub setup_page_content {

	my ($page) = @_;

	$_REQUEST {__allow_check___query} = 1;
	delete $_REQUEST {__the_table};

	our @_COLUMNS = ();
	our %_ORDER = ();
	our $_QUERY = undef;

	eval { $_REQUEST {__page_content} = $page -> {content} = call_for_role (($_REQUEST {id} ? 'get_item_of_' : 'select_') . $page -> {type})};

	$@ and return $_REQUEST {error} = $@;

# Call it unless content function does'nt called order () or sql ()
	check___query ()
		unless $_QUERY;

	$_REQUEST {__allow_check___query} = 0;

	$@ and return $_REQUEST {error} = $@;

	$_USER -> {id} and !$_REQUEST {__only_menu} and $_REQUEST {__edit_query} or return;

	my $is_dump = delete $_REQUEST {__dump};

	setup_skin ();

	$_REQUEST {__allow_check___query} = 1;

	call_for_role (($_REQUEST {id} ? 'draw_item_of_' : 'draw_') . $page -> {type}, $page -> {content});

	$_REQUEST {__allow_check___query} = 0;

	$_REQUEST {__dump} = $is_dump;

	$_REQUEST {id___query} ||= sql_select_id (

		$conf -> {systables} -> {__queries} => {
			id_user       => $_USER -> {id},
			type          => $_REQUEST {type},
			label         => '',
			order_context => $_REQUEST {__order_context} || '',
		}, ['id_user', 'type', 'label', 'order_context'],

	);

	require_both ('__queries');

	$_REQUEST {__allow_check___query} = 1;

	check___query ();

	$_REQUEST {__allow_check___query} = 0;

	$_REQUEST {type} = $page -> {type} = '__queries';

	$_REQUEST {id}   = $_REQUEST {id___query};

	eval { $_REQUEST {__page_content} = $page -> {content} = call_for_role ('get_item_of___queries', $page -> {content}) };

	$@ and return $_REQUEST {error} = $@;

	delete $_REQUEST {__skin};

}

################################################################################

sub fix___query {

	my ($id_table) = @_;

	$conf -> {core_store_table_order} or return;

	$_REQUEST {__order_context} ||= '';

	@_COLUMNS > 0 or return;

	if ($_REQUEST {id___query}) {

		foreach my $key (keys %{$_QUERY -> {content} -> {columns}}) {
			next if $_QUERY -> {content} -> {columns} -> {$key} -> {no_hidden} != 1;
			unless ($key ~~ [map {$_ -> {id}} @_COLUMNS]) {
				$_QUERY -> {content} -> {columns} -> {$key} -> {order} = $key;
				$_QUERY -> {content} -> {columns} -> {$key} -> {hidden} = 1;
				push @_COLUMNS, $_QUERY -> {content} -> {columns} -> {$key};
			}
		}

		my $columns = delete $_QUERY -> {content} -> {columns};

		foreach my $o (@_COLUMNS) {

			next unless ($o -> {order} || $o -> {no_order});

			$_QUERY -> {content} -> {columns} -> {$o -> {order} || $o -> {no_order}} = {
				ord       => $o -> {ord},
				id        => $columns -> {$o -> {order} || $o -> {no_order}} -> {id},
				width     => $columns -> {$o -> {order} || $o -> {no_order}} -> {width},
				height    => $columns -> {$o -> {order} || $o -> {no_order}} -> {height},
				sort      => $columns -> {$o -> {order} || $o -> {no_order}} -> {sort},
				desc      => $columns -> {$o -> {order} || $o -> {no_order}} -> {desc},
				no_hidden => $o -> {no_hidden},
			} ;

			foreach my $filter (@{$o -> {filters}}) {

				$_QUERY -> {content} -> {filters} -> {$filter -> {name}} = $_REQUEST {$filter -> {name}};

			}

		}

		keys %{$_QUERY -> {content} -> {columns}} or return;

		my $id___query = $_REQUEST {id___query};

		set_dump_if_need__query ($_QUERY -> {content}, $id_table);

		!$id___query or $_REQUEST {id___query} == $id___query
			or set___query ($_REQUEST {id___query}, {parent => $id___query});

	} else {

		my $content = {filters => {}, columns => {}};

		my %n;
		my $is_exist_default_ords = 0 + grep {defined $_ -> {ord} || $_ -> {ord_fixed}} @_COLUMNS;

		foreach my $o (@_COLUMNS) {

			next unless ($o -> {order} || $o -> {no_order} || $o -> {parent_header} -> {order} || $o -> {parent_header} -> {no_order});

			my $parent = exists $o -> {parent_header} ? ($o -> {parent_header} -> {order} || $o -> {parent_header} -> {no_order}) : '';
			$content -> {columns} -> {$o -> {order} || $o -> {no_order}} = {
				ord       => $is_exist_default_ords ? 0 + $o -> {ord} : ++ $n {$parent},
				width     => $o -> {width},
				height    => $o -> {height},
				sort      => $o -> {sort},
				desc      => $o -> {desc},
				no_hidden => $o -> {no_hidden},
			};

			foreach my $filter (@{$o -> {filters}}) {

				$content -> {filters} -> {$filter -> {name}} = $_REQUEST {$filter -> {name}};

			}

		}

		set_dump_if_need__query ($content, $id_table);

	}

}

################################################################################

sub set_dump_if_need__query {

	my ($content, $id_table) = @_;

	my $dump = Dumper ($content);

	my $query = get___query (0, $id_table);

	if ($query -> {id}) {

		$_REQUEST {id___query} = $query -> {id};

		if ($dump ne $query -> {dump}) {

			set___query ($_REQUEST {id___query}, {dump => $dump});

		}

	} else {

		$_REQUEST {id___query} = sql_do_insert (

			$conf -> {systables} -> {__queries} => {

				fake          => 0,
				id_user       => $_USER -> {id},
				type          => $_REQUEST {type},
				dump          => $dump,
				label         => '',
				order_context => $_REQUEST {__order_context},
				id_table      => $id_table,

			}

		);

	}

}

################################################################################

sub check___query {

	my ($id_table) = @_;

	return if $_QUERY;

	$_REQUEST {__allow_check___query} or return;

	$conf -> {core_store_table_order} or return;
# Don't setup wrong $_REQUEST {__the_table} in sql_select_hash
	local $_REQUEST {__the_table} = $_REQUEST {__the_table};

	$_REQUEST {__order_context} ||= $_REQUEST {id} ? 'id' : '';

	if ($_REQUEST {id___query} == -1) {

		if ($SQL_VERSION -> {driver} eq 'Oracle') {
			sql_do ("DELETE FROM $conf->{systables}->{__queries} WHERE fake = 0 AND label IS NULL AND id_user = ? AND type = ? AND order_context" . ($_REQUEST {__order_context} ? ' = ?' : ' IS NULL'), $_USER -> {id}, $_REQUEST {type}, $_REQUEST {__order_context} || ());
		} else {
			sql_do ("DELETE FROM $conf->{systables}->{__queries} WHERE fake = 0 AND label = '' AND id_user = ? AND type = ? AND order_context = ?", $_USER -> {id}, $_REQUEST {type}, $_REQUEST {__order_context});
		}

	}
	else {

		unless ($_REQUEST {id___query}) {

			my $query = get___query (0, $id_table);

			$_REQUEST {id___query} = $query -> {id};

		}

	}

	unless ($_REQUEST {id___query}) {

		our $_QUERY = {};
		our @_COLUMNS = ();
		return;

	}

	our $_QUERY = sql_select_hash ($conf -> {systables} -> {__queries} => $_REQUEST {id___query});

	if ($_QUERY -> {label}) {

		$_REQUEST {id___query} = sql_select_id (

			$conf -> {systables} -> {__queries} => {

				id_user		=> $_USER -> {id},
				type		=> $_QUERY -> {type},
				label		=> '',
				order_context	=> $_REQUEST {__order_context},
				-fake		=> 0,
				-dump		=> $_QUERY -> {dump},
				-parent		=> $_QUERY -> {id},

			}, ['id_user', 'type', 'label', 'order_context'],

		);

		$_QUERY -> {parent_label}  = delete $_QUERY -> {label};
		$_QUERY -> {id_user}       = $_USER -> {id};
		$_QUERY -> {order_context} = $_REQUEST {__order_context};
		$_QUERY -> {fake}          = 0;


	}

	my $VAR1;

	eval $_QUERY -> {dump};

	$_QUERY -> {content} = $VAR1;

	my $filters = $_QUERY -> {content} -> {filters};

	foreach my $key (keys %$filters) {

		next if exists $_REQUEST {$key};

		if ($key =~ /^id_/) {

			$filters -> {$key} = $_USER -> {id} if $filters -> {$key} eq '$_USER -> {id}';

		}
		elsif ($key =~ /^dt_/ && $filters -> {$key} =~ /[^\d\.]/) {

			my ($y, $m, $d) = Date::Calc::Today;

			my $q = sprintf ('%02d', $m - (($m - 1) % 3));
			$m = sprintf ('%02d', $m);
			$d = sprintf ('%02d', $d);

			$filters -> {$key} =~ s|$i18n->{reduction_year}|$y|;
			$filters -> {$key} =~ s|$i18n->{reduction_month}|$m|;
			$filters -> {$key} =~ s|$i18n->{reduction_quarter}|$q|;
			$filters -> {$key} =~ s|$i18n->{reduction_day}|$d|;

		}

		$_REQUEST {$key} = $filters -> {$key};

	}

	my $is_there_some_columns;

	foreach my $key (keys %{$_QUERY -> {content} -> {columns}}) {

		if ($_QUERY -> {content} -> {columns} -> {$key} -> {ord}) {
			$is_there_some_columns = 1;
			last;
		}

	}

	unless ($is_there_some_columns) {

		sql_do ("DELETE FROM $conf->{systables}->{__queries} WHERE id = ?", $_REQUEST {id___query});

		delete $_REQUEST {id___query};

		$_QUERY = undef;

	}

}

################################################################################

sub get_item_of___queries {

	my ($data) = @_;

	delete $_REQUEST {__read_only};

	return $data;

}

################################################################################

sub do_drop_filters___queries {

	my $_QUERY = sql_select_hash ($conf -> {systables} -> {__queries} => $_REQUEST {id});

	my $VAR1;

	eval $_QUERY -> {dump};

	$_QUERY -> {content} = $VAR1;

	delete $_QUERY -> {content} -> {filters};

	sql_do ("UPDATE $conf->{systables}->{__queries} SET dump = ? WHERE id = ?", Dumper ($_QUERY -> {content}), $_REQUEST {id});

	my $esc_href = esc_href ();

	foreach my $key (keys %_REQUEST) {

		$key =~ /^_filter_(.+)$/ or next;

		my $filter = $1;

		$filter =~ s/_\d+//;

		$esc_href =~ s/([\?\&]$filter=)[^\&]*//;

	}

	$esc_href =~ s/([\?\&]__last_query_string=)(\-?\d+)/$1$_REQUEST{__last_query_string}/;
	$esc_href .= '&__edit_query=1';

	redirect ($esc_href, {kind => 'js'});


}

################################################################################

sub do_update___queries {

	my $content = {};

	my @order = ();

	my $is_any_column_shown = 0;

	foreach my $key (keys %_REQUEST) {

		$key =~ /^_(.+)_ord$/ or next;

		my $order = $1;

		my $mandatory_field_label = $_REQUEST {"_${order}_mandatory"};

		if (!exists($_REQUEST{"_${order}_parent"}) || $_REQUEST{$_REQUEST {"_${order}_parent"}} > 0) {
			!$mandatory_field_label or $_REQUEST {"_${order}_ord"}
				or croak "#_${order}_ord#:$i18n->{column} \"$mandatory_field_label\" $i18n->{mandatory_f}";
		};

		$content -> {columns} -> {$order} = {
			ord  => $_REQUEST {"_${order}_ord"} || 0,
			sort => $_REQUEST {"_${order}_sort"},
			desc => $_REQUEST {"_${order}_desc"},
		};

		$is_any_column_shown ||= $_REQUEST {"_${order}_ord"};

		if ($_REQUEST {"_${order}_sort"}) {

			$order [ $_REQUEST {"_${order}_sort"} ]  = $order;
			$order [ $_REQUEST {"_${order}_sort"} ] .= ' DESC' if $_REQUEST {"_${order}_desc"};

		}

	}

	$is_any_column_shown
		or croak "#_#:$i18n->{any_column_is_mandatory}";

	$content -> {order} = join ', ', grep { $_ } @order;

	foreach my $cbx (split /,/, $_REQUEST {__form_checkboxes_custom}) {
		if ($cbx =~ /(\d+)_(\d+)$/) {
			$content -> {filters} -> {$1} .= '';
		}
	}

	foreach my $key (keys %_REQUEST) {

		$key =~ /^_filter_(.+)$/ or next;

		my $filter = $1;

		$_REQUEST {$key} = join ',', -1, @{$_REQUEST {$key}} if (ref $_REQUEST {$key} eq ARRAY);

		$content -> {filters} -> {$filter} = $_REQUEST {$key} || '';

	}

	my $_QUERY = sql_select_hash ($conf -> {systables} -> {__queries} => $_REQUEST {id});

	my $VAR1;

	eval $_QUERY -> {dump};

	foreach my $col (keys %{$VAR1 -> {columns}}) {
		$content -> {columns} -> {$col} -> {no_hidden} = $VAR1 -> {columns} -> {$col} -> {no_hidden} if (exists $content -> {columns} -> {$col});
	}

	sql_do ("UPDATE $conf->{systables}->{__queries} SET dump = ? WHERE id = ?", Dumper ($content), $_REQUEST {id});

	my $esc_href = esc_href ();

	foreach my $filter (keys (%{$content -> {filters}})) {

		next
			if $filter =~ /^.+\[\]$/;

		unless ($esc_href =~ s/([\?\&]$filter=)[^\&]*/$1$content->{filters}->{$filter}/) {

			$esc_href .= "&$filter=$content->{filters}->{$filter}";

		};

	}

	$esc_href =~ s/\bstart=\d+\&?//;

	redirect ($esc_href, {kind => 'js'});

}

################################################################################

sub get___query {

	my ($id_query, $id_table) = @_;

	my ($filter, @params);

	if ($id_query) {

		$filter = ' id = ?';
		push @params, $id_query;

	} else {

		$filter = ' fake = 0 AND id_user = ? AND type = ?';
		push @params, $_USER -> {id}, $_REQUEST {type};

		if ($SQL_VERSION -> {driver} eq 'Oracle') {

			$filter .= ' AND label IS NULL';

			if ($_REQUEST {__order_context}) {
				$filter .= ' AND order_context = ?';
				push @params, $_REQUEST {__order_context};
			} else {
				$filter .= ' AND order_context IS NULL';
			}

		} else {

			$filter .= " AND label = '' AND order_context = ?";
			push @params, $_REQUEST {__order_context};

		}

		if ($id_table) {
			$filter .= ' AND id_table = ?';
			push @params, $id_table;
		} else {
			$filter .= ' AND id_table IS NULL';
		}

	}

	return sql_select_hash (
		"SELECT * FROM $conf->{systables}->{__queries} WHERE $filter",
		@params
	);

}

################################################################################

sub set___query {

	my ($id_query, $values) = @_;

	$id_query or return;

	my ($set, @params);
	foreach my $field (keys %$values) {
		$set .= ($set ? ',' : '') . "$field = ?";
		push @params, $values -> {$field};
	}

	sql_do (
		"UPDATE $conf->{systables}->{__queries} SET $set WHERE id = ?"
		, @params
		, $id_query
	);
}

################################################################################

sub set_column_props {

	my ($options) = @_;

	$options -> {id_query} or return;

	my $query = get___query ($options -> {id_query});
	my $VAR1;
	eval $query -> {dump};
	my $settings = $VAR1;

	foreach my $key (keys %$options) {
		next if $key =~ /^id_/;
		$settings -> {columns} -> {$options -> {id}} -> {$key} = $options -> {$key};
	}

	set___query ($options -> {id_query}, {dump => Dumper ($settings)});
}

################################################################################

sub draw_item_of___queries {

	my ($data) = @_;

	my @fields = (

		{
			type  => 'banner',
			label => $i18n -> {columns_and_filters},
		},

	);

	$_REQUEST {__form_checkboxes_custom} = '';

	my $cells_cnt = [];
	my $composite_columns_cnt = -1;

	for (my $i = 0; $i < @_COLUMNS; $i++) {

		my $o = $_COLUMNS [$i];

		$o -> {order} ||= $o -> {no_order};

		next unless ($o -> {order} || $o -> {no_order});

		next
			if $o -> {__hidden} && !$o -> {no_hidden} || $o -> {ord_fixed};

		my @f;

		if (exists $o -> {type} && $o -> {type} eq 'banner') {

			@f = (
				{
					type   => 'banner',
					label  => $o -> {title} || $o -> {label},
				}
			);

		} else {

			my $current_o = $o;
			my $no_hidden_title = $o -> {no_hidden_title} || 'Не отображается в текущем режиме';
			while ($current_o -> {parent_header}) {
					push @f, {
						type => 'static',
						label_off => 1,
					};
					$current_o = $current_o -> {parent_header};
			}

			push @f, (
				{
					label 		=> ($o -> {__hidden} ? "<img src='$_REQUEST{__static_url}/status_102.gif' title = '$no_hidden_title' > " : '') . ($o -> {title} || $o -> {label}),
					type  		=> 'hgroup',
					label_title => $o -> {__hidden} ? $no_hidden_title : '',
					nobr		=> 1,
					cell_width	=> '50%',
					items => [
						{
							label => $i18n -> {column_order},
							size  => 2,
							name  => $o -> {order} . '_ord',
							value => $_QUERY -> {content} -> {columns} -> {$o -> {order} || $o -> {no_order}} -> {ord},
							off   => $o -> {no_column},
						},
						{
							label => $i18n -> {sorting},
							size  => 2,
							name  => $o -> {order} . '_sort',
							value => $_QUERY -> {content} -> {columns} -> {$o -> {order} || $o -> {no_order}} -> {sort},
							off   => $o -> {no_column} || $o -> {no_order},
						},
						{
							name  => $o -> {order} . '_desc',
							type  => 'select',
							values => [{id => 1, label => $i18n -> {descending}}],
							empty => $i18n -> {ascending},
							value => $_QUERY -> {content} -> {columns} -> {$o -> {order} || $o -> {no_order}} -> {desc},
							off   => $o -> {no_column} || $o -> {no_order},
						},
						{
							name  => $o -> {order} . '_mandatory',
							type  => 'hidden',
							value => $o -> {title} || $o -> {label},
							off   => $o -> {no_column} || $o -> {no_order} || !$o -> {mandatory},
						},
						{
							name  => $o -> {order} . '_parent',
							type  => 'hidden',
							value => "_$o->{parent_header}->{order}_ord",
							off   => $o -> {no_column} || $o -> {no_order} || !$o -> {mandatory} || !$o -> {parent_header} -> {order},
						},
						{
							type  => 'static',
							value => '',
							off   => !$o -> {no_column},
						},
					],
				},
			);

			foreach my $filter (@{$o -> {filters}}) {

				my %f = %$filter;

				$f {value} ||= $_QUERY -> {content} -> {filters} -> {$f {name}};

				delete $f {type}
					if $f {type} eq 'input_text';

				$f {type} =~ s/^input_//;

				if ($f {type} eq 'select') {
					$f {values} = [grep {$_ -> {id} != -1} @{$f {values}}];
					if ($f {other}) {
						$f {name} = '_' . $f {name};
						$f {value} ||= $_QUERY -> {content} -> {filters} -> {$f {name}};
					}
				} elsif ($f {type} eq 'date') {
					$f {no_read_only}	= 1;
				} elsif ($f {type} eq 'checkbox') {
					$f {checked} = $f {value};
				} elsif ($f {type} eq 'radio') {
					$data -> {"filter_$f{name}"} = $f {value};
				} elsif ($f {type} eq 'checkboxes') {
					$data -> {'filter_' . $f {name}} = [split /,/, $f {value}];
					delete $f {value};

					$_REQUEST {__form_checkboxes_custom} .= ',' . join ',', map {"_$f{name}_$_->{id}"} @{$f {values}};
				}

				$f {name} = 'filter_' . $f {name};

				push @f, \%f;

			}

		}

		push @fields, \@f;

	}

	return draw_form ({
			keep_params	=> ['__form_checkboxes_custom'],
			right_buttons => [
				{
					icon	=> 'delete',
					label	=> $i18n -> {drop_filters},
					href	=> "javaScript:document.form.action.value='drop_filters'; \$(document.form).submit(); void(0);",
					target	=> 'invisible',
					keep_esc	=> 1,
					off		=> $_REQUEST {__read_only} || !keys %{$_QUERY -> {content} -> {filters}},
				},
			],
			no_edit => $_REQUEST {'__page_content'} -> {no_del},
			confirm_ok => undef,
		},

		$data,

		\@fields

	);

}

1;