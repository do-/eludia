sub draw_form_field_checkboxes {

	my ($options, $data, $form_options) = @_;

	$options -> {cols} ||= 1;

	if (!ref $data -> {$options -> {name}}) {
	
		$data -> {$options -> {name}} = [grep {$_} split /\,/, $data -> {$options -> {name}}];
		
	}
	
	my $key = '__get_ids_' . $options -> {name};
	
	$_REQUEST {$key} = 1;
	
	push @{$form_options -> {keep_params}}, $key;
	
	my $value = $data -> {$options -> {name}};
	
	my %values = ();
	
	%values = map {$_ => 1} @$value if ref $value eq ARRAY;

	foreach my $value (@{$options -> {values}}) {

		$value -> {type} ||= 'checkboxes' if $value -> {items};
		
		if ($value -> {type} eq 'checkboxes') {
			$value -> {values} = $value -> {items};
			$value -> {inline} = 1;
			$value -> {name} = $options -> {name} if $value;
		};

		$value -> {checked} = 1 if $values {$value -> {id}};

		$value -> {type} or next;

		$value -> {attributes} -> {tabindex} = ++ $_REQUEST {__tabindex};

		$value -> {html} = draw_form_field_of_type ($value, $data);
		$value -> {html} =~ s/\<input/&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\<input/g if ($value -> {type} eq 'checkboxes');
		
		delete $value -> {attributes} -> {class};
						
	}

	return $_SKIN -> draw_form_field_checkboxes (@_);
	
}

1;