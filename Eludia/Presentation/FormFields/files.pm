sub draw_form_field_files {

	my ($options, $data) = @_;
	
	$_REQUEST {__form_options} {enctype} = 'multipart/form-data';

	$options -> {size} ||= 60;
	
	adjust_form_field_options ($options);

	return $_SKIN -> draw_form_field_files (@_);

}

1;