sub draw_form_field_htmleditor {

	my ($options, $data) = @_;

	$options -> {value} ||= $data -> {$options -> {name}};

	return $_SKIN -> draw_form_field_htmleditor (@_);

}

1;