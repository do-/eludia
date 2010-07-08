sub draw_radio_cell {

	my ($data, $options) = @_;
	
	return draw_text_cell (@_) if $data -> {read_only} || $data -> {off};
	
	$data -> {value} ||= 1;	
	$data -> {checked} = $data -> {checked} ? 'checked' : '';

	_adjust_row_cell_style ($data, $options);

	check_title ($data);
	
	return $_SKIN -> draw_radio_cell ($data, $options);

}

1;