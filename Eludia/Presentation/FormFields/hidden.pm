sub draw_form_field_hidden {

	my ($options, $data)  = @_;	
	
	$options -> {value} ||= $data -> {$options -> {name}};	
	
	adjust_form_field_options ($options);

	return $_SKIN -> draw_form_field_hidden (@_);
	
}

1;