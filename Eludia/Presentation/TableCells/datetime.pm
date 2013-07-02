sub draw_datetime_cell {

	my ($data, $options) = @_;

	return call_from_file ('Eludia/Presentation/TableCells/text.pm', 'draw_text_cell', @_)
		if ($_REQUEST {__read_only} && !$data -> {edit}) || $data -> {read_only} || $data -> {off};

	if ($r -> headers_in -> {'User-Agent'} =~ /MSIE 5\.0/) {
		$options -> {size} ||= $options -> {no_time} ? 11 : 16;
		return draw_input_cell ($options, $data);
	}

	unless ($options -> {format}) {

		if ($options -> {no_time}) {
			$options -> {format}  ||= $i18n -> {_format_d} || '%d.%m.%Y';
			$options -> {attributes} -> {size}    ||= 11;
		}
		else {
			$options -> {format}  ||= $i18n -> {_format_dt} || '%d.%m.%Y %k:%M';
			$options -> {attributes} -> {size}    ||= 16;
		}

	}

	$options -> {attributes} -> {id} = 'input' . $data -> {name};

	$options -> {attributes} -> {class} ||= $data -> {mandatory} ? 'form-mandatory-inputs' : 'form-active-inputs';

	$options -> {attributes} -> {value}   ||= $data -> {label};

	_adjust_row_cell_style ($data, $options);

	check_title ($data);

	return $_SKIN -> draw_datetime_cell (@_);

}

1;
