sub draw_form_field_button {

	my ($options, $data) = @_;

	$options -> {value} ||= $data -> {$options -> {name}};

	$options -> {value} =~ s/\"/\&quot\;/gsm; #"

	return $_SKIN -> draw_form_field_button (@_);

}

1;