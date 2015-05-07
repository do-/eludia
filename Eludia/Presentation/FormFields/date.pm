sub draw_form_field_date {

	my ($options, $data) = @_;

	$options -> {value}  ||= $data -> {$options -> {name}};
	
	$options -> {no_time}  = 1;

	$options -> {format} ||= ($i18n -> {_format_d} || '%d.%m.%Y');

	unless ($options -> {size}) {
		$options -> {size} = 11;
		$options -> {attributes} -> {maxlength} = $options -> {size} - 1;
	}

	if ($r -> headers_in -> {'User-Agent'} =~ /MSIE 5\.0/) {
		$options -> {type} = 'string';
		return draw_form_field_of_type ($options, $data);
	}
	
	adjust_form_field_options ($options);

	return $_SKIN -> draw_form_field_datetime (@_);

}

1;