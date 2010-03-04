sub draw_form_field_checkbox {

	my ($options, $data) = @_;
	
	$_REQUEST {__form_checkboxes} .= ",_$options->{name}";
	
	$options -> {attributes} -> {checked}  = 1 if $options -> {checked} || $data -> {$options -> {name}};
	$options -> {attributes} -> {tabindex} = ++ $_REQUEST {__tabindex};
	
	return $_SKIN -> draw_form_field_checkbox (@_);
	
}

1;