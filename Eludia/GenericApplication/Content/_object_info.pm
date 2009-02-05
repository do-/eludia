################################################################################

sub get_item_of__object_info {

	$_REQUEST {__read_only} = 1;

	my $item = sql_select_hash ($_REQUEST {object_type});
	
	my $log_alias = 'log_' . $$;
	
	sql_do ("HANDLER $conf->{systables}->{log} OPEN AS $log_alias");

	$item -> {last_update} = sql_select_hash ("HANDLER $log_alias READ \`PRIMARY\` LAST WHERE type = '$_REQUEST{object_type}' AND action = 'update' AND id_object = '$_REQUEST{id}'");
	$item -> {last_update} -> {dt} =~ s{(\d+)\-?(\d+)\-?(\d+)}{$3.$2.$1};
	$item -> {last_update} -> {user} = sql_select_hash ($conf -> {systables} -> {users}, $item -> {last_update} -> {id_user});

	$item -> {last_create} = sql_select_hash ("HANDLER $log_alias READ \`PRIMARY\` PREV WHERE type = '$_REQUEST{object_type}' AND action = 'create' AND id_object = '$_REQUEST{id}'");
	$item -> {last_create} -> {dt} =~ s{(\d+)\-?(\d+)\-?(\d+)}{$3.$2.$1};
	$item -> {last_create} -> {user} = sql_select_hash ($conf -> {systables} -> {users}, $item -> {last_create} -> {id_user});
	
	sql_do ("HANDLER $log_alias CLOSE");

	my @references = ();
	
	foreach my $reference ( sort {$a -> {table_name} . ' ' . $a -> {name} cmp $b -> {table_name} . ' ' . $b -> {name}} @{$DB_MODEL -> {tables} -> {$_REQUEST {object_type}} -> {references}}) {

		my $where = ' WHERE fake = 0 AND ' . $reference -> {name};

		if ($reference -> {TYPE_NAME} =~ /int/) {
			$where .= " = $_REQUEST{id}";
		}
		else {
			$where .= " LIKE '\%,$_REQUEST{id},\%'";
		}
		
		my $cnt = sql_select_scalar ("SELECT COUNT(*) FROM " . $reference -> {table_name} . $where) or next;

		push @references, {
			table_name => $reference -> {table_name},
			name => $reference -> {name},
			cnt => $cnt,
		};
		
		if ($_REQUEST {table_name} eq $reference -> {table_name} && $_REQUEST {name} eq $reference -> {name}) {

			my $start = $_REQUEST {start} + 0;

			($item -> {records}, $item -> {cnt}) = sql_select_all_cnt ('SELECT * FROM ' . $reference -> {table_name} . $where . " ORDER BY id DESC LIMIT $start, 15");

		}
		
	}
	
	$item -> {references} = \@references;
		
	return $item;
	
}
