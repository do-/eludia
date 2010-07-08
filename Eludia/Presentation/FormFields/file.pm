sub draw_form_field_file {

	my ($options, $data) = @_;
	
	$_REQUEST {__form_options} {enctype} = 'multipart/form-data';

	$options -> {size} ||= 60;
	
	$options -> {attributes} -> {class} ||= $options -> {mandatory} ? 'form-mandatory-inputs' : 'form-active-inputs';

	adjust_form_field_options ($options);

	return $_SKIN -> draw_form_field_file (@_);

}

1;