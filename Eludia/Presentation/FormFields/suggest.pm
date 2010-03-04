sub draw_form_field_suggest {

	my ($options, $data) = @_;
	
	$options -> {max_len} ||= 255;
	$options -> {size}    ||= 120;
	$options -> {lines}   ||= 10;

	$options -> {value}   ||= $data -> {$options -> {name}};
	$options -> {value__id} = $options -> {value};

	my $id = $_REQUEST {id};
	
	if ($data -> {id}) {
	
		if ($options -> {value} == 0) {
		
			$options -> {value} = '';
		
		}
		else {

			$_REQUEST {id} = $options -> {value};
			my $h = &{$options -> {values}} ();
			$options -> {value} = $h -> {label} if ref $h eq HASH;
			$_REQUEST {id} = $id;

		}

	}
	elsif ($_REQUEST {__suggest} eq $options -> {name}) {
	
		our $_SUGGEST_SUB = $options -> {values};
	
	}
	
	adjust_form_field_options ($options);

	return $_SKIN -> draw_form_field_suggest (@_);
	
}

1;