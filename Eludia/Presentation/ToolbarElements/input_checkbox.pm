sub draw_toolbar_input_checkbox {

	my ($options) = @_;
	
	$options -> {checked} = (exists $options -> {checked} ? $options -> {checked} : $_REQUEST {$options -> {name}}) ? 'checked' : '';

	$options -> {onClick} ||= 'submit();';
	

	return $_SKIN -> draw_toolbar_input_checkbox ($options);
	
}

1;