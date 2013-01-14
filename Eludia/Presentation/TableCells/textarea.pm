sub draw_textarea_cell {

	my ($data, $options) = @_;

	return call_from_file ('Eludia/Presentation/TableCells/text.pm', 'draw_text_cell', @_)
		if ($_REQUEST {__read_only} && !$data -> {edit}) || $data -> {read_only} || $data -> {off};

	$data -> {rows} ||= 3;
	$data -> {cols} ||= 80;

	$data -> {attributes} ||= {};
	$data -> {attributes} -> {class} ||= 'row-cell';

	_adjust_row_cell_style ($data, $options);

	$data -> {label} ||= '';

	check_title ($data);

	return $_SKIN -> draw_textarea_cell ($data, $options);

}

1;
