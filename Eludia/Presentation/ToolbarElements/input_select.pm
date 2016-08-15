sub draw_toolbar_input_select {

	my ($options) = @_;

	$options -> {max_len} ||= $conf -> {max_len};

	if (defined $options -> {other}) {

		ref $options -> {other} or $options -> {other} = {href => $options -> {other}};

		$options -> {other} -> {label} ||= $i18n -> {voc};

		check_href ($options -> {other});
		$options -> {other} -> {href} =~ s{([\&\?])select\=\w+}{$1};

		if (0 == grep {$_ -> {other}} @{$options -> {values}}) {
			if ($options -> {other} -> {top}) {
				unshift @{$options -> {values}}, {id => -1, label => $options -> {other} -> {label}, other => 1};
			} else {
				push @{$options -> {values}}, {id => -1, label => $options -> {other} -> {label}, other => 1};
			}
		}
	}

	exists $options -> {empty} and 0 == grep {$_ -> {empty}} @{$options -> {values}} and unshift @{$options -> {values}}, {id => '', label => $options -> {empty}, empty => 1};

	$options -> {value} ||= exists $_REQUEST {$options -> {name}} ? $_REQUEST {$options -> {name}} : '';

	foreach my $value (@{$options -> {values}}) {
		$value -> {title}    = $value -> {label};
		$value -> {label}    = trunc_string ($value -> {label}, $options -> {max_len});
		$value -> {selected} = !$value -> {other} && $value -> {id} eq $options -> {value} ? 'selected' : '';
		delete $value -> {title} if ($value -> {title} eq $value -> {label});
	}

	$options -> {onChange} ||= 'submit();';

	$options -> {tabindex} = ++ $_REQUEST {__tabindex};

	return $_SKIN -> draw_toolbar_input_select ($options);

}

1;