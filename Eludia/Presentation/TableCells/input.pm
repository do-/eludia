sub draw_input_cell {

	my ($data, $options) = @_;

	return call_from_file ('Eludia/Presentation/TableCells/text.pm', 'draw_text_cell', @_)
		if ($_REQUEST {__read_only} && !$data -> {edit} && !$_REQUEST {__suggest}) || $data -> {read_only} || $data -> {off};

	$data -> {size} ||= 30;

	_adjust_row_cell_style ($data, $options);

	defined $data -> {label} or $data -> {label} = '';

	if ($data -> {picture}) {
		$data -> {label} = format_picture ($data -> {label}, $data -> {picture});
		$data -> {label} =~ s/^\s+//g;
		$data -> {attributes} -> {align} ||= 'right';
	}

	if ($data -> {autocomplete} && $_REQUEST {__suggest} eq $data -> {name}) {

		our $_SUGGEST_SUB = &{$data -> {autocomplete} -> {values}} ();

	} 

	check_title ($data);

	return $_SKIN -> draw_input_cell ($data, $options);

}

1;
