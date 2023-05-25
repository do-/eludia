sub draw_toolbar_input_tree {

	my ($options, $data, $form_options) = @_;

	my $label = '';

	my $key = '__get_ids_' . $options -> {name};

	$_REQUEST {$key} = 1;

	push @{$form_options -> {keep_params}}, $key;

	foreach my $value (@{$options -> {values}}) {

		my $is_checked = $_REQUEST {"$options->{name}_$value->{id}"};

		$value -> {__node} = draw_node ({
			label       => $value -> {label},
			id          => $value -> {id},
			parent      => $value -> {parent},
			is_checkbox => $value -> {is_checkbox} + $is_checked,
			icon        => $value -> {icon},
			iconOpen    => $value -> {iconOpen},
			href        => $value -> {href},
		});

		if ($is_checked) {

			$label .= ', ' if $label;
			$label .= $value -> {label};

		}

	}

	$label = $options -> {label} if $options -> {label_fix};

	if ($label) {

		$options -> {max_len} ||= ($conf -> {max_len} || 20);

		$options -> {label} = trunc_string ($label, $options -> {max_len});

	}

	return $_SKIN -> draw_toolbar_input_tree ($options);

}

1;