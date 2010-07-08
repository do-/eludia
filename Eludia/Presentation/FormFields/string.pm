sub draw_form_field_string {

	my ($options, $data) = @_;
	
	$options -> {value} ||= $data -> {$options -> {name}};
		
	if ($options -> {picture}) {
	
		$options -> {value} = format_picture ($options -> {value}, $options -> {picture});
		
		$options -> {value} =~ s/^\s+//g;
		
	}

	adjust_form_field_options ($options);

	return $_SKIN -> draw_form_field_string (@_);

}

1;