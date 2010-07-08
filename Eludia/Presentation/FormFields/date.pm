sub draw_form_field_date {

	my ($options, $data) = @_;

	$options -> {value}  ||= $data -> {$options -> {name}};
	
	$options -> {no_time}  = 1;

	$options -> {format} ||= ($i18n -> {_format_d} || '%d.%m.%Y');

	$options -> {size}   ||= 11;

	return draw_form_field_string ($options, $data) if $r -> headers_in -> {'User-Agent'} =~ /MSIE 5\.0/;
	
	adjust_form_field_options ($options);

	return $_SKIN -> draw_form_field_datetime (@_);

}

1;