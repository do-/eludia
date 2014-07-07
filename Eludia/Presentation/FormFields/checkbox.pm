sub draw_form_field_checkbox {

	my ($options, $data) = @_;
	
	$_REQUEST {__form_checkboxes} .= ",_$options->{name}";
	$options -> {value_src} = "(document.getElementsByName ('_$options->{name}') [0].checked ? 1 : 0)";
	
	$options -> {attributes} -> {checked}  = 1 if $options -> {checked} || $data -> {$options -> {name}};
	$options -> {attributes} -> {tabindex} = ++ $_REQUEST {__tabindex};
	
	if (defined $options -> {detail}) {
		$options -> {attributes} -> {onclick} .= js_detail ($options);
	}

	return $_SKIN -> draw_form_field_checkbox (@_);
	
}

1;