sub draw_toolbar_input_datetime {

	my ($options) = @_;
			
	if ($r -> headers_in -> {'User-Agent'} =~ /MSIE 5\.0/) {
		$options -> {size} ||= $options -> {no_time} ? 11 : 16;
		return draw_toolbar_input_text ($options, $data);
	}
		
	unless ($options -> {format}) {
	
		if ($options -> {no_time}) {
			$options -> {format}  ||= $i18n -> {_format_d} || '%d.%m.%Y';
			$options -> {size}    ||= 11;
		}
		else {
			$options -> {format}  ||= $i18n -> {_format_dt} || '%d.%m.%Y %k:%M';
			$options -> {size}    ||= 16;
		}
	
	}
			
	$options -> {attributes} -> {size}      = $options -> {size};
	$options -> {attributes} -> {maxlength} = $options -> {size};

	$options -> {value}      ||= $_REQUEST {$$options{name}};
	$options -> {attributes} -> {value} = $options -> {value};
	
	$options -> {attributes} -> {id} = 'input' . $options -> {name};

	$options -> {attributes} -> {tabindex} = ++ $_REQUEST {__tabindex};
	
	return $_SKIN -> draw_toolbar_input_datetime (@_);
	
}

1;