sub draw_form_field_htmleditor {
	
	my ($options, $data) = @_;
		
	push @{$_REQUEST{__include_js}}, 'rte/fckeditor';
	
	$options -> {value} ||= $data -> {$options -> {name}};
		
	$options -> {value} =~ s{\\}{\\\\}gsm;
	$options -> {value} =~ s{\"}{\\\"}gsm; #"
	$options -> {value} =~ s{\'}{\\\'}gsm; #'
	$options -> {value} =~ s{[\n\r]+}{\\n}gsm;

	return $_SKIN -> draw_form_field_htmleditor (@_);

}

1;