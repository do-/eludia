sub draw_form_field_date {

	my ($_options, $data) = @_;
	
	$_options -> {no_time} = 1;	
	
	return draw_form_field_datetime ($_options, $data);

}

1;