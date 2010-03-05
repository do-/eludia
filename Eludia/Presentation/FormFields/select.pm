sub draw_form_field_select {

	my ($options, $data) = @_;
	
	$options -> {max_len} ||= $conf -> {max_len};

	foreach my $value (@{$options -> {values}}) {

		delete $value -> {fake} if $value -> {fake} == 0;
		
		$value -> {selected} = 'selected' if (($value -> {id} eq $data -> {$options -> {name}}) or ($value -> {id} eq $options -> {value}));

	}

	if (defined $options -> {other}) {

		ref $options -> {other} or $options -> {other} = {href => $options -> {other}};
		
		$options -> {other} -> {label} ||= $i18n -> {voc};

		check_href ($options -> {other});

		$options -> {other} -> {href} =~ s{([\&\?])select\=\w+}{$1};
		$options -> {other} -> {href} =~ s{([\&\?])__tree\=\w+}{$1};

	}		

	adjust_form_field_options ($options);

	return $_SKIN -> draw_form_field_select (@_);
	
}

1;