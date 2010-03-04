sub draw_form_field_select {

	my ($options, $data) = @_;
	
	$options -> {max_len} ||= $conf -> {max_len};
	$options -> {attributes} -> {class} ||= $options -> {mandatory} ? 'form-mandatory-inputs' : 'form-active-inputs';	
	$options -> {attributes} -> {tabindex} = ++ $_REQUEST {__tabindex};

	if ($options -> {rows}) {
		$options -> {attributes} -> {multiple} = 1;	
		$options -> {attributes} -> {size} = $options -> {rows};	
	}

	foreach my $value (@{$options -> {values}}) {

		$value -> {selected} = 'selected' if (($value -> {id} eq $data -> {$options -> {name}}) or ($value -> {id} eq $options -> {value}));
		$value -> {label} = trunc_string ($value -> {label}, $options -> {max_len});
		$value -> {id} =~ s{\"}{\&quot;}g; #";
		delete $value -> {fake} if $value -> {fake} == 0;

	}

#	$options -> {onChange} = '' if defined $options -> {other} || defined $options -> {detail};

	if (defined $options -> {other}) {

		ref $options -> {other} or $options -> {other} = {href => $options -> {other}};
		
		$options -> {other} -> {label} ||= $i18n -> {voc};

		check_href ($options -> {other});

		$options -> {other} -> {href} =~ s{([\&\?])select\=\w+}{$1};
		$options -> {other} -> {href} =~ s{([\&\?])__tree\=\w+}{$1};

	}		

	if (defined $options -> {detail}) {

		$options -> {onChange} .= <<EOJS;
				if (this.options[this.selectedIndex].value && this.options[this.selectedIndex].value != -1) {
EOJS
		$options -> {onChange} .= js_detail ($options);
		
		$options -> {onChange} .= <<EOJS;
				}
EOJS

	
	}

	return $_SKIN -> draw_form_field_select (@_);
	
}

1;