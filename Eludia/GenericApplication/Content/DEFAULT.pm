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
			
				foreach my $table ($db -> tables ('', $self -> {schema}, '%', "'TABLE'")) {
					
					$table = $model_update -> unquote_table_name ($table);
				
					$table =~ s{\W}{}g;
														
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
	
		my $href = sql_select_scalar (
			"SELECT href FROM $conf->{systables}->{__access_log} WHERE id_session = ? AND no = ?",
			$_REQUEST {sid}, 
			$_REQUEST {__last_last_query_string}
		);
		
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

	my $type = $_[0] || $_REQUEST {type};

	my $columns = $model_update -> get_columns ($type);

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
	
	@fields > 0 or return;

	sql_do_update ($type, \@fields, {id => $_[1] || $_REQUEST {id}});

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