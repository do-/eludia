sub draw_form_field_color {

	my ($options, $data) = @_;

	$options -> {value} ||= $data -> {$options -> {name}};

	return $_SKIN -> draw_form_field_color (@_);

}

1;