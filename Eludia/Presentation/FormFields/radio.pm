sub draw_form_field_radio {

	my ($options, $data) = @_;

	$options -> {values} = [ grep { !$_ -> {off} } @{$options -> {values}} ] if $data -> {id};

	foreach my $value (@{$options -> {values}}) {

		$value -> {attributes} -> {tabindex} = ++ $_REQUEST {__tabindex};
		$value -> {attributes} -> {checked} = 1 if ($data -> {$options -> {name}} == $value -> {id} && $data -> {$options -> {name}} =~ /^\d+$/) or $data -> {$options -> {name}} eq $value -> {id};

		if (defined $options -> {detail}) {

			$value -> {onclick} .= js_detail ($options);

		}

		$value -> {type} ||= 'select' if $value -> {values};		
		$value -> {type} or next;
			
		local $value -> {attributes};
		$value -> {html} = call_from_file ("Eludia/Presentation/FormFields/$value->{type}.pm", "draw_form_field_$value->{type}", $value, $data);
		delete $value -> {attributes} -> {class};
						
	}

	return $_SKIN -> draw_form_field_radio (@_);
	
}

1;