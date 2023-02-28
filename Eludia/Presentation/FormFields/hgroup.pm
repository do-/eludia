sub draw_form_field_hgroup {

	my ($options, $data) = @_;

	foreach my $item (@{$options -> {items}}) {

		ref $item or $item = {name => $item};

		next if $item -> {type} eq 'br';
		next if $item -> {off} && $data -> {id};

		$item = _adjust_field ($item, $data);

		$item -> {label} .= ': ' if $item -> {label} && !$item -> {no_colon};

		if (($_REQUEST {__read_only} || $options -> {read_only} || $item -> {read_only}) && $item -> {type} ne 'button' && $item -> {type} ne 'multi_select') {

			if ($item -> {type} eq 'checkbox') {
				$item -> {value} = $data -> {$item -> {name}} || $item -> {checked} ? $i18n -> {yes} : $i18n -> {no};
			}
			if ($item -> {type} eq 'hgroup') {
				$item -> {value} = draw_form_field_of_type ($item, $data);
			}

			$item -> {type}   = 'static';

		}

		$item -> {mandatory} = exists $item -> {mandatory} ? $item -> {mandatory} : $options -> {mandatory};

		$item -> {type} ||= 'string';

		$item -> {html}   = draw_form_field_of_type ($item, $data);

	}

	return $_SKIN -> draw_form_field_hgroup (@_);

}

1;