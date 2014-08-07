sub draw_form_field_tree {

	my ($options, $data, $form_options) = @_;

	return '' if $options -> {off} && $data -> {id};

	my $key = '__get_ids_' . $options -> {name};

	$_REQUEST {$key} = 1;

	push @{$form_options -> {keep_params}}, $key;

	my $v = $options -> {value} || $data -> {$options -> {name}};

	$options -> {href} ||= {__edit => $_REQUEST {__edit}};

	check_href ($options);

	foreach my $value (@{$options -> {values}}) {

		if ($value -> {href}) {

			my $__last_query_string = $_REQUEST {__last_query_string};
			$_REQUEST {__last_query_string} = $options -> {no_no_esc} ? $__last_query_string : -1;
			check_href ($options);
			$options -> {href} .= '&__tree=1' unless ($options -> {no_tree} && $options -> {href} !~ /^javascript:/);
			$_REQUEST {__last_query_string} = $__last_query_string;

		}

		my $o = {
			label    => $value -> {label},
			id       => $value -> {id},
			parent   => $value -> {parent},
			is_radio => $value -> {is_radio} + $checked,
			icon     => $value -> {icon},
			iconOpen => $value -> {iconOpen},
			href     => $value -> {href},
		};

		$o -> {is_checkbox} = (grep {$_ eq $value -> {id}} @$v) > 0 ? 2 : 1 if $value -> {is_checkbox};

		$o -> {is_radio}    = $v == $value -> {id} ? 2 : 1 if $value -> {is_radio};

		our $i = $value;

		$value -> {__node} = draw_node ($o);

	}

	return $_SKIN -> draw_form_field_tree ($options, $data);

}

1;