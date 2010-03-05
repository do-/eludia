sub draw_toolbar_input_text {

	my ($options) = @_;
	
	$options -> {id} ||= ('' . $options);

	$conf -> {kb_options_focus} ||= $conf -> {kb_options_buttons};
	$conf -> {kb_options_focus} ||= {ctrl => 1, alt => 1};

	register_hotkey ($options, 'focus_id', $options -> {id}, $conf -> {kb_options_focus});
	
	$options -> {value} ||= $_REQUEST {$options -> {name}};	
	$options -> {size} ||= 15;		
	
	return $_SKIN -> draw_toolbar_input_text (@_);

}

1;