sub draw_text_cell {

	my ($data, $options) = @_;

	return '' if ref $data eq HASH && $data -> {hidden};

	ref $data eq HASH or $data = {label => $data};

	_adjust_row_cell_style ($data, $options);

	if (defined $data -> {off}) {

		if ($data -> {off} eq 'if zero' && defined $data -> {label}) {

			$data -> {label} == 0 or delete $data -> {off};

		}
		elsif ($data -> {off} eq 'if not') {

			$data -> {label}      or delete $data -> {off};

		}

	}

	unless ($data -> {off}) {

		$data -> {max_len} ||= $data -> {size} || $conf -> {size}  || $conf -> {max_len} || 30;

		if (ref $data -> {values} eq ARRAY) {

			foreach (@{$data -> {values}}) {
				$_ -> {id} eq $data -> {value} or next;
				$data -> {label} = $_ -> {label};
				last;
			}

		}

		$data -> {attributes} -> {align} ||= 'right' if $options -> {is_total};

		check_title ($data, $options);

		if ($_REQUEST {select}) {

			$data -> {href}   = js_set_select_option ('', {
				id       => $i -> {id},
				label    => $options -> {select_label},
				question => $options -> {select_question},
			});

		}

		if ($data -> {href} && !$_REQUEST {lpt}) {
			check_href ($data) unless $data -> {no_check_href};
			$data -> {a_class} ||= $options -> {a_class} || 'row-cell';
			if ($data -> {no_wait_cursor}) {
				$data -> {onclick} = qq[onclick="window.document.body.onbeforeunload = function() {document.body.style.cursor = 'default';}; void(0);"];
			}
		}
		else {
			delete $data -> {href};
		}

		if ($data -> {add_hidden}) {
			$data -> {hidden_name}  ||= $data -> {name};
			$data -> {hidden_value} ||= $data -> {label};
			$data -> {hidden_value} =~ s/\"/\&quot\;/gsm; #";
		}

		if ($data -> {picture}) {
			$data -> {label} = format_picture ($data -> {label}, $data -> {picture});
			$data -> {attributes} -> {align} ||= 'right';
		}
		else {
			$data -> {label} = trunc_string ($data -> {label}, $data -> {max_len});
		}

		exists $options -> {strike} or !exists $i -> {fake} or $data -> {strike} ||= $i -> {fake} < 0;


		if (@{$data -> {context_menu}}) {

			local $_SKIN -> {__current_row} -> {__types} = [];

			foreach my $item (@{$data -> {context_menu}}) {
				call_from_file ("Eludia/Presentation/TableCells/button.pm", "draw_button_cell", $item);
			}

			$data -> {__context_menu} = draw_vert_menu ($data, $_SKIN -> {__current_row} -> {__types});

		}

	}

	return $_SKIN -> draw_text_cell ($data, $options);

}

1;