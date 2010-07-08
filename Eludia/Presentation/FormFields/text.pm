sub draw_form_field_text {

	my ($options, $data) = @_;
	
	$options -> {value}   ||= $data -> {$options -> {name}};

	$options -> {cols}    ||= 60;
	
	$options -> {rows}    ||= 25;
	
	adjust_form_field_options ($options);
	
	return $_SKIN -> draw_form_field_text (@_);

}

1;