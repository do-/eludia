sub draw_form_field_tree {

	my ($options, $data) = @_;
	
	return '' if $options -> {off} && $data -> {id};
	
	my $key = '__get_ids_' . $options -> {name};
	
	$_REQUEST {$key} = 1;
	
	push @{$form_options -> {keep_params}}, $key;

	my $v = $options -> {value} || $data -> {$options -> {name}};

	foreach my $value (@{$options -> {values}}) {
	
		my $checked = 0 + (grep {$_ eq $value -> {id}} @$v);
		
		if ($value -> {href}) {
	
			my $__last_query_string = $_REQUEST {__last_query_string};
			$_REQUEST {__last_query_string} = $options -> {no_no_esc} ? $__last_query_string : -1;
			check_href ($options);
			$options -> {href} .= '&__tree=1' unless ($options -> {no_tree} && $options -> {href} !~ /^javascript:/);
			$_REQUEST {__last_query_string} = $__last_query_string;
	
		}
		
		$value -> {__node} = draw_node ({
			label	=> $value -> {label},
			id	=> $value -> {id},
			parent	=> $value -> {parent},
			is_checkbox	=> $value -> {is_checkbox} + $checked,
			icon    	=> $value -> {icon},
			iconOpen    	=> $value -> {iconOpen},
			href  		=> $value -> {href},
		})

	}

	return $_SKIN -> draw_form_field_tree ($options, $data);
	
}

1;