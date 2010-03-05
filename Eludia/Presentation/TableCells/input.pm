sub draw_input_cell {

	my ($data, $options) = @_;
	
	return draw_text_cell ($data, $options) if ($_REQUEST {__read_only} && !$data -> {edit}) || $data -> {read_only} || $data -> {off};

	$data -> {size} ||= 30;
	
	_adjust_row_cell_style ($data, $options);
						
	defined $data -> {label} or $data -> {label} = '';
	
	if ($data -> {picture}) {
		$data -> {label} = format_picture ($data -> {label}, $data -> {picture});
		$data -> {label} =~ s/^\s+//g;
		$data -> {attributes} -> {align} ||= 'right';
	}
			
	check_title ($data);
		
	return $_SKIN -> draw_input_cell ($data, $options);

}

1;