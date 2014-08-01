sub draw_form_field_suggest {

	my ($options, $data) = @_;

	$options -> {max_len} ||= 255;
	$options -> {size}    ||= 120;
	$options -> {lines}   ||= 10;

	$options -> {value}   ||= $data -> {$options -> {name}};
	$options -> {value__id} = $options -> {value};

	my $id = $_REQUEST {id};

	if ($_REQUEST {__suggest} eq $options -> {name}) {
		if ($ENV {HTTP_CONTENT_TYPE} =~ /charset=UTF-8/i) {
			$_REQUEST {"_$options->{name}__label"} = encode ("cp1251", decode ("utf-8", $_REQUEST {"_$options->{name}__label"}));
		}
		our $_SUGGEST_SUB = $options -> {values};

	}
	elsif ($data -> {id}) {

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

	adjust_form_field_options ($options);

	return $_SKIN -> draw_form_field_suggest (@_);

}

1;