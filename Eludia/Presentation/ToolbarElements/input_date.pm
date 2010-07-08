sub draw_toolbar_input_date {

	my ($options) = @_;

	$options -> {no_time} = 1;

	return call_from_file ("Eludia/Presentation/ToolbarElements/input_datetime.pm", 'draw_toolbar_input_datetime', @_);

}

1;