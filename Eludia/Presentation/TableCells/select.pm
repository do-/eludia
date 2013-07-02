sub draw_select_cell {

	my ($data, $options) = @_;

	return call_from_file ('Eludia/Presentation/TableCells/text.pm', 'draw_text_cell', @_)
		if ($_REQUEST {__read_only} && !$data -> {edit}) || $data -> {read_only} || $data -> {off};

	$data -> {max_len} ||= $conf -> {max_len};

	_adjust_row_cell_style ($data, $options);

	foreach my $value (@{$data -> {values}}) {
		$value -> {selected} = ($value -> {id} eq $data -> {value}) ? 'selected' : '';
		$value -> {label} = trunc_string ($value -> {label}, $data -> {max_len});
		$value -> {id} =~ s{\"}{\&quot;}g; #"
	}

	return $_SKIN -> draw_select_cell ($data, $options);

}

1;
