sub draw_form_field_string_voc {

	my ($options, $data) = @_;
	
	$options -> {max_len} ||= $conf -> {max_len};
	$options -> {attributes} -> {class} ||= $options -> {mandatory} ? 'form-mandatory-inputs' : 'form-active-inputs';	
	$options -> {attributes} -> {tabindex} = ++ $_REQUEST {__tabindex};
	$options -> {size}    ||= 50;
	$options -> {attributes} -> {size}      = $options -> {size};

	foreach my $value (@{$options -> {values}}) {

		if (($value -> {id} eq $data -> {$options -> {name}}) or ($value -> {id} eq $options -> {value})) {
			$options -> {attributes} -> {value} = trunc_string ($value -> {label}, $options -> {max_len});
			$value -> {id} =~ s{\"}{\&quot;}g; #";
			$options -> {id} = $value -> {id};
			last; 
		}

	}
	$options -> {onChange} = '';

	if (defined $options -> {other}) {

		ref $options -> {other} or $options -> {other} = {href => $options -> {other}};

		check_href ($options -> {other});

		$options -> {other} -> {param} ||= 'q';
		$options -> {other} -> {href} =~ s{([\&\?])select\=\w+}{$1};
		$options -> {other} -> {href} =~ s{([\&\?])__tree\=\w+}{$1};

	}


	if (defined $options -> {detail}) {

		$options -> {onChange} .= js_detail ($options);

	}

	$options -> {attributes} -> {name}  = '_' . $options -> {name} . '_label';

	return $_SKIN -> draw_form_field_string_voc (@_);
	
}

1;