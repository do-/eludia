sub draw_form_field_datetime {

	my ($options, $data) = @_;
	
	$options -> {value}  ||= $data -> {$options -> {name}};

	$options -> {format} ||= $options -> {no_time} ?

		($i18n -> {_format_d}  || '%d.%m.%Y'      ) :
		
		($i18n -> {_format_dt} || '%d.%m.%Y %k:%M') ;

	unless ($options -> {size}) {
		$options -> {size} = length ($options -> {format}) + 4 - ($options -> {format} =~ y{ }{ });
		$options -> {attributes} -> {maxlength} = $options -> {size} - 1;
	}

	if (defined $options -> {detail}) {
		$options -> {value_src} = "\$('#input_$options->{name}').val()";
		$options -> {onClose} .= js_detail ($options);
	}

	if ($r -> headers_in -> {'User-Agent'} =~ /MSIE 5\.0/) {
		$options -> {type} = 'string';
		return draw_form_field_of_type ($options, $data);
	}
	
	adjust_form_field_options ($options);

	return $_SKIN -> draw_form_field_datetime (@_);

}

1;