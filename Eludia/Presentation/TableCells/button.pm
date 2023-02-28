sub draw_button_cell {

	my ($options) = @_;

	return ''
		if $_REQUEST {xls};

	check_href ($options);

	if ($options -> {confirm}) {
		my $salt = rand;
		my $msg = js_escape ($options -> {confirm});
		$options -> {href} =~ s{\%}{\%25}gsm; 		# wrong, but MSIE uri_unescapes the 1st arg of window.open :-(
		my $target = $options -> {target} || '_self';
		if ($options -> {href} =~ s/^javascript://i) {
			$options -> {href} = qq [javascript:if (confirm ($msg)) {$$options{href}}];
		}else{
			$options -> {href} = qq [javascript:if (confirm ($msg)) {nope('$$options{href}', '$target')} else {document.body.style.cursor = 'default'; nop ();}];
		}
	}

	if (
		! (
			$options -> {keep_esc} ||
			(!exists $options -> {keep_esc} && $options -> {icon} eq 'delete' && !$_REQUEST {id})
		)

	) {
		$options -> {href} =~ s{__last_query_string\=\d+}{__last_query_string\=$_REQUEST{__last_last_query_string}}gsm;
	}

	if ($options -> {href} =~ /^java/) {
		$options -> {target} = '_self';
	}

	check_title ($options);

	return $_SKIN -> draw_row_button ($options);

}

1;