################################################################################

sub do_add_DEFAULT { # Слияние дубликатов

	sql_do_relink ($_REQUEST {type}, [get_ids ('clone')] => $_REQUEST {id});

}

################################################################################

sub do_kill_DEFAULT { # массовое удаление

	foreach my $id (get_ids ($_REQUEST {type})) {

		sql_do ("UPDATE $_REQUEST{type} SET fake = -1 WHERE id = ?", $id);

	}

}

################################################################################

sub do_unkill_DEFAULT { # массовое восстановление

	my $extra = '';
	$extra .= ', is_merged_to = 0' if $DB_MODEL -> {tables} -> {$table_name} -> {columns} -> {is_merged_to};
	$extra .= ', id_merged_to = 0' if $DB_MODEL -> {tables} -> {$table_name} -> {columns} -> {id_merged_to};

	foreach my $id (get_ids ($_REQUEST {type})) {

		sql_do ("UPDATE $_REQUEST{type} SET fake = 0 $extra WHERE id = ?", $id);

		sql_undo_relink ($_REQUEST{type}, $_REQUEST{id});

	}

	$_REQUEST {fake} = 0;

}

################################################################################

#sub validate_kill_DEFAULT {
#	get_ids ($_REQUEST {type}) > 0 or return 'Вы не выделили ни одной строки';
#	return undef;
#}

################################################################################

#sub validate_unkill_DEFAULT {
#	get_ids ($_REQUEST {type}) > 0 or return 'Вы не выделили ни одной строки';
#	return undef;
#}

################################################################################

sub do_create_DEFAULT { # создание

	my $default_values = {};

	my $def = $DB_MODEL -> {tables} -> {$_REQUEST {type}};

	my $parent;

	if ($def && $def -> {columns}) {

		my $columns = $def -> {columns};

		foreach my $key (keys %$columns) {

			my $column = $columns -> {$key};

			$column -> {parent} or next;

			$parent = {column => $key, columns => []};

			unless ($column -> {ref}) {

				foreach my $table ($model_update -> get_tables) {

					$key eq 'id_' . en_unplural ($table) or next;

					$parent -> {table} = $table;

					last;

				}

				$parent -> {table} or die "Parent table not found for $key\n";

				my $parent_def = $DB_MODEL -> {tables} -> {$parent -> {table}} or die "Table definition not found for $parent->{table}\n";

				my $parent_columns = $parent_def -> {columns} or die "Columns definition not found for $parent->{table}\n";

				foreach my $key (%$parent_columns) {

					$key =~ /^id_/ or next;

					$columns -> {$key} or next;

					push @{$parent -> {columns}}, $key;

				}

			}

			last;

		}

	}

	my $columns = $model_update -> get_columns ($_REQUEST {type});

	if ($parent && !$_REQUEST {"_$parent->{column}"}) {

		my $href = session_access_log_get ($_REQUEST {__last_last_query_string});

		if ($href =~ /\bid\=(\d+)/) {

			$_REQUEST {"_$parent->{column}"} = $1;

		}

	}

	if ($parent && $_REQUEST {"_$parent->{column}"}) {

		my $data = sql ($parent -> {table} => $_REQUEST {"_$parent->{column}"});

		foreach my $key (@{$parent -> {columns}}) {

			exists $_REQUEST {"_$key"} or $_REQUEST {"_$key"} = $data -> {$key};

		}

	}

	while (my ($k, $v) = each %_REQUEST) {

		if ($k =~ /^_/) {

			exists $columns -> {$'} or next;
			$default_values -> {$'} = $v;

		}
		else {

			next if $k =~ /^(s(id|alt|elect)|type|action|lang|error|fake)$/;
			exists $columns -> {$k} or next;
			$default_values -> {$k} = $v;

		}

	}

	$_REQUEST {id} = sql_do_insert ($_REQUEST {type}, $default_values);

}

################################################################################

sub do_update_DEFAULT { # запись карточки

	my $type = $_[0] || $_REQUEST {__edited_cells_table} || $_REQUEST {type};

	my $columns = $model_update -> get_columns ($type);

	my $id_edit = $_REQUEST {id_edit_cell} || $_REQUEST {id};

	if ($_REQUEST {_file_clear_flag_for_file} && !$_REQUEST {_file}) {

		sql_delete_file ({path_column => 'file_path', table => $type});

		sql_do ("UPDATE $type SET file_name = NULL, file_size = NULL, file_type = NULL, file_path = NULL WHERE id = ?", $id_edit);

	}

	my $options = {
		name => 'file',
		dir => 'upload/images',
		table => $type,
		file_name_column => 'file_name',
		size_column => 'file_size',
		type_column => 'file_type',
		path_column => 'file_path',
	};

	$options -> {body_column} = 'file_body' if $columns -> {file_body};

	sql_upload_file ($options);

	sql_upload_files ({name => 'file'});

	my @fields = ();

	foreach my $key (keys %_REQUEST) {
		$key =~ /^_/ or next;
		$columns -> {$'} or next;
		push @fields, $';
	}

	if (@fields > 0) {

		my $id = $_[2] || 'id';

		sql_do_update ($type, \@fields, {$id => $_[1] || $id_edit});

	}

	foreach my $key (keys %_REQUEST) {

		$key =~ /^__checkboxes_/ or next;

		my $table_from = $_REQUEST {$key};

		my ($table, $from) = split /\./, $table_from;

		$from ||= 'id_' . en_unplural ($_REQUEST {type});

		my $options = {

			table => $table,
			key   => $',
			root  => {$from => $id_edit},

		};

		sql_store_ids (darn $options);

	}

}

################################################################################

sub do_download_DEFAULT { # загрузка файла

	my $name = $_REQUEST {_name} || 'file';

	my $options = {
		name => $name,
		dir => 'upload/images',
		table => $_REQUEST{type},
		file_name_column => $name . '_name',
		size_column => $name . '_size',
		type_column => $name . '_type',
		path_column => $name . '_path',
		no_force_download => $_REQUEST {no_force_download},
	};

	$options -> {body_column} = $name . '_body' if $DB_MODEL -> {tables} -> {$_REQUEST {type}} -> {columns} -> {$name . '_body'};

	sql_download_file ($options);

}

################################################################################

sub do_delete_DEFAULT { # удаление

	sql_do ("UPDATE $_REQUEST{type} SET fake = -1 WHERE id = ?", $_REQUEST{id});

}

################################################################################

sub do_undelete_DEFAULT { # восстановление

	my ($table_name, $id) = @_;
	$table_name ||= $_REQUEST {type};
	$id ||= $_REQUEST {id};

	my $extra = '';
	$extra .= ', is_merged_to = 0' if $DB_MODEL -> {tables} -> {$table_name} -> {columns} -> {is_merged_to};
	$extra .= ', id_merged_to = 0' if $DB_MODEL -> {tables} -> {$table_name} -> {columns} -> {id_merged_to};

	sql_do ("UPDATE $table_name SET fake = 0 $extra WHERE id = ?", $id);

	sql_undo_relink ($table_name, $id);

}

################################################################################

sub _do_update_dimensions_DEFAULT { # сохранение ширин колонок

	my ($columns) = @_;

	foreach my $column (@$columns) {

		$column -> {id_query} = $_REQUEST {id___query};

		if (@{$column -> {group}}) {
			_do_update_dimensions_DEFAULT ($column -> {group});
			delete $column -> {group};
		}

		set_column_props ($column);

	}


}

################################################################################

sub do_update_dimensions_DEFAULT { # сохранение ширин колонок

	my $columns = $_JSON -> decode ($_REQUEST {columns});

	_do_update_dimensions_DEFAULT ($columns);

	my $query = sql_select_hash ("SELECT parent, dump FROM $conf->{systables}->{__queries} WHERE id = ?", $_REQUEST {id___query});
	if ($query -> {parent}) {
		sql_do ("UPDATE $conf->{systables}->{__queries} SET dump = ? WHERE id = ? AND id_user = ?", $query -> {dump}, $query -> {parent}, $_USER -> {id});
	}

	out_json ({});
}

################################################################################

sub _do_update_columns_DEFAULT { # сохранение ширин колонок

	my ($columns) = @_;

	my $ord = 1;
	foreach my $column (@$columns) {

		$column -> {sortable} = $column -> {asc} || $column -> {desc};

		if ($_REQUEST {sort} && !$_REQUEST {order} && $column -> {sortable}) {
			$_REQUEST {order} = $column -> {id};
			$_REQUEST {desc} = $column -> {desc} || 0;
		}

		set_column_props ({
			id_query => $_REQUEST {id___query},
			id       => $column -> {id},
			ord      => $ord,
			$column -> {width}  ? (width  => $column -> {width})  : (),
			$column -> {height} ? (height => $column -> {height}) : (),
		});

		if (@{$column -> {group}}) {
			_do_update_columns_DEFAULT ($column -> {group});
		}

		$ord++;
	}

}

################################################################################

sub do_update_columns_DEFAULT { # переставили колонки, поменяли сортировку

	setup_json ();

	my $columns = $_JSON -> decode ($_REQUEST {columns});

	_do_update_columns_DEFAULT ($columns);

	my ($parent, $dump) = sql_select_array ("SELECT parent, dump FROM $conf->{systables}->{__queries} WHERE id = ?", $_REQUEST {id___query} || 0);

	if ($parent) {
		sql_do ("UPDATE $conf->{systables}->{__queries} SET dump = ? WHERE id = ? AND id_user = ?", $dump, $parent, $_USER -> {id});
	}

	$_QUERY = undef;

	delete $_REQUEST {action};

	my $page = setup_page ();

	$page -> {no_adjust_last_query_string} = 1;

	handle_request_of_type_showing ($page);
}


################################################################################

sub get_data_DEFAULT {

	handle_request_of_type_showing (@_);

}

1;
