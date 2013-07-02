sub draw_checkbox_cell {

	my ($data, $options) = @_;

	return call_from_file ('Eludia/Presentation/TableCells/text.pm', 'draw_text_cell', @_)
		if $data -> {read_only} || $data -> {off};

	if ($data -> {name} =~ /^_(\w+)_\d+$/) {

		$_REQUEST {__get_ids} -> {$1} ||= 1;

	}

	$data -> {value} ||= 1;
	$data -> {checked} = $data -> {checked} ? 'checked' : '';

	_adjust_row_cell_style ($data, $options);

	check_title ($data);

	return $_SKIN -> draw_checkbox_cell ($data, $options);

}

1;
