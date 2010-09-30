sub draw_form_field_datetime {

	my ($options, $data) = @_;
	
	$options -> {value}  ||= $data -> {$options -> {name}};

	$options -> {format} ||= $options -> {no_time} ?

		($i18n -> {_format_d}  || '%d.%m.%Y'      ) :
		
		($i18n -> {_format_dt} || '%d.%m.%Y %k:%M') ;

	$options -> {size}   ||= length ($options -> {format}) + 3 - ($options -> {format} =~ y{ }{ });

	if ($r -> headers_in -> {'User-Agent'} =~ /MSIE 5\.0/) {
		$options -> {type} = 'string';
		return draw_form_field_of_type ($options, $data);
	}
	
	adjust_form_field_options ($options);

	return $_SKIN -> draw_form_field_datetime (@_);

}

1;