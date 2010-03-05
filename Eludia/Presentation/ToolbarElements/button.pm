sub draw_toolbar_button {

	my ($options) = @_;
			
	$conf -> {kb_options_buttons} ||= {ctrl => 1, alt => 1};	
	
	register_hotkey ($options, 'href', $options, $conf -> {kb_options_buttons});
	
	check_href ($options);

	if (
		$options -> {href} !~ /^java/ &&
		(	
			$options -> {keep_esc} ||
			(!exists $options -> {keep_esc} && $options -> {icon} eq 'create' && $options -> {href} !~ /action=create/)
		)
	) {
		
		$options -> {href} =~ s{\&?__last_query_string=\d*}{}gsm;
		$options -> {href} .= "&__last_query_string=$_REQUEST{__last_last_query_string}";

		$options -> {href} =~ s{\&?__last_scrollable_table_row=\d*}{}gsm;
		$options -> {href} .= "&__last_scrollable_table_row=$_REQUEST{__last_scrollable_table_row}" unless ($_REQUEST {__windows_ce});
	
	}		
	
	$_SKIN -> __adjust_button_href ($options);
	
	return $_SKIN -> draw_toolbar_button ($options);

}

1;