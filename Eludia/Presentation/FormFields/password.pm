################################################################################

sub draw_form_field_password {

	my ($options, $data) = @_;

	$options -> {size} ||= $conf -> {size} || 120;
	
	delete $options -> {value};

	adjust_form_field_options ($options);
	
	return $_SKIN -> draw_form_field_password (@_);
	
}

1;