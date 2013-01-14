sub draw_date_cell {

	my ($data, $options) = @_;

	return call_from_file ('Eludia/Presentation/TableCells/text.pm', 'draw_text_cell', @_)
		if ($_REQUEST {__read_only} && !$data -> {edit}) || $data -> {read_only} || $data -> {off};

	$options -> {no_time} = 1;

	return call_from_file ("Eludia/Presentation/TableCells/datetime.pm", "draw_datetime_cell", @_);

}

1;
