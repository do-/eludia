sub draw_string_voc_cell {

	my ($data, $options) = @_;

	$data -> {value} ||= $i -> {$data -> {name}};
	return draw_text_cell ($data, $options) if ($_REQUEST {__read_only} && !$data -> {edit}) || $data -> {read_only} || $data -> {off};
	
	$data -> {max_len} ||= $conf -> {max_len};

	_adjust_row_cell_style ($data, $options);

	
	foreach my $value (@{$data -> {values}}) {
		if (($value -> {id} eq $i -> {$data -> {name}}) or ($value -> {id} eq $data -> {value})) {			
 			$data -> {id} = $value -> {id};
			$data -> {label} = $value -> {label}; 
			$data -> {label} =~ s/\"/\&quot\;/gsm; #";			
			last;
		}
	}
	
	if (defined $data -> {other}) {

		ref $data -> {other} or $data -> {other} = {href => $data -> {other}};
		check_href ($data -> {other});

		$data -> {other} -> {param} ||= 'q';
		$data -> {other} -> {button} ||= '...';
		$data -> {other} -> {href} =~ s{([\&\?])select\=\w+}{$1};
		$data -> {other} -> {href} =~ s{([\&\?])__tree\=\w+}{$1};		
	}		
	
	return $_SKIN -> draw_string_voc_cell ($data, $options);
	
}

1;