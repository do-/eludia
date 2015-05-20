sub draw_toolbar_pager {

	my ($options, $list) = @_;
		
	$options -> {portion} ||= $_REQUEST {__page_content} -> {portion} || $conf -> {portion};
	$options -> {total}   ||= $_REQUEST {__page_content} -> {cnt};
	$options -> {cnt}     ||= 0 + @$list;

	if (!$options -> {total} && !$options -> {empty_label}) {
		return '';
	}

	$options -> {start} = $_REQUEST {start} || 0;

	$conf -> {kb_options_pager} ||= $conf -> {kb_options_buttons};
	$conf -> {kb_options_pager} ||= {ctrl => 1};

	my %keep_params	= map {$_ => $_REQUEST {$_}} @{$options -> {keep_params}};

	$keep_params {__this_query_string}      = $_REQUEST {__last_query_string};
	$keep_params {__last_query_string}      = $_REQUEST {id} && !$options -> {keep_esc} ? $_REQUEST {__last_last_query_string} : $_REQUEST {__last_query_string};
	$keep_params {__last_last_query_string} = $_REQUEST {__last_last_query_string};
	
	if ($options -> {start} > $options -> {portion}) {
		$options -> {rewind_url} = create_url (start => 0, %keep_params);
	}
	
	if ($options -> {start} > 0) {

		hotkey ({
			code => 33, 
			data  => '_pager_prev', 
			%{$conf -> {kb_options_pager}},
		});
		
		$options -> {back_url} = create_url (start => ($options -> {start} - $options -> {portion} < 0 ? 0 : $options -> {start} - $options -> {portion}), %keep_params);

	}
	
	if ($options -> {start} + $$options{cnt} < $$options{total} || $$options{total} == -1) {
	
		hotkey ({
			code => 34, 
			data  => '_pager_next', 
			%{$conf -> {kb_options_pager}},
		});
		
		$options -> {next_url} = create_url (start => $options -> {start} + $options -> {portion}, %keep_params);

	}
	
	if ($options -> {start} + $$options{cnt} * 2 < $$options{total}) {
	
		$options -> {last_url} = create_url (start => $options -> {total} - $options -> {portion}, %keep_params);

	}

	$options -> {infty_url}   = create_url (__last_query_string => $last_query_string, __infty => 1 - ($_REQUEST {__infty} || 0), __no_infty => 1 - ($_REQUEST {__no_infty} || 0), @keep_params);
	
	$options -> {infty_label} = $options -> {total} > 0 ? $options -> {total} : $i18n -> {infty};
	
	return $_SKIN -> draw_toolbar_pager (@_);

}

1;