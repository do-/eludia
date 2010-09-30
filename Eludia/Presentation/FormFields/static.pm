sub draw_form_field_static {

	my ($options, $data) = @_;

	$options -> {crlf} ||= '; ';
		
	if ($options -> {add_hidden}) {
		$options -> {hidden_name}  ||= '_' . $options -> {name};
		$options -> {hidden_value} ||= $data    -> {$options -> {name}};
		$options -> {hidden_value} ||= $options -> {value};
		$options -> {hidden_value} =~ s/\"/\&quot\;/gsm; #";
	}	

	if ($options -> {href} && !$_REQUEST {__edit} && !$_REQUEST {xls} && !$_REQUEST {__only_field}) {
		check_href ($options);
	}
	else {
		delete $options -> {href};
	}
	
	my $value = defined $options -> {value} ? $options -> {value} : $data -> {$options -> {name}};

	my $static_value = '';
	
	if (($options -> {field} || '') =~ /^(\w+)\.(\w+)$/) {
			
		$options -> {values} = [map {{
			type   => 'static',
			id     => $_ -> {id},
			value  => $_ -> {file_name},
			href   => "/?type=$1&id=$_->{id}&action=download",
			target => 'invisible',
			fake   => $_ -> {fake},
		}} @{sql_select_all ("SELECT * FROM $1 WHERE fake = 0 AND $2 = ? ORDER BY id", $data -> {id})}];
		
		$value = [map {$_ -> {id}} @{$options -> {values}}];
	
	}
	
	if (ref $value eq ARRAY) {
	
		my %v = (map {$_ => 1} @$value);		

		foreach my $item (@{$options -> {values}}) {
		
			$v {$item -> {id}} or next;
			
			if ($item -> {type} || $item -> {name}) {
			
				if ($static_value) {

					$static_value =~ s{\s+$}{}sm;
					$static_value .= $options -> {crlf} if $static_value;

				}

				$static_value .= $item -> {label};
				$static_value .= ' ';

				$item -> {read_only} = 1;

				$static_value .= $item -> {type} =~ /^(hgroup|multi_select)$/ ?
					draw_form_field_of_type ($item, $data)
					: draw_form_field_static ($item, $data);
			
			}
			else {
				
				$static_value ||= [];
			
				push @$static_value, $item if $v {$item -> {id}};

				foreach my $ppv (@{$item -> {items}}) {
					if (@{$ppv -> {show_for}}+0) {
						$ppv -> {no_checkbox} = 0;
						foreach my $sf (@{$ppv -> {show_for}}) {
							$ppv -> {no_checkbox} = 1 if ($v {$sf});
						}
					}
					push @$static_value, $ppv if $v {$ppv -> {id}} || $ppv -> {no_checkbox};
				}
				
			}

		}
		
			
	}
	else {
	
		if (ref $options -> {values} eq ARRAY) {
		
			my $item = undef;			
					
			if (defined $value && $value ne '') {
			
				my $tied = tied @{$options -> {values}};
					
				if ($tied && !$tied -> {body}) {
				
					if ($value && $value != -1) {
						my $record = $tied -> _select_hash ($value);
						$static_value = $record -> {label};
						$options -> {fake} = $record -> {fake};
					}	
				
				}
				else {
			
					if ($value == 0) {

						foreach (@{$options -> {values}}) {

							next if $_ -> {id} ne $value;
							$item = $_;
							$static_value = $item -> {label};
							$options -> {fake} = $item -> {fake} if (defined $item -> {fake});
							last;

						}

					}
					else {

						foreach (@{$options -> {values}}) {

							next if $_ -> {id} != $value;
							$item = $_;
							$static_value = $item -> {label};
							$options -> {fake} = $item -> {fake} if (defined $item -> {fake});
							last;

						}

					}
					
				}
			
			}			
			
			if (($item -> {type} ||= '') eq 'hgroup') {
				$item -> {read_only} = 1;
				$static_value .= ' ';
				$static_value .= draw_form_field_of_type ($item, $data);
			}
			elsif ($item -> {type} eq 'multi_select') {
				$item -> {read_only} = 1;
				$static_value .= ' ';
				$static_value .= draw_form_field_of_type ($item, $data);
			}
			elsif ($item -> {type} || $item -> {name}) {
				$static_value .= ' ';
				$item -> {type} = 'static';
				$static_value .= draw_form_field_of_type ($item, $data);
			}

		}
		elsif (ref $options -> {values} eq HASH) {
			$static_value = $options -> {values} -> {$value};
		}
		elsif (ref $options -> {values} eq CODE) {
		
			if ($data -> {id}) {

				if ($value == 0) {

					$static_value = '';

				}
				else {

					my $id = $_REQUEST {id};
					$_REQUEST {id} = $value;
					my $h = &{$options -> {values}} ();
					$static_value = $h -> {label};
					$options -> {fake} = $h -> {fake};
					$_REQUEST {id} = $id;

				}

			}		
		
		}
		else {
		
			if (defined $options -> {value}) {

				$static_value = $options -> {value};

			}
			elsif ($options -> {name}) {

				$static_value = $data;
				$options -> {fake} = $data if ($options -> {name} =~ /\W/);

				foreach my $chunk (split /\W+/, $options -> {name}) {
					$static_value = $static_value -> {$chunk};					
					$options -> {fake} = $options -> {fake} -> {$chunk} if ($options -> {name} =~ /\W/ && defined $options -> {fake} -> {$chunk} && ref $options -> {fake} -> {$chunk} eq 'HASH');
				}

				$options -> {fake} = $options -> {fake} -> {fake} if ($options -> {name} =~ /\W/);

			}

		}
		
	}
		
	$options -> {value} = $static_value;		
	$options -> {value} = format_picture ($options -> {value}, $options -> {picture}) if $options -> {picture};

	$options -> {value} =~ s/\n/\<br\>/gsm;
	
	delete $options -> {values};

	return $_SKIN -> draw_form_field_static (@_);
			
}

1;