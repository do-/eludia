no warnings;

################################################################################

sub js ($)    {$_REQUEST {__script} .= ";\n$_[0];\n"; return ''}

sub j  ($)    {js "\$(document).ready (function () { $_[0] })"}

################################################################################

sub json_dump_to_function {

	my ($name, $data) = @_;

	return "\n function $name () {\n return " . $_JSON -> encode ($data) . "\n}\n";

}

################################################################################

sub is_off {
	
	my ($options, $value) = @_;
	
	return 0 unless $options -> {off};
	
	if ($options -> {off} eq 'if zero') {
		return ($value == 0);
	}
	elsif ($options -> {off} eq 'if not') {
		return !$value;
	}
	else {
		return $options -> {off};
	}

}

################################################################################

sub action_type_label (;$$) {
	
	my ($action, $type) = @_;
	
	$i18n -> {_actions} -> {$type || $_REQUEST {type}} -> {$action};

}

################################################################################

sub __d {

	my ($data, @fields) = @_;

	unless (@fields + 0) {
		@fields = grep {/(_|\b)dt(_|\b)/} keys %$data;
	}

	foreach (@fields) {

		if ($preconf -> {core_fix_tz} && $data -> {$_} !~ /^0000-00-00/ && $data -> {$_} =~ /^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})$/) {
			$data -> {$_} = sprintf ('%04d-%02d-%02d %02d:%02d:%02d', Date::Calc::Add_Delta_DHMS ($1, $2, $3, $4, $5, $6, 0, - $_USER -> {tz_offset} + 0 || 0, 0, 0));
		}

		$data -> {$_} =~ s{(\d\d\d\d)-(\d\d)-(\d\d)}{$3.$2.$1};
		$data -> {$_} =~ s{00\.00\.0000}{};
						
	}
	
	return $data;
		
}

###############################################################################

sub format_picture {

	my ($txt, $picture) = @_;
	
	return '' if $txt eq '';
	
	return $txt if ($_REQUEST {xls});
	
	my $result = $number_format -> format_picture ('' . $txt, $picture);
	
	if ($_USER -> {demo_level} > 1) {
		$result =~ s{\d}{\*}g;
	}
	
	$result =~ s{^\s+}{};

	return $result;

}

################################################################################

sub js_ok_escape {
	return '';
}

################################################################################

sub js_escape {
	my ($s) = @_;	
	$s =~ s/\"/\'/gsm; #"
	$s =~ s{[\n\r]+}{ }gsm;
	$s =~ s{\\}{\\\\}g;
	$s =~ s{\'}{\\\'}g; #'
	return "'$s'";
}

################################################################################

sub register_hotkey {

	my ($hashref, $type, $data, $options) = @_;
	
	my $code = $_SKIN -> register_hotkey ($hashref) or return;
	
	push @scan2names, {
		code => $code,
		type => $type,
		data => $data,
		ctrl => $options -> {ctrl},
		alt  => $options -> {alt},
	};

}

################################################################################

sub hotkeys {
	foreach (@_) { hotkey ($_) };
}

################################################################################

sub hotkey {

	my ($def) = $_[0];
			
	$def -> {type} ||= 'href';

	if ($def -> {code} =~ /^F(\d+)/) {
		$def -> {code} = 111 + $1;
	}
	elsif ($def -> {code} =~ /^ESC$/i) {
		$def -> {code} = 27;
	}
	elsif ($def -> {code} =~ /^DEL$/i) {
		$def -> {code} = 46;
	}
	elsif ($def -> {code} =~ /^ENTER$/i) {
		$def -> {code} = 13;
	}
	
	push @scan2names, $def;
	
}

################################################################################

sub trunc_string {

	my ($s, $len) = @_;

	return $s if $_REQUEST {xls};
	
	my $cached = $_REQUEST {__trunc_string} -> {$s, $len};
	
	return $cached if $cached;
	
	my $length = length $s;
	
	return $s if $length <= $len;
	
	my $has_ext_chars = $s =~ y/\200-ї/\200-ї/;
	
	$s = decode_entities ($s) if $has_ext_chars;
	$s = substr ($s, 0, $len - 3) . '...' if length $s > $len;
	$s = encode_entities ($s, "‚„-‰‹‘-™›\xA0¤¦§©«-®°-±µ-·»") if $has_ext_chars;
	
	$_REQUEST {__trunc_string} -> {$s, $len} = $s;

	return $s;
	
}

################################################################################

sub esc_href {

	my $href = 
				
		session_access_log_get ($_REQUEST {__last_last_query_string})

		|| "/?type=$_REQUEST{type}"
		
	;

	if (exists $_REQUEST {__last_scrollable_table_row} && !$_REQUEST {__windows_ce}) {
		$href =~ s{\&?__scrollable_table_row\=\d*}{}g;
		$href .= "&__scrollable_table_row=$_REQUEST{__last_scrollable_table_row}";
	}

	$href = check_href ({href => $href}, 1);

	return "${href}&__next_query_string=$_REQUEST{__last_query_string}";

}

################################################################################

sub create_url {
	return check_href ({href => {@_}});
}

################################################################################

sub hrefs {

	my ($order, $options) = @_;

	unless (ref $options eq 'HASH') {
		$options -> {kind} = $options;
	}

	my $name_order = $options -> {suffix} ? "order_$$options{suffix}" : 'order';
	my $name_desc  = $options -> {suffix} ? "desc_$$options{suffix}"  : 'desc';

	return $order ?
		$options -> {kind} == 1 ?
			(
				href      => create_url ($name_order => $order, $name_desc => $order eq $_REQUEST {$name_order} ? 1 - $_REQUEST {$name_desc} : 0, __last_last_query_string => $_REQUEST {__last_last_query_string}),
			)
		:	
			(
				href      => create_url ($name_order => $order, $name_desc => 0, __last_last_query_string => $_REQUEST {__last_last_query_string}),
				href_asc  => create_url ($name_order => $order, $name_desc => 0, __last_last_query_string => $_REQUEST {__last_last_query_string}),
				href_desc => create_url ($name_order => $order, $name_desc => 1, __last_last_query_string => $_REQUEST {__last_last_query_string}),
			)
	:
		();
	
}

################################################################################

sub headers {

	my @result = ();
	
	while (@_) {
	
		my $label = shift;
		$label =~ s/_/ /g;

		my $order;
		$order = shift if $label ne ' ';
		
		push @result, {label => $label, hrefs ($order)};
	
	}
	
	return \@result;

}

################################################################################

sub order {

	my $options;

	if (ref $_ [-1] eq HASH) {
		$options = pop;
	}
	elsif (ref $_ [0] eq HASH) {
		$options = shift;
	}

	my $default = shift;

	my $result;

	my $name_order = $options -> {suffix} ? "order_$$options{suffix}" : 'order';
	my $name_desc  = $options -> {suffix} ? "desc_$$options{suffix}"  : 'desc';
	
	my @default_order;
	check___query ();

	while (@_) {
		my $name  = shift;
		my $sql   = shift;
		
		$default_order [$_QUERY -> {content} -> {columns} -> {$name} -> {sort}] = {name => $name, sql => $sql} 
			if (exists $_QUERY -> {content} -> {columns} -> {$name} && $_QUERY -> {content} -> {columns} -> {$name} -> {sort});
			
		$name eq $_REQUEST {$name_order} or next;
		$result   = $sql;
		last;
	}

	if (!$result && @default_order + 0) {
		foreach my $order (@default_order) {

			next 
				unless $order;
			
			
			unless ($_QUERY -> {content} -> {columns} -> {$order -> {name}} -> {desc}) {
			
				$order -> {sql} =~ s{(?<=SC)\!}{}g;
				$result .= ','
					if $result;
				$result .= ' ' . $order -> {sql};
				
				next;
			}
			
			
			my @new = ();
			
			foreach my $token (split /\s*\,\s*/gsm, $order -> {sql}) {
			
				unless ($token =~ s{\!$}{}) {
		
					unless ($token =~ s{DESC$}{}i) {
		
						$token =~ s{ASC$}{}i;
						$token .= ' DESC';
		
					}
		
				}
			
				push @new, $token;
			
			}
			
			$result .= ','
				if $result;

			$result .= ' ' . join ', ', @new;
			
		}

		return $result;
	
	}

	$result ||= $default;

	unless ($_REQUEST {$name_desc}) {
		$result =~ s{(?<=SC)\!}{}g;
		return $result;
	}
	
	
	my @new = ();
	
	foreach my $token (split /\s*\,\s*/gsm, $result) {
	
		unless ($token =~ s{\!$}{}) {

			unless ($token =~ s{DESC$}{}i) {

				$token =~ s{ASC$}{}i;
				$token .= ' DESC';

			}

		}
	
		push @new, $token;
	
	}
	
	return join ', ', @new;


}

################################################################################

sub check_title {

	my ($options) = @_;

	return if exists $options -> {title} && $options -> {title} eq '';

	$options -> {title} ||= '' . $options -> {label};
	$options -> {title} =~ s{\<.*?\>}{}g;	
	$options -> {title} =~ s{^(\&nbsp\;)+}{};	
	$options -> {title} =~ s{\"}{\&quot\;}g;	
	$options -> {attributes} -> {title} = $options -> {title};
	$options -> {title} = qq{title="$$options{title}"} if length $options -> {title}; #"

}

################################################################################

sub check_href {

	my ($options) = @_;
	
	my $href = $options -> {href};
	
	my %h = ();
	
	if (ref $href eq HASH) {
		
		if ($_REQUEST_TO_INHERIT) {
		
			%h = %$_REQUEST_TO_INHERIT;

		}
		else {

			foreach my $k (keys %_REQUEST) {

				next if $k =~ /^_/ && !$_INHERITABLE_PARAMETER_NAMES -> {$k};
				next if             $_NONINHERITABLE_PARAMETER_NAMES -> {$k};
				$h {$k} = uri_escape ($_REQUEST {$k});

			}
			
			$_REQUEST_TO_INHERIT = {%h};

		}		
		
		foreach my $k (keys %$href) {
		
			$h {$k} = $href -> {$k};
			
		}
		
	}
	else {
			
		return $href if ($href =~ /\#$/ || $href =~ /^(java|mailto|file|\/i\/)/);

		$href = uri_escape ($href, "\x7f-\xff") if MP2 && $href =~ /[\x7f-\xff]/;
		
		if ($href =~ /\?/) {$href = $'};

		foreach my $token (split /\&/, $href) {
		
			$token =~ /\=/ or next;
			
			$h {$`} = $';
			
		}
		
		foreach my $name (@_OVERRIDING_PARAMETER_NAMES) {
			
			$_REQUEST {$name} or next;

			$h {$name} ||= $_REQUEST {$name};
			
		}
								
	}
	
	$_REQUEST {__salt}     ||= rand () * time ();
	
	unless ($_REQUEST {__uri_root}) {
	
		$_REQUEST {__uri_root} = $_REQUEST{__uri};
		
		if ($_REQUEST {__script_name} && $ENV {GATEWAY_INTERFACE} !~ /^CGI-PerlEx/) {
		
			$_REQUEST {__uri_root} .= $_REQUEST{__script_name};
		
		}
		
		$_REQUEST {__uri_root} .= "?salt=$_REQUEST{__salt}&sid=$_REQUEST{sid}";

	}	

	my $url = $_REQUEST {__uri_root};
				
	foreach my $k (keys %h) {

		defined (my $v = $h {$k || next}) or next;

		next if !$v and $_NON_VOID_PARAMETER_NAMES -> {$k};
		
		$url .= "&$k=$v";
		
	}

	if ($h {action} eq 'download' || $h {xls}) {
		$options -> {no_wait_cursor} = 1;
	}
    
	if ($options -> {dialog}) {
	
		$url =
			dialog_open ({
				
				title => $options -> {dialog} -> {title},
				
				href => $url . '#',
					
			}, $options -> {dialog} -> {options}) .
			$options -> {dialog} -> {after} .
			';setCursor (); try {top.setCursor (top)} catch (e) {}; void (0)';

		if ($options -> {dialog} -> {before}) {
			$url =~ s/^javascript:/javascript: $options->{dialog}->{before};/i;
		}

	}

	$options -> {href} = $url;

	return $url;

}

################################################################################

sub draw_auth_toolbar {

	return '' if $_REQUEST {__no_navigation} or $_REQUEST {__tree} or $conf -> {core_no_auth_toolbar};

	return $_SKIN -> draw_auth_toolbar ({
		top_banner => ($conf -> {top_banner} ? interpolate ($conf -> {top_banner}) : ''),
		user_label  => $_USER -> {__label} || $i18n -> {User} . ': ' . ($_USER -> {label} || $i18n -> {not_logged_in}) . $_REQUEST{__add_user_label},
	});
			
}

################################################################################

sub draw_hr {

	my (%options) = @_;
		
	$options {height} ||= 1;
	$options {class}  ||= bgr8;
	
	return $_SKIN -> draw_hr (\%options);
		
}

################################################################################

sub draw_window_title {

	my ($options) = @_;
	
	return '' if $options -> {off};
	
	our $__last_window_title = $options -> {label};
		
	return $_SKIN -> draw_window_title (@_);

}

################################################################################

sub draw_logon_form {

	my ($options) = @_;

	if ($options -> {hta}) {
	
		$_REQUEST {__script} .= json_dump_to_function (hta => $options -> {hta});				
	
	}
			
	return $_SKIN -> draw_logon_form (@_);

}

################################################################################

sub adjust_esc {

	my ($options, $data) = @_;
	
	$data ||= $_REQUEST {__page_content};

	if (
		$_REQUEST {__edit} 
		&& !$_REQUEST{__from_table} 
		&& !(ref $data eq HASH && $data -> {fake} > 0)
	) {
		$options -> {esc} = create_url (
			__last_query_string => $_REQUEST {__last_last_query_string},
			__last_scrollable_table_row => $_REQUEST {__windows_ce} ? undef : $_REQUEST {__last_scrollable_table_row},
		);
	}	
	elsif ($_REQUEST {__last_query_string}) {
		$options -> {esc} ||= esc_href ();
	}

}

################################################################################

sub draw_form {

	my ($options, $data, $fields) = @_;
	
	return '' if $options -> {off} && $data;

	$options -> {hr} = defined $options -> {hr} ? $options -> {hr} : 10;
	$options -> {hr} = $_REQUEST {__tree} ? '' : draw_hr (height => $options -> {hr});
	
	if (ref $data eq HASH && $data -> {fake} == -1 && !exists $options -> {no_edit}) {
		$options -> {no_edit} = 1;
	}
	
	$options -> {data} = $data;
	
	$options -> {name}    ||= 'form';
	
	!$_REQUEST {__only_form} or $_REQUEST {__only_form} eq $options -> {name} or return '';

	$options -> {no_esc}    = 1 if $apr -> param ('__last_query_string') < 0 && !$_REQUEST {__edit};
	$options -> {target}  ||= 'invisible';	
	$options -> {method}  ||= 'post';
	$options -> {target}  ||= 'invisible';	
	$options -> {action}    = 'update' unless exists $options -> {action};
	
	$_REQUEST {__form_options} = $options;
	$_REQUEST {__form_checkboxes} = '';

	adjust_esc ($options, $data);
	
	our $tabindex = 1;

	my @rows = ();

	foreach my $field (@$fields) {
		
		my $row;
		
		if (ref $field eq ARRAY) {
			my @row = ();
			foreach (@$field) {
				next if $_ -> {off} && $data -> {id};
				next if $_REQUEST {__read_only} && $_ -> {type} eq 'password';
				push @row, $_;
			}
			next if @row == 0;
			$row = \@row;
		}
		else {
			next if $field -> {off} && $data -> {id};
			next if $_REQUEST {__read_only} && $field -> {type} eq 'password';
			$row = [$field];
		}
		
		push @rows, $row;

	}
	
	my $max_colspan = 1;
	
	foreach my $row (@rows) {
		my $sum_colspan = 0;
		for (my $i = 0; $i < @$row; $i++) {
			$row -> [$i] -> {form_name} = $options -> {name};
			$row -> [$i] -> {colspan} ||= 1;
			$sum_colspan += $row -> [$i] -> {colspan};
			$sum_colspan ++ 
				unless ($row -> [$i] -> {label_off});
			next if $i < @$row - 1;
			$row -> [$i] -> {sum_colspan} = $sum_colspan;
		}
		$max_colspan > $sum_colspan or $max_colspan = $sum_colspan;
	}

	$_SKIN -> start_form () if $_SKIN -> {options} -> {no_buffering};

	foreach my $row (@rows) {
		$row -> [-1] -> {colspan} += ($max_colspan - $row -> [-1] -> {sum_colspan});
		$_SKIN -> start_form_row () if $_SKIN -> {options} -> {no_buffering};
		foreach (@$row) { $_ -> {html} = draw_form_field ($_, $data, $options) };
		$_SKIN -> draw_form_row ($row) if $_SKIN -> {options} -> {no_buffering};
	}
	
	$options -> {rows} = \@rows;
	
	$options -> {path} ||= $data -> {path};
				
	$options -> {path} = ($options -> {path} && !$_REQUEST{__no_navigation}) ? draw_path ($options, $options -> {path}) : '';
	
	delete $options -> {menu} if $_REQUEST {__edit};
	if ($options -> {menu}) {	
		$options -> {menu} = [ grep {!$_ -> {off}} @{$options -> {menu}} ];
	}
	delete $options -> {menu} if @{$options -> {menu}} == 0;
		
	if ($options -> {menu}) {
		
		foreach my $item (@{$options -> {menu}}) {
				
			if ($item -> {type}) {
				$item -> {href} = {type => $item -> {type}, start => ''};
				$item -> {is_active} = $item -> {type} eq $_REQUEST {type} ? 1 : 0;
			}
			else {
				$item -> {is_active} += 0;
			}
		
			check_href ($item);

			if (!exists $item -> {keep_esc}) {
						
				$item -> {href} =~ s{\&?__last_query_string=\d*}{}gsm;
				$item -> {href} .= "&__last_query_string=$_REQUEST{__last_last_query_string}";

				$item -> {href} =~ s{\&?__last_scrollable_table_row=\d*}{}gsm;
				$item -> {href} .= "&__last_scrollable_table_row=$_REQUEST{__last_scrollable_table_row}" unless ($_REQUEST {__windows_ce});
			
			}

			if ($item -> {hotkey}) {
				hotkey ({
					%{$item -> {hotkey}},
					data => $item,
					type => 'href',
				});
			}			
			
		}
	
	
	} 

	unless (exists $options -> {bottom_toolbar}) {
	
		$options -> {bottom_toolbar} =
			($_REQUEST {__no_navigation} && !$_REQUEST {select}) ? draw_close_toolbar ($options) :
			$options -> {back} ? draw_back_next_toolbar ($options) :
			$options -> {no_ok} ? draw_esc_toolbar ($options) :
			draw_ok_esc_toolbar ($options, $data);

	}
	
	delete $_REQUEST {__form_options};

	my   @keep_params = map {{name => $_, value => $_REQUEST {$_}}} @{$options -> {keep_params}};
	push @keep_params, {name  => 'sid',                         value => $_REQUEST {sid}                         };
	push @keep_params, {name  => 'select',                      value => $_REQUEST {select}                      };
	push @keep_params, {name  => '__no_navigation',             value => $_REQUEST {__no_navigation}             };
	push @keep_params, {name  => '__tree',                      value => $_REQUEST {__tree}                      };
	push @keep_params, {name  => 'type',                        value => $options -> {type} || $_REQUEST {type}  };
	push @keep_params, {name  => 'id',                          value => $options -> {id} || $_REQUEST {id}      };
	push @keep_params, {name  => 'action',                      value => $options -> {action}                    };
	push @keep_params, {name  => '__last_query_string',         value => $_REQUEST {__last_last_query_string}    };
	push @keep_params, {name  => '__form_checkboxes',           value => $_REQUEST {__form_checkboxes}           } if $_REQUEST {__form_checkboxes};
	push @keep_params, {name  => '__last_scrollable_table_row', value => $_REQUEST {__last_scrollable_table_row} } unless ($_REQUEST {__windows_ce});
	
	foreach my $key (keys %_REQUEST) {
	
		$key =~ /^__checkboxes_/ or next;			

		push @keep_params, {name => $key, value => $_REQUEST {$key} };
	
	}

	$options -> {keep_params} = \@keep_params;	
		
	return $_SKIN -> draw_form ($options);

}

################################################################################

sub _adjust_field {

	my ($field, $data) = @_;

	my $table_def = $DB_MODEL -> {tables} -> {$_REQUEST {__the_table} ||= $_REQUEST {type}};
	
	if ($table_def) {
	
		my $field_def = $table_def -> {columns} -> {$field -> {name}};

		if ($field_def) {
		
			my %field_options = %{$field_def -> {FIELD_OPTIONS} || {}};
			
			$field_options {type}  ||= $field_def -> {TYPE};
			
			$field_options {label} ||= $field_def -> {REMARKS};
		
			$field_options {label} ||= $field_def -> {label};

			%$field = (%field_options, %$field);
		
		}
	
	}

	$field -> {data_source} and $field -> {values} ||= ($data -> {$field -> {data_source}} ||= sql_select_vocabulary ($field -> {data_source}));
	
	return $field;

}

################################################################################

sub draw_form_field {

	my ($field, $data, $form_options) = @_;
	
	$field = _adjust_field ($field, $data);

	if (
		($_REQUEST {__read_only} or $field -> {read_only})
	 	 &&  $field -> {type} ne 'hgroup'
	 	 &&  $field -> {type} ne 'banner'
	 	 &&  $field -> {type} ne 'article'
	 	 &&  $field -> {type} ne 'iframe'
	 	 &&  $field -> {type} ne 'color'
	 	 &&  $field -> {type} ne 'multi_select'
	 	 &&  $field -> {type} ne 'dir'
		 && ($field -> {type} ne 'text'    || !$conf -> {core_keep_textarea})
		 && ($field -> {type} ne 'suggest' || !$_REQUEST {__suggest})
	)
	{
		
		if ($field -> {type} eq 'file') {
			$field -> {href}      ||= {action => 'download', _name => $field -> {name}};
			$field -> {file_name} ||= $field -> {name} . '_name';
			$field -> {name}        = $field -> {file_name};
			$field -> {target}    ||= 'invisible';
		}
		elsif ($field -> {type} eq 'checkbox') {
			$field -> {value} = $data -> {$field -> {name}} || $field -> {checked} ? $i18n -> {yes} : $i18n -> {no};
		}
		elsif ($field -> {type} eq 'tree') {
			$field -> {value} ||= $data -> {$field -> {name}} || [map {$_ -> {id}} grep {$_ -> {is_checkbox} > 1} @{$field -> {values}}];
		}
		elsif ($field -> {type} eq 'checkboxes') {
	
			$data -> {$field -> {name}} = [grep {$_} split /\,/, $data -> {$field -> {name}}] unless (ref $data -> {$field -> {name}});

			my $values = $field -> {values};
			my @spaces = (@$values + 0);
			delete $field -> {values};

			while (my $value = shift @$values) {
                                $value -> {label} = "&nbsp; " x (2 * (@spaces - 1)) . $value -> {label};

				if ($value -> {items}) {
					unshift @spaces, @{$value -> {items}} + 0;
					unshift @$values, @{$value -> {items}};
					delete $value -> {items};
				}

				if (@spaces[0]) {
					@spaces[0] -= 1;
				} else {
					shift @spaces;
				};


				push @{$field -> {values}}, $value;
			}

		}
		else {
			$field -> {value} ||= $data -> {$field -> {name}};
		}	
		
		
		$field -> {type} = 'static';
		
	}	

	$field -> {type} ||= 'string';
	
	if ($_REQUEST {__only_field}) {
	
		my @fields = split (',', $_REQUEST {__only_field});

		if ($field -> {type} eq 'hgroup') {
			my $html = '';
			foreach (@{$field -> {items}}) {$html .= draw_form_field ($_, $data)}
			return $html;
		}
		elsif ($field -> {type} eq 'radio') {
			my $html = '';
			foreach (@{$field -> {values}}) {$html .= draw_form_field ($_, $data)}
			return $html;
		}
		else {
			(grep {$_ eq $field -> {name}} @fields) > 0 or return '';
		}

	}

	$field -> {tr_id}  = 'tr_' . $field -> {name};

	$field -> {html} = &{"draw_form_field_$$field{type}"} ($field, $data, $form_options);

	$conf -> {kb_options_focus} ||= $conf -> {kb_options_buttons};
	$conf -> {kb_options_focus} ||= {ctrl => 1, alt => 1};

	register_hotkey ($field, 'focus', '_' . $field -> {name}, $conf -> {kb_options_focus});

	$field -> {label} .= $field -> {label} ? ':' : '&nbsp;';

	$field -> {colspan} ||= $_REQUEST {__max_cols} - 1;

	$field -> {state}     = $data -> {fake} == -1 ? 'deleted' : $_REQUEST {__read_only} ? 'passive' : 'active';

	$field -> {label_width} = '20%' unless $field -> {is_slave};	

	return $_REQUEST {__only_field} ? $_JS_SKIN -> draw_form_field ($field) : $_SKIN -> draw_form_field ($field);

}

################################################################################

sub draw_path {

	my ($options, $list) = @_;

	return '' if $_REQUEST {lpt};
	return '' unless $list;
	return '' unless ref $list eq ARRAY;
	$list = [grep {!$_ -> {off}} @$list];
	return '' unless @$list > 0;

	$options -> {id_param} ||= 'id';
	$options -> {max_len}  ||= $conf -> {max_len};
	$options -> {max_len}  ||= 30;
	$options -> {nowrap}   = exists $options -> {nowrap} ? $options -> {nowrap} : 
								$options -> {multiline} ? '' : 
								'nowrap';

	if ($_SKIN -> {options} -> {home_esc_forward}) {
	
		adjust_esc ($options);
		
		if ($_REQUEST {__next_query_string}) {
		
			$options -> {forward} = session_access_log_get ($_REQUEST {__next_query_string}) . "&sid=$_REQUEST {sid}";

		}
	
	}
	
	$_REQUEST {__path} = [];
	
	for (my $i = 0; $i < @$list; $i ++) {		
	
		my $item = $list -> [$i];
	
		$item -> {label}      = trunc_string ($item -> {label} || $item -> {name}, $options -> {max_len});
		$item -> {id_param} ||= $options -> {id_param};		
		$item -> {cgi_tail} ||= $options -> {cgi_tail};
		
		$item -> {cgi_tail} .= '&__tree=1'
			if ($_REQUEST {__tree});
			
		unless ($options -> {no_path_href} || $_REQUEST {__edit} || $i == @$list - 1) {
			$item -> {href} = "/?type=$$item{type}&$$item{id_param}=$$item{id}&$$item{cgi_tail}";
			check_href ($item);
			push @{$_REQUEST {__path}}, $item -> {href};
		}
	
	}
	
	return $_SKIN -> draw_path ($options, $list);
	
}

################################################################################

sub draw_form_field_banner {

	my ($field, $data) = @_;
	return $_SKIN -> draw_form_field_banner (@_);

}

################################################################################

sub draw_form_field_article {

	my ($field, $data) = @_;

	$field -> {value} ||= $data -> {$field -> {name}};

	return $_SKIN -> draw_form_field_article (@_);

}

################################################################################

sub draw_form_field_button {

	my ($options, $data) = @_;
	$options -> {value} ||= $data -> {$options -> {name}};
	$options -> {value} =~ s/\"/\&quot\;/gsm; #"

	return $_SKIN -> draw_form_field_button (@_);

}

################################################################################

sub draw_form_field_string {

	my ($options, $data) = @_;
	
	my $value = ($options -> {value} ||= $data -> {$options -> {name}});
		
	if ($options -> {picture}) {
	
		$value = format_picture ($value, $options -> {picture});
		
		$value =~ s/^\s+//g;
		
	}
	
	if ($value =~ y/"/"/) {
	
		$value =~ s{\"}{\&quot;}gsm;
	
	}
	
	my $attributes = ($options -> {attributes} ||= {});

	$attributes -> {value}        = \$value;
	
	$attributes -> {name}         = '_' . $options -> {name};
			
	$attributes -> {size}         = ($options -> {size} ||= 120);

	$attributes -> {maxlength}    = $options -> {max_len} || $options -> {size} || 255;

	$attributes -> {class}      ||= $options -> {mandatory} ? 'form-mandatory-inputs' : 'form-active-inputs';
	
	$attributes -> {autocomplete} = 'off' unless exists $attributes -> {autocomplete};

	$attributes -> {tabindex}     = ++ $_REQUEST {__tabindex};

	return $_SKIN -> draw_form_field_string (@_);
	
}

################################################################################

sub draw_form_field_suggest {

	my ($options, $data) = @_;

	$options -> {max_len} ||= $options -> {size};
	$options -> {max_len} ||= 255;
	$options -> {attributes} -> {maxlength} = $options -> {max_len};
	$options -> {attributes} -> {class} ||= $options -> {mandatory} ? 'form-mandatory-inputs' : 'form-active-inputs';


	$options -> {size}    ||= 120;
	$options -> {attributes} -> {size}      = $options -> {size};
	$options -> {lines}   ||= 10;
	
	$options -> {value}   ||= $data -> {$options -> {name}};
	$options -> {value__id} = $options -> {value};

	my $id = $_REQUEST {id};
	
	if ($data -> {id}) {
	
		if ($options -> {value} == 0) {
		
			$options -> {value} = '';
		
		}
		else {

			$_REQUEST {id} = $options -> {value};
			my $h = &{$options -> {values}} ();
			$options -> {value} = $h -> {label} if ref $h eq HASH;
			$_REQUEST {id} = $id;

		}

	}
	elsif ($_REQUEST {__suggest} eq $options -> {name}) {
	
		our $_SUGGEST_SUB = $options -> {values};
	
	}
	
	$options -> {value} =~ s/\"/\&quot\;/gsm; #";
	
	$options -> {attributes} -> {value} = $options -> {value};	
	$options -> {attributes} -> {name}  = '_' . $options -> {name};
	$options -> {attributes} -> {tabindex} = ++ $_REQUEST {__tabindex};

	return $_SKIN -> draw_form_field_suggest (@_);
	
}

################################################################################

sub draw_form_field_date {

	my ($_options, $data) = @_;	
	$_options -> {no_time} = 1;	
	return draw_form_field_datetime ($_options, $data);

}

################################################################################

sub draw_form_field_datetime {

	my ($options, $data) = @_;

	if ($r -> headers_in -> {'User-Agent'} =~ /MSIE 5\.0/) {
		$options -> {size} ||= $options -> {no_time} ? 11 : 16;
		return draw_form_field_string ($options, $data);
	}	

	unless ($options -> {format}) {
	
		if ($options -> {no_time}) {
			$options -> {format}  ||= $i18n -> {_format_d} || '%d.%m.%Y';
			$options -> {size}    ||= 11;
		}
		else {
			$options -> {format}  ||= $i18n -> {_format_dt} || '%d.%m.%Y %k:%M';
			$options -> {size}    ||= 16;
		}
	
	}
		
	$options -> {attributes} -> {size}      = $options -> {size};
	$options -> {attributes} -> {maxlength} = $options -> {size};

	$options -> {value}   ||= $data -> {$options -> {name}};
	$options -> {attributes} -> {value} = $options -> {value};
	
	$options -> {attributes} -> {id} = 'input_' . $options -> {name};

	$options -> {attributes} -> {class} ||= $options -> {mandatory} ? 'form-mandatory-inputs' : 'form-active-inputs';	

	$options -> {attributes} -> {tabindex} = ++ $_REQUEST {__tabindex};

	return $_SKIN -> draw_form_field_datetime (@_);

}

################################################################################

sub draw_form_field_file {

	my ($options, $data) = @_;
	
	$_REQUEST {__form_options} {enctype} = 'multipart/form-data';

	$options -> {size} ||= 60;
	$options -> {attributes} -> {class} ||= $options -> {mandatory} ? 'form-mandatory-inputs' : 'form-active-inputs';	

	return $_SKIN -> draw_form_field_file (@_);

}

################################################################################

sub draw_form_field_files {

	my ($options, $data) = @_;
	
	$_REQUEST {__form_options} {enctype} = 'multipart/form-data';

	$options -> {size} ||= 60;
	$options -> {attributes} -> {class} ||= $options -> {mandatory} ? 'form-mandatory-inputs' : 'form-active-inputs';	

	return $_SKIN -> draw_form_field_files (@_);

}

################################################################################

sub draw_form_field_hidden {
	my ($options, $data) = @_;	
	$options -> {value}   ||= $data -> {$options -> {name}};
	$options -> {value} =~ s/\"/\&quot\;/gsm; #";
	return $_SKIN -> draw_form_field_hidden (@_);	
}

################################################################################

sub draw_form_field_hgroup {

	my ($options, $data) = @_;
			
	foreach my $item (@{$options -> {items}}) {
	
		next if $item -> {off} && $data -> {id};
		
		$item = _adjust_field ($item, $data);		
		
		$item -> {label} .= ': ' if $item -> {label} && !$item -> {no_colon};
		
		if ($_REQUEST {__read_only} || $options -> {read_only} || $item -> {read_only}) {

			if ($item -> {type} eq 'checkbox') {
				$item -> {value} = $data -> {$item -> {name}} || $item -> {checked} ? $i18n -> {yes} : $i18n -> {no};
			}
			if ($item -> {type} eq 'hgroup') {
				$item -> {value} = draw_form_field_hgroup ($item, $data);
			}
			
			$item -> {type}   = 'static';
			
		}
		
		$item -> {mandatory} = exists $item -> {mandatory} ? $item -> {mandatory} : $options -> {mandatory}; 
		
		$item -> {type} ||= 'string';
		
		$item -> {html}   = &{'draw_form_field_' . $item -> {type}} ($item, $data);
		
	}
	
	return $_SKIN -> draw_form_field_hgroup (@_);
		
}

################################################################################

sub draw_form_field_multi_select {

	my ($options, $data) = @_;

	check_href ($options);

	my $url = dialog_open ({
		href	=> $options -> {href} . '&multi_select=1',
		title	=> $options -> {label},
	}, {
		dialogHeight	=> 'screen.availHeight - (screen.availHeight <= 600 ? 50 : 100)',
		dialogWidth	=> 'screen.availWidth - (screen.availWidth <= 800 ? 50 : 100)',
	}) . "if (result.result == 'ok') {document.getElementById ('ms_$options').innerHTML=result.label; document.form._$options->{name}.value=result.ids;";
	
	my $js_detail;
	
	if (defined $options -> {detail}) {

		$options -> {value_src} = "this.form.elements['_$options->{name}'].value";
		$js_detail = js_detail ($options);

		$url .= $js_detail;

	}

	$url .= "} void (0);";

	$url =~ s/^javascript://i;
	
	my $url_dialog_id = $_REQUEST {__dialog_cnt};

	my $detail_from;
	if (exists $options -> {detail_from}) {
		if (ref $options -> {detail_from} ne ARRAY) {
			$options -> {detail_from} = [$options -> {detail_from}];
		}
		foreach my $field (@{$options -> {detail_from}}) {
			$detail_from .= <<EOJS;
                        re = /&$field=[\\d]*/;
                        dialog_open_$url_dialog_id.href = dialog_open_$url_dialog_id.href.replace(re, '');
			dialog_open_$url_dialog_id.href += '&$field=' + document.getElementsByName ('_$field') [0].value;
EOJS
		}
	}
	

	return draw_form_field_hgroup (
		{
			label	=> $options -> {label},
			type	=> 'hgroup',
			items	=> [
#				{
#					type	=> 'static',
#					value	=> qq[<table id="_$$options{name}">],
#				},
				{
					type	=> 'static',
					value	=> qq[<span id="ms_$options">] . join ('<br>', map {$_ -> {label}} @{$options -> {values}}) . '</span>',
				},
				{
					type	=> 'hidden',
					name	=> $options->{name},
					value	=> join (',', map {$_ -> {id}} @{$options -> {values}}),
					off	=> $_REQUEST {__read_only},
				},
				{
					type	=> 'button',
					value	=> 'Изменить',
					onclick	=> <<EOJS,
						re = /&_?salt=[\\d\\.]*/g;
						dialog_open_$url_dialog_id.href = dialog_open_$url_dialog_id.href.replace(re, '');
						dialog_open_$url_dialog_id.href += '&salt=' + Math.random ();
						
						re = /&ids=[^&]*/i; 
						dialog_open_$url_dialog_id.href = dialog_open_$url_dialog_id.href.replace(re, '');
						dialog_open_$url_dialog_id.href += '&ids=' + document.getElementsByName ('_$options->{name}') [0].value; 

						$detail_from

						$url
EOJS

					off	=> $_REQUEST {__read_only},
				},
				{
					type	=> 'button',
					value	=> 'Очистить',
					onclick => "document.getElementById ('ms_$options').innerHTML=''; document.form._$options->{name}.value='';" . $js_detail,
					off	=> $_REQUEST {__read_only},
				},
#				{
#					type	=> 'static',
#					value	=> qq[</table>],
#				},
			],
		},
		$data
	);
		
}

################################################################################

sub draw_form_field_text {

	my ($options, $data) = @_;
	
	$options -> {value}   ||= $data -> {$options -> {name}};
	$options -> {value} =~ s/\"/\&quot\;/gsm; #";
	$options -> {cols} ||= 60;
	$options -> {rows} ||= 25;

	$options -> {attributes} -> {class} ||= $options -> {mandatory} ? 'form-mandatory-inputs' : 'form-active-inputs';	
	
	$options -> {attributes} -> {readonly} = 1 if $_REQUEST {__read_only} or $options -> {read_only};	
	$options -> {attributes} -> {tabindex} = ++ $_REQUEST {__tabindex};
	
	return $_SKIN -> draw_form_field_text (@_);

}

################################################################################

sub draw_form_field_password {

	my ($options, $data) = @_;

	$options -> {size} ||= $conf -> {size} || 120;	
	$options -> {attributes} -> {tabindex} = ++ $_REQUEST {__tabindex};
	$options -> {attributes} -> {class} ||= $options -> {mandatory} ? 'form-mandatory-inputs' : 'form-active-inputs';	
	
	return $_SKIN -> draw_form_field_password (@_);
	
}

################################################################################

sub draw_form_field_static {

	my ($options, $data) = @_;

	$options -> {crlf} ||= '; ';
		
	if ($options -> {add_hidden}) {
		$options -> {hidden_name}  ||= '_' . $options -> {name};
		$options -> {hidden_value} ||= $data    -> {$options -> {name}};
		$options -> {hidden_value} ||= $options -> {value};
		$options -> {hidden_value} =~ s/\"/\&quot\;/gsm; #";
	}	

	if ($options -> {href} && !$_REQUEST {__edit} && !$_REQUEST {xls}) {
		check_href ($options);
	}
	else {
		delete $options -> {href};
	}
	
	my $value = defined $options -> {value} ? $options -> {value} : $data -> {$options -> {name}};

	my $static_value = '';
	
	if ($options -> {field} =~ /^(\w+)\.(\w+)$/) {
			
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

				$static_value .= $item -> {type} eq 'hgroup' ? draw_form_field_hgroup ($item, $data)
					: $item -> {type} eq 'multi_select' ? draw_form_field_multi_select ($item, $data)
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
			
			if ($item -> {type} eq 'hgroup') {
				$item -> {read_only} = 1;
				$static_value .= ' ';
				$static_value .= draw_form_field_hgroup ($item, $data);
			}
			elsif ($item -> {type} eq 'multi_select') {
				$item -> {read_only} = 1;
				$static_value .= ' ';
				$static_value .= draw_form_field_multi_select ($item, $data);
			}
			elsif ($item -> {type} || $item -> {name}) {
				$static_value .= ' ';
				$static_value .= draw_form_field_static ($item, $data);
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

	return $_SKIN -> draw_form_field_static (@_);
			
}

################################################################################

sub draw_form_field_checkbox {

	my ($options, $data) = @_;
	
	$_REQUEST {__form_checkboxes} .= ",_$options->{name}";
	
	$options -> {attributes} -> {checked}  = 1 if $options -> {checked} || $data -> {$options -> {name}};
	$options -> {attributes} -> {tabindex} = ++ $_REQUEST {__tabindex};
	
	return $_SKIN -> draw_form_field_checkbox (@_);
	
}

################################################################################

sub js_detail {

	my ($options) = @_;

	ref $options -> {detail} eq ARRAY or $options -> {detail} = [$options -> {detail}];

	my ($codetail_js, $tab_js);

	my (@all_details, @all_codetails); 

	foreach my $detail_ (@{$options -> {detail}}) {

		my ($detail, $codetails);
		if (ref $detail_ eq HASH) {
			($detail, $codetails) = (%{$detail_}); 
		} else {
			$detail = $detail_;
		}
		
		if (defined $codetails) {

			ref $codetails eq ARRAY or $codetails = [$codetails];

			foreach my $codetail (@{$codetails}) {

				next
					if ((grep {$_ eq $codetail} @all_codetails) > 0);

				push (@all_codetails, $codetail);

			}

		}


		push @all_details, $detail;
		
		$tab_js .= <<EOJS;
			element = this.form.elements['_${detail}'];
			if (element) {
				tabs.push (element.tabIndex);
			}
EOJS
		
	}

	my $h = {href => {}};

	check_href ($h);

	my $script_name = $ENV {SCRIPT_NAME} eq '/' ? '' : $ENV {SCRIPT_NAME};
	my $href = $$h{href};
	$href =~ s{^/}{};
	
	$options -> {value_src} ||= 'this.value';
	my $onchange = $_REQUEST {__windows_ce} ? "loadSlaveDiv ('$$h{href}&__only_form=this.form.name&_$$options{name}=this.value&__only_field=" . (join ',', @all_details) : <<EOJS;
		activate_link (

			'$script_name/$href&__only_field=${\(join (',', @all_details))}&__only_form=' + 
			this.form.name + 
			'&_$$options{name}=' + 
			$options->{value_src} + 
			codetails_url +
			tab

			, 'invisible_$$options{name}'
			
			, 1

		);
EOJS


	push @{$_REQUEST{__invisibles}}, 'invisible_' . $options -> {name};
	
	my $codetails = $_JSON -> encode (\@all_codetails);
	$codetails =~ s/\"/\'/g;
	
	return <<EOJS;
	
		var element;
		var tabs = [];

		$tab_js
		
		var tab = tabs.length > 0 ? '&__only_tabindex=' + tabs.join (',') : '';
		var codetails = $codetails;
		var codetails_url = '';

		for (i=0; i < codetails.length; i ++) {
		
			if (document.getElementById('_' + codetails[i] + '_select')) {
				codetails_url += '&' + '_' + codetails[i] + '=' + document.getElementById('_' + codetails[i] + '_select').value;

				continue; 
			} 
			
			if (document.getElementsByName('_' + codetails[i]).length > 1) {

				for (j=0; j < document.getElementsByName('_' + codetails[i]).length; j ++) {
				
					r = document.getElementsByName('_' + codetails[i]) [j];

					if (r.checked) {
						codetails_url += '&' + '_' + codetails[i] + '=' + r.value;
						break;
					}
				}
				continue;
			}

			if (document.getElementById('_' + codetails[i])) {
				codetails_url += '&' + '_' + codetails[i] + '=' + document.getElementById('_' + codetails[i]).value;
				continue; 
			} 
		}
		
		$onchange

EOJS

}

################################################################################

sub draw_form_field_radio {

	my ($options, $data) = @_;

	$options -> {values} = [ grep { !$_ -> {off} } @{$options -> {values}} ] if $data -> {id};

	foreach my $value (@{$options -> {values}}) {

		$value -> {attributes} -> {tabindex} = ++ $_REQUEST {__tabindex};
		$value -> {attributes} -> {checked} = 1 if ($data -> {$options -> {name}} == $value -> {id} && $data -> {$options -> {name}} =~ /^\d+$/) or $data -> {$options -> {name}} eq $value -> {id};

		if (defined $options -> {detail}) {

			$value -> {onclick} .= js_detail ($options);

		}

		$value -> {type} ||= 'select' if $value -> {values};		
		$value -> {type} or next;
			
		my $renderrer = "draw_form_field_$$value{type}";
		
		local $value -> {attributes};
		$value -> {html} = &$renderrer ($value, $data);
		delete $value -> {attributes} -> {class};
						
	}


	return $_SKIN -> draw_form_field_radio (@_);
	
}

################################################################################

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

		$value -> {selected} = (($value -> {id} eq $data -> {$options -> {name}}) or ($value -> {id} eq $options -> {value})) ? 'selected' : '';
		$value -> {label} = trunc_string ($value -> {label}, $options -> {max_len});
		$value -> {id} =~ s{\"}{\&quot;}g; #";

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

################################################################################

sub draw_form_field_string_voc {

	my ($options, $data) = @_;
	
	$options -> {max_len} ||= $conf -> {max_len};
	$options -> {attributes} -> {class} ||= $options -> {mandatory} ? 'form-mandatory-inputs' : 'form-active-inputs';	
	$options -> {attributes} -> {tabindex} = ++ $_REQUEST {__tabindex};
	$options -> {size}    ||= 50;
	$options -> {attributes} -> {size}      = $options -> {size};

	foreach my $value (@{$options -> {values}}) {

		if (($value -> {id} eq $data -> {$options -> {name}}) or ($value -> {id} eq $options -> {value})) {
			$options -> {attributes} -> {value} = trunc_string ($value -> {label}, $options -> {max_len});
			$value -> {id} =~ s{\"}{\&quot;}g; #";
			$options -> {id} = $value -> {id};
			last; 
		}

	}
	$options -> {onChange} = '';

	if (defined $options -> {other}) {

		ref $options -> {other} or $options -> {other} = {href => $options -> {other}};

		check_href ($options -> {other});

		$options -> {other} -> {param} ||= 'q';
		$options -> {other} -> {href} =~ s{([\&\?])select\=\w+}{$1};
		$options -> {other} -> {href} =~ s{([\&\?])__tree\=\w+}{$1};

	}


	if (defined $options -> {detail}) {

		$options -> {onChange} .= js_detail ($options);

	}

	$options -> {attributes} -> {name}  = '_' . $options -> {name} . '_label';

	return $_SKIN -> draw_form_field_string_voc (@_);
	
}

################################################################################

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

################################################################################

sub draw_form_field_checkboxes {

	my ($options, $data, $form_options) = @_;

	$options -> {cols} ||= 1;

	if (!ref $data -> {$options -> {name}}) {
	
		$data -> {$options -> {name}} = [grep {$_} split /\,/, $data -> {$options -> {name}}];
		
	}
	
	my $key = '__get_ids_' . $options -> {name};
	
	$_REQUEST {$key} = 1;
	
	push @{$form_options -> {keep_params}}, $key;
	
	foreach my $value (@{$options -> {values}}) {

		$value -> {type} ||= $value -> {items} ? 'checkboxes' : undef;
		
		if ($value -> {type} eq 'checkboxes') {
			$value -> {values} = $value -> {items};
			$value -> {inline} = 1;
			$value -> {name} = $options -> {name} if ($options -> {name});
		};
		
		$value -> {type} or next;

		$value -> {attributes} -> {tabindex} = ++ $_REQUEST {__tabindex};
		$value -> {attributes} -> {checked} = 1 if $data -> {$options -> {name}} == $value -> {id};

		my $renderrer = "draw_form_field_$$value{type}";
		
		$value -> {html} = &$renderrer ($value, $data);
		$value -> {html} =~ s/\<input/&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\<input/g if ($value -> {type} eq 'checkboxes');
		
		delete $value -> {attributes} -> {class};
						
	}
		
	return $_SKIN -> draw_form_field_checkboxes (@_);
	
}

################################################################################

sub draw_form_field_image {

	return $_SKIN -> draw_form_field_image (@_);

}

################################################################################

sub draw_form_field_color {

	my ($options, $data) = @_;

	$options -> {value} ||= $data -> {$options -> {name}};

	return $_SKIN -> draw_form_field_color (@_);

}

################################################################################

sub draw_form_field_iframe {
	
	my ($options, $data) = @_;

	return $_SKIN -> draw_form_field_iframe (@_);

}

################################################################################

sub draw_form_field_dir {

	require File::Find;
	
	my ($options, $data) = @_;

	$options -> {width}  ||= 800;
	$options -> {height} ||= 100;
	
	$options -> {name}   ||= 'dir';
	$options -> {$options -> {name}} ||= $_REQUEST {type} . '/' . $data -> {id};
	
	my $root = $r -> document_root . '/i/upload/dav_';
	
	my $ro_dir = $root . 'ro/' . $options -> {$options -> {name}};
	my $rw_dir = $root . 'rw/' . $options -> {$options -> {name}};

	($options -> {url}) = split /\//, lc $r -> protocol;
	$options -> {url} .= '://';
	$options -> {url} .= $ENV {HTTP_HOST};
	$options -> {url} .= $_REQUEST {__uri};
	$options -> {url} .= 'i/upload/dav_';

	if ($_REQUEST {__read_only}) {
		
		my $ro_dir1 = $ro_dir;
		$ro_dir1 =~ s{/\w+/?$}{};

		unless (-d $ro_dir1) {
			mkdir $ro_dir1;
			chmod 0777, $ro_dir1;
		}
	
		if (-d $rw_dir) {
		
			finddepth (sub {-d $File::Find::name ? rmdir $File::Find::name : unlink $File::Find::name}, $ro_dir);			
			move ($rw_dir, $ro_dir);
		
		}
		elsif (!-d $ro_dir) {
		
			mkdir $ro_dir;
			chmod 0777, $ro_dir;
		
		}		
	
		$options -> {url} .= 'ro/';

	}
	else {
	
		my $rw_dir1 = $rw_dir;
		$rw_dir1 =~ s{/\w+/?$}{};
		unless (-d $rw_dir1) {
			mkdir $rw_dir1;
			chmod 0777, $rw_dir1;
		}

		if (-d $ro_dir) {
		
			finddepth (sub {-d $File::Find::name ? rmdir $File::Find::name : unlink $File::Find::name}, $rw_dir);
			move ($ro_dir, $rw_dir);
		
		}
		elsif (!-d $rw_dir) {
		
			mkdir $rw_dir;
			chmod 0777, $rw_dir;

		}
	
		$options -> {url} .= 'rw/';

	}

	$options -> {url} .= $options -> {$options -> {name}};

	return $_SKIN -> draw_form_field_dir (@_);

}

################################################################################

sub draw_form_field_htmleditor {
	
	my ($options, $data) = @_;
		
	push @{$_REQUEST{__include_js}}, 'rte/fckeditor';
	
	$options -> {value} ||= $data -> {$options -> {name}};
		
	$options -> {value} =~ s{\\}{\\\\}gsm;
	$options -> {value} =~ s{\"}{\\\"}gsm; #"
	$options -> {value} =~ s{\'}{\\\'}gsm;
	$options -> {value} =~ s{[\n\r]+}{\\n}gsm;

	return $_SKIN -> draw_form_field_htmleditor (@_);

}

################################################################################

sub draw_toolbar {

	my ($options, @buttons) = @_;

	return '' if $options -> {off};	
	
	$_REQUEST {__toolbar_inputs} = '';

	$_REQUEST {__toolbars_number} ||= 0;

	$options -> {form_name} = $_REQUEST {__toolbars_number} ? 'toolbar_form_' . $_REQUEST {__toolbars_number} : 'toolbar_form';

	$_REQUEST {__toolbars_number} ++;

	if ($_REQUEST {select}) {

		hotkeys (
			{
				code => 27,
				data => 'cancel',
			},
		);
		
	}
	
	if ($_REQUEST {__tree}) {
		push (@{$options -> {keep_params}}, '__tree');
	}

	foreach my $button (@buttons) {

		if (ref $button eq HASH) {

			next if $button -> {off};
			
			if ($button -> {hidden} && !$_REQUEST {__edit_query}) {
			
				push @{$_ORDER {$button -> {order}} -> {filters}}, $button if $conf -> {core_store_table_order} && $button -> {order};

				next;
				
			}
			
			$button -> {type} ||= 'button';

			$_REQUEST {__toolbar_inputs} .= "$button->{name}," if $button -> {type} =~ /^input_/;

			$button -> {html} = &{'draw_toolbar_' . $button -> {type}} ($button, $options -> {_list}) unless $_REQUEST {__edit_query};

		}
		else {
			$button = {html => $button, type => 'input_raw'};
		}

		push @{$options -> {buttons}}, $button;
		
		push @{$_ORDER {$button -> {order}} -> {filters}}, $button if $conf -> {core_store_table_order} && $button -> {order};

	};

	return '' if 0 == @{$options -> {buttons}};
	
	push @{$options -> {keep_params}}, qw (
		sid
		__last_query_string
		__last_scrollable_table_row
		__last_last_query_string value
		__toolbar_inputs
	);

	return $_SKIN -> draw_toolbar ($options);

}

################################################################################

sub draw_toolbar_break {
	my ($options) = @_;
	return $_SKIN -> draw_toolbar_break ($options);
}

################################################################################

sub draw_toolbar_button {

	my ($options) = @_;
			
	$conf -> {kb_options_buttons} ||= {ctrl => 1, alt => 1};	
	
	register_hotkey ($options, 'href', $options, $conf -> {kb_options_buttons});
	
	check_href ($options);

	if (
		$options -> {href} !~ /^java/ &&
		(	
			$options -> {keep_esc} ||
			(!exists $options -> {keep_esc} && $options -> {icon} eq 'create' && $options -> {href} !~ /action=create/)
		)
	) {
		
		$options -> {href} =~ s{\&?__last_query_string=\d*}{}gsm;
		$options -> {href} .= "&__last_query_string=$_REQUEST{__last_last_query_string}";

		$options -> {href} =~ s{\&?__last_scrollable_table_row=\d*}{}gsm;
		$options -> {href} .= "&__last_scrollable_table_row=$_REQUEST{__last_scrollable_table_row}" unless ($_REQUEST {__windows_ce});
	
	}		

	my $cursor_state = $options -> {no_wait_cursor} ? q[; window.document.body.onbeforeunload = function() {document.body.style.cursor = 'default';};] : '';

	if ($options -> {confirm}) {
		$options -> {target} ||= '_self';
		my $salt = rand;
		my $msg = js_escape ($options -> {confirm});
		$options -> {href} =~ s{\%}{\%25}gsm; 		# wrong, but MSIE uri_unescapes the 1st arg of window.open :-(
		$options -> {href} = qq [javascript:if (confirm ($msg)) {nope($cursor_state '$$options{href}', '$$options{target}')} else {document.body.style.cursor = 'default'; nop ();}];
	} elsif ($options -> {no_wait_cursor}) {
	    $options -> {onclick} = qq[onclick="$cursor_state  void(0);"];
	} 
	
	if ($options -> {href} =~ /^java/) {
		$options -> {target} = '_self';
	}

	if ($options -> {hotkey}) {
		$options -> {id} ||= $options;
		$options -> {hotkey} -> {data}    = $options -> {id};
		$options -> {hotkey} -> {off}     = $options -> {off};
		hotkey ($options -> {hotkey});
	}	
		
	$options -> {id} ||= '' . $options;
	
	return $_SKIN -> draw_toolbar_button ($options);

}

################################################################################

sub draw_toolbar_input_tree {

	my ($options) = @_;

	my $label = '';

	foreach my $value (@{$options -> {values}}) {
	
		my $is_checked = $_REQUEST {"$options->{name}_$value->{id}"};

		$value -> {__node} = draw_node ({
			label	=> $value -> {label},
			id	=> $value -> {id},
			parent	=> $value -> {parent},
			is_checkbox	=> $value -> {is_checkbox} + $is_checked,
			icon    	=> $value -> {icon},
			iconOpen    	=> $value -> {iconOpen},
			href  		=> $value -> {href},
		});
		
		if ($is_checked) {
		
			$label .= ', ' if $label;
			$label .= $value -> {label};

		}

	}
	
	if ($label) {
	
		$options -> {max_len} ||= ($conf -> {max_len} || 20);
		
		$options -> {label} = trunc_string ($label, $options -> {max_len});
	
	}

	return $_SKIN -> draw_toolbar_input_tree ($options);

}

################################################################################

sub draw_toolbar_input_select {

	my ($options) = @_;
		
	$options -> {max_len} ||= $conf -> {max_len};

	if (defined $options -> {other}) {

		ref $options -> {other} or $options -> {other} = {href => $options -> {other}};
		
		$options -> {other} -> {label} ||= $i18n -> {voc};

		check_href ($options -> {other});
		$options -> {other} -> {href} =~ s{([\&\?])select\=\w+}{$1};
		if ($options -> {other} -> {top}) {
			unshift @{$options -> {values}}, {id => -1, label => $options -> {other} -> {label}};
		} else {
			push @{$options -> {values}}, {id => -1, label => $options -> {other} -> {label}};
		}

	}		
	
	exists $options -> {empty} and unshift @{$options -> {values}}, {id => '', label => $options -> {empty}};

	$options -> {value}   ||= $_REQUEST {$options -> {name}};

	foreach my $value (@{$options -> {values}}) {		
		$value -> {label}    = trunc_string ($value -> {label}, $options -> {max_len});						
		$value -> {selected} = $value -> {id} eq $options -> {value} ? 'selected' : '';
	}

	$options -> {onChange} ||= 'submit();';
	$options -> {onChange} = '' if defined $options -> {other};

	return $_SKIN -> draw_toolbar_input_select ($options);
	
}

################################################################################

sub draw_toolbar_input_checkbox {

	my ($options) = @_;
	
	$options -> {checked} = (exists $options -> {checked} ? $options -> {checked} : $_REQUEST {$options -> {name}}) ? 'checked' : '';

	$options -> {onClick} ||= 'submit();';
	

	return $_SKIN -> draw_toolbar_input_checkbox ($options);
	
}

################################################################################

sub draw_toolbar_input_submit {

	return $_SKIN -> draw_toolbar_input_submit (@_);

}

################################################################################

sub draw_toolbar_input_text {

	my ($options) = @_;
	
	$options -> {id} ||= ('' . $options);

	$conf -> {kb_options_focus} ||= $conf -> {kb_options_buttons};
	$conf -> {kb_options_focus} ||= {ctrl => 1, alt => 1};

	register_hotkey ($options, 'focus_id', $options -> {id}, $conf -> {kb_options_focus});
	
	$options -> {value} ||= $_REQUEST {$options -> {name}};	
	$options -> {size} ||= 15;		
	
	return $_SKIN -> draw_toolbar_input_text (@_);

}

################################################################################

sub draw_toolbar_input_datetime {

	my ($options) = @_;
			
	if ($r -> headers_in -> {'User-Agent'} =~ /MSIE 5\.0/) {
		$options -> {size} ||= $options -> {no_time} ? 11 : 16;
		return draw_toolbar_input_text ($options, $data);
	}
		
	unless ($options -> {format}) {
	
		if ($options -> {no_time}) {
			$options -> {format}  ||= $i18n -> {_format_d} || '%d.%m.%Y';
			$options -> {size}    ||= 11;
		}
		else {
			$options -> {format}  ||= $i18n -> {_format_dt} || '%d.%m.%Y %k:%M';
			$options -> {size}    ||= 16;
		}
	
	}
			
	$options -> {attributes} -> {size}      = $options -> {size};
	$options -> {attributes} -> {maxlength} = $options -> {size};

	$options -> {value}      ||= $_REQUEST {$$options{name}};
	$options -> {attributes} -> {value} = $options -> {value};
	
	$options -> {attributes} -> {id} = 'input' . $options -> {name};

	$options -> {attributes} -> {tabindex} = ++ $_REQUEST {__tabindex};
	
	return $_SKIN -> draw_toolbar_input_datetime (@_);
	
}

################################################################################

sub draw_toolbar_input_date {

	my ($_options) = @_;

	$_options -> {no_time} = 1;

	return draw_toolbar_input_datetime ($_options);
	
}

################################################################################

sub draw_toolbar_pager {

	my ($options, $list) = @_;
		
	$options -> {portion} ||= $_REQUEST {__page_content} -> {portion} || $conf -> {portion};
	$options -> {total}   ||= $_REQUEST {__page_content} -> {cnt};
	$options -> {cnt}     ||= 0 + @$list;

	$options -> {start} = $_REQUEST {start} + 0;

	$conf -> {kb_options_pager} ||= $conf -> {kb_options_buttons};
	$conf -> {kb_options_pager} ||= {ctrl => 1};

	my %keep_params	= map {$_ => $_REQUEST {$_}} @{$options -> {keep_params}};

	$keep_params {__this_query_string}      = $_REQUEST {__last_query_string};
	$keep_params {__last_query_string}      = $_REQUEST {id} && !$options -> {keep_esc} ? $_REQUEST {__last_last_query_string} : $_REQUEST {__last_query_string};
	$keep_params {__last_last_query_string} = $_REQUEST {__last_last_query_string};
	
	if ($options -> {start} > $options -> {portion}) {
		$options -> {rewind_url} = create_url (start => 0, %keep_params);
	}
	
	if ($options -> {start} > 0) {

		hotkey ({
			code => 33, 
			data  => '_pager_prev', 
			%{$conf -> {kb_options_pager}},
		});
		
		$options -> {back_url} = create_url (start => ($options -> {start} - $options -> {portion} < 0 ? 0 : $options -> {start} - $options -> {portion}), %keep_params);

	}
	
	if ($options -> {start} + $$options{cnt} < $$options{total} || $$options{total} == -1) {
	
		hotkey ({
			code => 34, 
			data  => '_pager_next', 
			%{$conf -> {kb_options_pager}},
		});
		
		$options -> {next_url} = create_url (start => $options -> {start} + $options -> {portion}, %keep_params);

	}
	
	if ($options -> {start} + $$options{cnt} * 2 < $$options{total}) {
	
		$options -> {last_url} = create_url (start => $options -> {total} - $options -> {portion}, %keep_params);

	}

	$options -> {infty_url}   = create_url (__last_query_string => $last_query_string, __infty => 1 - $_REQUEST {__infty}, __no_infty => 1 - $_REQUEST {__no_infty}, @keep_params);
	
	$options -> {infty_label} = $options -> {total} > 0 ? $options -> {total} : $i18n -> {infty};
	
	return $_SKIN -> draw_toolbar_pager (@_);

}

################################################################################

sub draw_centered_toolbar_button {

	my ($options) = @_;
	
	if ($options -> {preset}) {
		my $preset = $conf -> {button_presets} -> {$options -> {preset}};
		$options -> {hotkey}     ||= Storable::dclone ($preset -> {hotkey}) if $preset -> {hotkey};
		$options -> {icon}       ||= $preset -> {icon};
		$options -> {label}      ||= $i18n -> {$preset -> {label}};
		$options -> {label}      ||= $preset -> {label};
		$options -> {confirm}    = exists $options -> {confirm} ? $options -> {confirm} :
			$i18n -> {$preset -> {confirm}} ? $i18n -> {$preset -> {confirm}} :
			$preset -> {confirm};
		$options -> {preconfirm} ||= $preset -> {preconfirm};
	}	

	if ($options -> {hotkey}) {
		$options -> {id} ||= $options . '';
		$options -> {hotkey} -> {data}    = $options -> {id};
		$options -> {hotkey} -> {off}     = $options -> {off};
		hotkey ($options -> {hotkey});
	}

	$options -> {href} = 'javaScript:' . $options -> {onclick} if $options -> {onclick};

	check_href ($options);
	
	if (
		!(	
			$options -> {keep_esc} ||
			(!exists $options -> {keep_esc} && $options -> {icon} eq 'cancel')
		)
	) {
		$options -> {href} =~ s{__last_query_string\=\d+}{__last_query_string\=$_REQUEST{__last_last_query_string}}gsm;
	}

	$options -> {target} ||= '_self';

	my $cursor_state = $options -> {no_wait_cursor} ? q[; window.document.body.onbeforeunload = function() {document.body.style.cursor = 'default';};] : '';

	if ($options -> {confirm}) {
		my $salt = rand;
		my $msg = js_escape ($options -> {confirm});
		$options -> {preconfirm} ||= 1;
		$options -> {href} =~ s{\%}{\%25}gsm; 		# wrong, but MSIE uri_unescapes the 1st arg of window.open :-(
		my $href = js_escape ($options -> {href});
		$options -> {href} = qq [javascript:if (!($$options{preconfirm}) || ($$options{preconfirm} && confirm ($msg))) {$cursor_state nope ($href, '$options->{target}')} else {document.body.style.cursor = 'default'; nop ();} ];
        } elsif ($options -> {no_wait_cursor}) {
		$options -> {onclick} = qq{onclick="$cursor_state; void(0);"};
	} 	

	if ($options -> {href} =~ /^java/) {
		$options -> {target} = '_self';
	}
	
	return $_SKIN -> draw_centered_toolbar_button (@_);

}

################################################################################

sub draw_centered_toolbar {

	$_REQUEST {lpt} and return '';

	my ($options, $list) = @_;
	
	$options -> {cnt} = 0;
		
	foreach my $i (@$list) {
		next if $i -> {off};
		$i -> {target} ||= $options -> {buttons_target};
		$i -> {html} = draw_centered_toolbar_button ($i);
		$options -> {cnt} ++;
	}

	$options -> {cnt} or return '';

	return $_SKIN -> draw_centered_toolbar (@_);

}

################################################################################

sub draw_esc_toolbar {

	my ($options) = @_;
		
	$options -> {href} = $options -> {esc};
	$options -> {href} ||= "/?type=$_REQUEST{type}";
	check_href ($options);

	draw_centered_toolbar ($options, [
		@{$options -> {left_buttons}},
		@{$options -> {additional_buttons}},
		{
			preset => 'cancel',
			href => $options -> {href}, 
			off  => $options -> {no_esc}, 
		},
		@{$options -> {right_buttons}},
	])
	
}

################################################################################

sub draw_ok_esc_toolbar {

	my ($options, $data) = @_;		
	
	$options -> {href} = $options -> {esc};
	$options -> {href} ||= "/?type=$_REQUEST{type}";
	check_href ($options);

	my $name = $options -> {name};
	$name ||= 'form';
	$name .= '_' . $_REQUEST {select} if ($_REQUEST {__windows_ce} && $_REQUEST {select});
	
	$options -> {label_ok}     ||= $i18n -> {ok};
	$options -> {label_cancel} ||= $i18n -> {cancel};
	$options -> {label_choose} ||= $i18n -> {choose};
	$options -> {label_edit}   ||= $i18n -> {edit};

	draw_centered_toolbar ($options, [
		@{$options -> {left_buttons}},
		{
			preset => 'ok',
			label => $options -> {label_ok}, 
			href => $_REQUEST {__windows_ce} || $_SKIN =~ /Universal/ || $_SKIN =~ /Gecko/ ? "javaScript:document.$name.submit()" : "javaScript:document.$name.fireEvent('onsubmit'); document.$name.submit()", 
			off  => $_REQUEST {__read_only} || $options -> {no_ok},
			(exists $options -> {confirm_ok} ? (confirm => $options -> {confirm_ok}) : ()),
		},
		{
			preset => 'edit',
			href  => create_url (
				__last_query_string         => $_REQUEST {__last_last_query_string},
				__last_scrollable_table_row => $_REQUEST {__windows_ce} ? undef : $_REQUEST {__last_scrollable_table_row},
				__edit                      => 1,
			),
			off   => ((!$conf -> {core_auto_edit} && !$_REQUEST{__auto_edit}) || !$_REQUEST{__read_only} || $options -> {no_edit}),
		},
		{
			preset => 'choose',
			label => $options -> {label_choose},
			href  => js_set_select_option ('', $data),
			off   => (!$_REQUEST {__read_only} || !$_REQUEST {select}),
		},
		@{$options -> {additional_buttons}},
		{
			preset => 'cancel',
			label => $options -> {label_cancel}, 			
			href => $options -> {href}, 
			off  => $options -> {no_esc},
		},
		@{$options -> {right_buttons}},
	 ])
	
}

################################################################################

sub draw_close_toolbar {
	
	my ($options) = @_;		

	draw_centered_toolbar ({}, [
		@{$options -> {left_buttons}},
		@{$options -> {additional_buttons}},
		{
			preset => 'close',     
			href => 'javascript: top.window.close()',
		},
		@{$options -> {right_buttons}},
	 ])
	
}

################################################################################

sub draw_back_next_toolbar {

	my ($options) = @_;
	
	my $type = $options -> {type};
	$type ||= $_REQUEST {type};
	
	my $back = $options -> {back};
	$back ||= "/?type=$type";
	
	my $name = $options -> {name};
	$name ||= 'form';

	draw_centered_toolbar ($options, [
		@{$options -> {left_buttons}},
		{
			preset => 'back', 
			href => $back, 
		},
		@{$options -> {additional_buttons}},
		{
			preset => 'next', 
			href => '#', 
			onclick => "document.$name.submit()",
		},
		@{$options -> {right_buttons}},
	])
	
}

################################################################################

sub draw_menu {

	my ($types, $cursor, $_options) = @_;
	
	@$types or return '';

	delete $_REQUEST {__tree} if $_REQUEST {__only_menu};	

	($_REQUEST {__no_navigation} or $_REQUEST {__tree}) and return '';	

	if ($preconf -> {core_show_dump}) {
	
		push @$types, $_SKIN -> draw_dump_button();

		push @$types, {
			label  => 'Info',
			href   => "/?type=_object_info&object_type=$_REQUEST{type}&id=$_REQUEST{id}",
			side   => 'right_items',
			no_off => 1,
		} if $_REQUEST {id} && $DB_MODEL -> {tables} -> {$_REQUEST {type}};

		push @$types, {
			label  => 'Proto',
			name   => '_proto',
			href   => create_url () . '&__proto=1&__edit=' . $_REQUEST {__edit},			
			side   => 'right_items',
			target => '_blank',
			no_off => 1,
		};
	
	}

	if ($_options -> {lpt}) {
	
		push @$types, {
			label  => 'MS Excel',
			name   => '_xls',
			href   => create_url (xls => 1, salt => rand * time) . '&__infty=1',
			side   => 'right_items',
			target => 'invisible',
		};
	
	}

	push @$types, {
		label => $i18n -> {Exit},
		name  => '_logout',
		href  => $conf -> {exit_url} || create_url (type => '_logout', id => ''),
		side  => 'right_items',
	};

	foreach my $type (@$types)	{
	
		next if $type -> {off};
	
		$conf -> {kb_options_menu} ||= {ctrl => 1, alt => 1};

		$type -> {name} ||= "$type->{items}";
		$type -> {name} ||= "$type";

		register_hotkey ($type, 'href', 'main_menu_' . $type -> {name}, $conf -> {kb_options_menu});
		
		if ($_REQUEST {__edit} && !($type -> {no_off} || $_SKIN -> {options} -> {core_unblock_navigation})) {
			$type -> {href} = "javaScript:alert('$$i18n{save_or_cancel}'); document.body.style.cursor = 'default'; nop ();";
		}
		elsif ($type -> {no_page}) {
			$type -> {href} = "javaScript:document.body.style.cursor = 'default'; nop ()";
		} 
		else {
			$type -> {href} ||= "/?type=$$type{name}";
			$type -> {href} .= "&role=$$type{role}" if $type -> {role};
			check_href ($type);
		}

		$type -> {onmouseout} = "menuItemOut ()";

		if (ref $type -> {items} eq ARRAY && (!$_REQUEST {__edit} || $_SKIN -> {options} -> {core_unblock_navigation})) {
			$type -> {vert_menu} = draw_vert_menu ($type -> {name}, $type -> {items}, 0, 1);
			$type -> {onhover} = "menuItemOver(this, '$$type{name}')";
		} else {
			$type -> {onhover} = "menuItemOver(this)";
		}
		
		$type -> {side  } ||= 'left_items';
		$type -> {target} ||= '_self';

		push @{$_options -> {$type -> {side}}}, $type;
	
	}
	
	return $_SKIN -> draw_menu ($_options);

}

################################################################################

sub draw_vert_menu {

	my ($name, $types, $level, $is_main) = @_;
	
	$level ||= 1;
	
	$types = [grep {!$_ -> {off}} @$types];
	
	foreach my $type (@$types) {
	
		if (ref $type -> {items} eq ARRAY && !$_REQUEST {__edit}) {

			my $sublevel = $level + 1;
			$type -> {name}     ||= '' . $type if $type -> {items};
			$type -> {vert_menu}  = draw_vert_menu ($type -> {name}, $type -> {items}, $sublevel, $is_main);

			$type -> {onhover} = "menuItemOver (this, '$$type{name}', '$name', $level)";
			$type -> {onmouseout} = "menuItemOut ()";
			
		}
		else {
			
			$type -> {onhover}    = "menuItemOver (this, null, '$name', $level)";
			$type -> {onmouseout} = "menuItemOut ()";

			$type -> {href}     ||= "/?type=$$type{name}";
			$type -> {href}      .= "&role=$$type{role}" if $type -> {role};

			check_href ($type);

			$type -> {target}   ||= "_self";

			$type -> {onclick} = 
				$type -> {href} =~ /^javascript\:/i ? $' : 
				$_SKIN -> {options} -> {core_unblock_navigation} ? "hideSubMenus(0); if (!check_edit_mode (this, '$$type{href}')) activate_link('$$type{href}', '$$type{target}')" :
				"hideSubMenus(0); activate_link('$$type{href}', '$$type{target}')";  #'
			$type -> {onclick} =~ s{[\n\r]}{}gsm;
		}
	
	}

	return $_SKIN -> draw_vert_menu ($name, $types, $level);

}

################################################################################

sub js_set_select_option {
	return $_SKIN -> js_set_select_option (@_);
}

################################################################################

sub draw_cells {

	my $options = (ref $_[0] eq HASH) ? shift () : {};
	
	if ($options -> {gantt}) {

		$i -> {__gantt} = $options -> {gantt};
		
		$_REQUEST {__gantt_from_year} ||= 3000;
		$_REQUEST {__gantt_to_year}   ||= 1;

		foreach my $key (keys %{$options -> {gantt}}) {
		
			foreach my $ft ('from', 'to') {
			
				$options -> {gantt} -> {$key} -> {$ft} =~ s{^(\d\d).(\d\d).(\d\d\d\d)$}{$3-$2-$1};

				$options -> {gantt} -> {$key} -> {$ft} =~ /^(\d\d\d\d)/;
				$_REQUEST {__gantt_from_year} <= $1 or $_REQUEST {__gantt_from_year} = $1;
				$_REQUEST {__gantt_to_year} >= $1 or $_REQUEST {__gantt_to_year} = $1;
			
			}
			
		}
		
	}
	
	my $result = '';
	
	delete $options -> {href} if $options -> {is_total};
		
	if ($options -> {href}) {
		check_href ($options) ;
		$options -> {a_class} ||= 'row-cell';
		$i -> {__href} ||= $options -> {href};
		$i -> {__target} ||= $options -> {target};
	}
	
	$options -> {__fixed_cols} = 0;
	

	if ($conf -> {core_store_table_order} && !$_REQUEST {__no_order}) {

		for (my $i = 0; $i < @_COLUMNS; $i ++) {
		
			my $h = $_COLUMNS [$i];
	
			ref $h eq HASH or next;
			
			last if $i >= @{$_ [0]};
			
			$_ [0] [$i] = {label => $_ [0] [$i]} unless ref $_ [0] [$i] eq HASH; 

			$_ [0] [$i] -> {ord} ||= $_COLUMNS [$i] -> {ord}; 

			$_ [0] [$i] -> {hidden} ||= $_COLUMNS [$i] -> {hidden}; 
	
		}

	}

	my @cells = order_cells (@{$_[0]});

	if ($_REQUEST {select} && !$options -> {select_label}) {
	
		my @cell;

		if ((@cell = grep {$_ -> {select_href}} @{$_[0]}) == 0) {

			foreach my $cell (@cells) {
				if (!$cell -> {no_select_href} && ($cell -> {label} ne '')) {
					$options -> {select_label} = $cell -> {label};
					last;
				} 
			}

		} else {
			$options -> {select_label} = $cell [0] -> {label};
		}
	}
	
	foreach my $cell (@cells) {
	
		if ($options -> {href}) {

			ref $cell or $cell = {label => $cell};

			$cell -> {a_class} ||= $options -> {a_class};
			$cell -> {target}  ||= $options -> {target} || '_self';

			unless (exists $cell -> {href}) {
				$cell -> {href} = $options -> {href};
				$cell -> {no_check_href} = 1;
			}

			if ($options -> {dialog} && !$cell -> {dialog}) {
				$cell -> {dialog} = $options -> {dialog};
			}
		}
		
		$options -> {__fixed_cols} ++ if ref $cell eq HASH && $cell -> {no_scroll};		
		
		$result .= 
			!ref ($cell) || ($cell -> {type} ne 'button' && !$cell -> {icon} && $cell -> {off}) || $cell -> {read_only} ? draw_text_cell ($cell, $options) :
			$cell  -> {type} eq 'radio'    ? draw_radio_cell  ($cell, $options) :
			$cell  -> {type} eq 'date'     ? draw_date_cell  ($cell, $options) :
			$cell  -> {type} eq 'datetime' ? draw_datetime_cell  ($cell, $options) :
			($cell -> {type} eq 'checkbox' || exists $cell -> {checked}) ? draw_checkbox_cell ($cell, $options) :
			($cell -> {type} eq 'button'   || $cell -> {icon}) ? draw_row_button ($cell, $options) :		
			$cell  -> {type} eq 'input'    ? draw_input_cell  ($cell, $options) :
			$cell  -> {type} eq 'textarea' ? draw_textarea_cell  ($cell, $options) :
			$cell  -> {type} eq 'select'   ? draw_select_cell ($cell, $options) :
			$cell  -> {type} eq 'embed'    ? draw_embed_cell ($cell, $options) :
			$cell  -> {type} eq 'string_voc' ? draw_string_voc_cell ($cell, $options) :			
			draw_text_cell ($cell, $options);
	
	}
	
	if ($options -> {gantt}) {

		$result .= draw_gantt_bars ($options -> {gantt});
		
	}

	return $result;
	
}

################################################################################

sub draw_gantt_bars {
	return $_SKIN -> draw_gantt_bars (@_);	
}

################################################################################

sub draw_text_cells {
	return draw_cells (@_);	
}

################################################################################

sub draw_row_buttons {
	return draw_cells (@_);	
}

################################################################################

sub _adjust_row_cell_style {

	my ($data, $options) = @_;

	$data -> {attributes} ||= {};
	$data -> {attributes} -> {colspan} = $data -> {colspan} if $data -> {colspan};
	$data -> {attributes} -> {rowspan} = $data -> {rowspan} if $data -> {rowspan};
	
	$data -> {attributes} -> {bgcolor} ||= $data    -> {bgcolor};
	$data -> {attributes} -> {bgcolor} ||= $options -> {bgcolor};

	$data -> {attributes} -> {style} ||= $data    -> {style};
	$data -> {attributes} -> {style} ||= $options -> {style};
	
	unless ($data -> {attributes} -> {style}) {
		delete $data -> {attributes} -> {style};
		$data -> {attributes} -> {class} ||= $data    -> {class};
		$data -> {attributes} -> {class} ||= $options -> {class};
		$data -> {attributes} -> {class} ||= 
			$options -> {is_total} ? 'row-cell-total' : 
			$data -> {attributes} -> {bgcolor} ? 'row-cell-transparent' : 
			'row-cell';
		$data -> {attributes} -> {class} .= '-no-scroll' if ($data -> {no_scroll} && $data -> {attributes} -> {class} =~ /row-cell/);
	}	

}

################################################################################

sub draw_text_cell {

	my ($data, $options) = @_;

	return '' if ref $data eq HASH && $data -> {hidden};

	ref $data eq HASH or $data = {label => $data};
			
	_adjust_row_cell_style ($data, $options);
				
	$data -> {off} = is_off ($data, $data -> {label});
	
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

		check_title ($data);	

		if ($_REQUEST {select}) {

			$data -> {href}   = js_set_select_option ('', {id => $i -> {id}, label => $options -> {select_label}});
		}
#		else {
#			$data -> {href}   ||= $options -> {href} unless $options -> {is_total};
#			$data -> {target} ||= $options -> {target};
#		}

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
		
#		if ($data -> {dialog}) {
#		
#			$data -> {href} = dialog_open ({
#					
#				title => $data -> {dialog} -> {title},
#					
#				href => $data -> {href},
#						
#			}, $data -> {dialog} -> {options}) . $data -> {dialog} -> {after} . ';void (0)',
#			
#		}

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

		exists $options -> {strike} or $data -> {strike} ||= $i -> {fake} < 0;
		
	}
	
	return $_SKIN -> draw_text_cell ($data, $options);

}

################################################################################

sub draw_radio_cell {

	my ($data, $options) = @_;
	
	return draw_text_cell (@_) if $data -> {read_only} || $data -> {off};
	
	$data -> {value} ||= 1;	
	$data -> {checked} = $data -> {checked} ? 'checked' : '';

	_adjust_row_cell_style ($data, $options);

	check_title ($data);
	
	return $_SKIN -> draw_radio_cell ($data, $options);

}

################################################################################

sub draw_date_cell {

	my ($data, $options) = @_;	

	return draw_text_cell ($data, $options) if ($_REQUEST {__read_only} && !$data -> {edit}) || $data -> {read_only} || $data -> {off};
	
	$options -> {no_time} = 1;	

	return draw_datetime_cell ($data, $options);

}

################################################################################

sub draw_datetime_cell {

	my ($data, $options) = @_;

	return draw_text_cell ($data, $options) if ($_REQUEST {__read_only} && !$data -> {edit}) || $data -> {read_only} || $data -> {off};
	
	if ($r -> headers_in -> {'User-Agent'} =~ /MSIE 5\.0/) {
		$options -> {size} ||= $options -> {no_time} ? 11 : 16;
		return draw_input_cell ($options, $data);
	}	

	unless ($options -> {format}) {
	
		if ($options -> {no_time}) {
			$options -> {format}  ||= $i18n -> {_format_d} || '%d.%m.%Y';
			$options -> {attributes} -> {size}    ||= 11;
		}
		else {
			$options -> {format}  ||= $i18n -> {_format_dt} || '%d.%m.%Y %k:%M';
			$options -> {attributes} -> {size}    ||= 16;
		}
	
	}
		
	$options -> {attributes} -> {id} = 'input' . $data -> {name};

	$options -> {attributes} -> {class} ||= $data -> {mandatory} ? 'form-mandatory-inputs' : 'form-active-inputs';

	$options -> {attributes} -> {value}   ||= $data -> {label};
	
	_adjust_row_cell_style ($data, $options);

	check_title ($data);

	return $_SKIN -> draw_datetime_cell (@_);

}

################################################################################

sub draw_checkbox_cell {

	my ($data, $options) = @_;
	
	return draw_text_cell (@_) if $data -> {read_only} || $data -> {off};
	
	if ($data -> {name} =~ /^_(\w+)_\d+$/) {

		$_REQUEST {__get_ids} -> {$1} ||= 1;
	
	}	

	$data -> {value} ||= 1;	
	$data -> {checked} = $data -> {checked} ? 'checked' : '';

	_adjust_row_cell_style ($data, $options);

	check_title ($data);

	return $_SKIN -> draw_checkbox_cell ($data, $options);
	
}

################################################################################

sub draw_select_cell {

	my ($data, $options) = @_;

	return draw_text_cell ($data, $options) if ($_REQUEST {__read_only} && !$data -> {edit}) || $data -> {read_only} || $data -> {off};
	
	$data -> {max_len} ||= $conf -> {max_len};

	_adjust_row_cell_style ($data, $options);

	foreach my $value (@{$data -> {values}}) {
		$value -> {selected} = ($value -> {id} eq $data -> {value}) ? 'selected' : '';
		$value -> {label} = trunc_string ($value -> {label}, $data -> {max_len});
		$value -> {id} =~ s{\"}{\&quot;}g; #"
	}

	return $_SKIN -> draw_select_cell ($data, $options);
	
}

################################################################################

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

################################################################################

sub draw_input_cell {

	my ($data, $options) = @_;
	
	return draw_text_cell ($data, $options) if ($_REQUEST {__read_only} && !$data -> {edit}) || $data -> {read_only} || $data -> {off};

	$data -> {size} ||= 30;
	
	_adjust_row_cell_style ($data, $options);
						
	defined $data -> {label} or $data -> {label} = '';
	
	if ($data -> {picture}) {
		$data -> {label} = format_picture ($data -> {label}, $data -> {picture});
		$data -> {label} =~ s/^\s+//g;
		$data -> {attributes} -> {align} ||= 'right';
	}
			
	check_title ($data);
		
	return $_SKIN -> draw_input_cell ($data, $options);

}

################################################################################

sub draw_textarea_cell {

	my ($data, $options) = @_;
	
	return draw_text_cell ($data, $options) if ($_REQUEST {__read_only} && !$data -> {edit}) || $data -> {read_only} || $data -> {off};

	$data -> {rows} ||= 3;
	$data -> {cols} ||= 80;

	$data -> {attributes} ||= {};
	$data -> {attributes} -> {class} ||= 'row-cell';
	
	_adjust_row_cell_style ($data, $options);
						
	$data -> {label} ||= '';
			
	check_title ($data);
		
	return $_SKIN -> draw_textarea_cell ($data, $options);

}

################################################################################

sub draw_embed_cell {

	my ($data, $options) = @_;
	
	$data -> {autostart} ||= 'false';
	$data -> {src_type} ||= 'audio/mpeg';
	$data -> {height} ||= 45;

	return $_SKIN -> draw_embed_cell ($data, $options);

}

################################################################################

sub draw_row_button {

	my ($options) = @_;
	
	return ''
		if $_REQUEST {xls};	
			
	check_href ($options);

	if ($options -> {confirm}) {
		my $salt = rand;
		my $msg = js_escape ($options -> {confirm});
		$options -> {href} =~ s{\%}{\%25}gsm; 		# wrong, but MSIE uri_unescapes the 1st arg of window.open :-(
		$options -> {href} = qq [javascript:if (confirm ($msg)) {nope('$$options{href}', '_self')} else {document.body.style.cursor = 'default'; nop ();}];
	}

	if (
		! (	
			$options -> {keep_esc} ||
			(!exists $options -> {keep_esc} && $options -> {icon} eq 'delete' && !$_REQUEST {id})
		)

	) {
		$options -> {href} =~ s{__last_query_string\=\d+}{__last_query_string\=$_REQUEST{__last_last_query_string}}gsm;
	}

	if ($options -> {href} =~ /^java/) {
		$options -> {target} = '_self';
	}

	check_title ($options);

	return $_SKIN -> draw_row_button ($options);

}

################################################################################

sub draw_table_header {

	my ($rows) = @_;
	
	ref $rows -> [0] eq ARRAY or $rows = [$rows];
	
	return $_SKIN -> draw_table_header ($rows, [map {draw_table_header_row ($_)} @$rows]);
	
}

################################################################################

sub order_cells {
		
	my %ord = ();
	
	my @result = ();
	
	foreach my $c (@_) {
		next if ref $c eq HASH && ($c -> {hidden} || $c -> {ord} < 0);
		my $cell = ref $c eq HASH ? {%$c} : {label => $c};
		$ord {$cell -> {ord}} ++ if $cell -> {ord};
		push @result, $cell;
	}
	
	return @result if 0 == %ord;
	
	my $n = 1;

	for (my $i = 0; $i < @result; $i++) {
	
		if ($result [$i] -> {ord}) {
		
			$result [$i] -> {ord} += $i / 1000;
		
		}
		else {
		
			$n++ while $ord {$n};
						
			$result [$i] -> {ord}  = $n;
		
		}
	
	}
	
	return sort {$a -> {ord} <=> $b -> {ord}} @result;

}

################################################################################

sub draw_table_header_row {

	my ($cells) = @_;
		
	return $_SKIN -> draw_table_header_row ($rows, [map {
		ref $_ eq ARRAY ? (join map {draw_table_header_cell ($_)} order_cells (@$_)) : draw_table_header_cell ($_)
	} order_cells (@$cells)]);
	
}

################################################################################

sub draw_table_header_cell {

	my ($cell) = @_;
	
	ref $cell eq HASH or $cell = {label => $cell};

	check_title ($cell);
	
	if ($cell -> {order}) {
	
		$cell -> {href} = {
			order                    => $cell -> {order}, 
			__last_last_query_string => $_REQUEST {__last_last_query_string},
		};
		
		$cell -> {href} -> {desc} = $_REQUEST {order} eq $cell -> {order} ? 1 - $_REQUEST {desc} : 0;

	}

	check_href ($cell) if $cell -> {href};	
	
	foreach my $field (qw(href_asc href_desc)) {
	
		$cell -> {$field} or next;
		
		my $h = {href => $cell -> {$field}};
		check_href ($h);
		$cell -> {$field} = $h -> {href};
	
	}
	
	$cell -> {colspan} ||= 1;
	$cell -> {rowspan} ||= 1;
	
	$cell -> {attributes} ||= {};
	$cell -> {attributes} -> {class}   ||= 'row-cell-header';
	$cell -> {attributes} -> {class}    .= '-no-scroll' if ($cell -> {no_scroll});
	$cell -> {attributes} -> {colspan} ||= $cell -> {colspan};
	$cell -> {attributes} -> {rowspan} ||= $cell -> {rowspan};
	
	return $_SKIN -> draw_table_header_cell ($cell);

}

################################################################################

sub draw_table_row {

	my ($n, $tr_callback) = @_;

	$i -> {__n} = $n;		
	$i -> {__types} = [];
	$i -> {__trs}   = [];
	
	$_SKIN -> {__current_row} = $i;

	my $tr_id = {href => 'id=' . $i -> {id}};
	check_href ($tr_id);
	$tr_id -> {href} =~ s{[\&\?]salt=[\d\.]+}{};
	$i -> {__tr_id} = $tr_id -> {href};

	foreach my $callback (@$tr_callback) {

		$_REQUEST {__uri_root} = $_REQUEST {__uri_root_common} . ($_REQUEST {__windows_ce} ? '' : '&__last_scrollable_table_row=' . $scrollable_row_id);

		$_SKIN -> start_table_row if $_SKIN -> {options} -> {no_buffering};
		my $tr = &$callback ();
		$_SKIN -> draw_table_row ($tr) if $_SKIN -> {options} -> {no_buffering};
							
		$tr or next;
		
		$scrollable_row_id ++;
		
		push @{$i -> {__trs}}, $tr unless $_SKIN -> {options} -> {no_buffering};
					
	}

	$_REQUEST {__uri_root} = $_REQUEST {__uri_root_common};
	
	if (@{$i -> {__types}} > 0) {			
		$i -> {__menu} = draw_vert_menu ($i, $i -> {__types});			
	}

}

################################################################################

sub draw_table {

	return '' if $_REQUEST {__only_form};

	my $headers = [];

	unless (ref $_[0] eq CODE or (ref $_[0] eq ARRAY and ref $_[0] -> [0] eq CODE)) {
		$headers = shift;
	}

	my ($tr_callback, $list, $options) = @_;
	
	if ($options -> {no_order}) {
		$_REQUEST {__no_order} = 1;
	} else {
		delete $_REQUEST {__no_order};
	}
	
	if ($conf -> {core_store_table_order} && !$options -> {no_order}) {

		our @_ORDER = ();
		our @_COLUMNS = ();
		our %_ORDER = ();
	
		my @header_cells = ();
		
		my $is_exists_subheaders;
		my $cells_cnt;

		foreach my $h (@$headers) {
		
			if (ref $h eq ARRAY) {
				$is_exists_subheaders = 1; last;
			};
			 
			ref $h eq HASH or ($h = {label => $h});
			 
			push @header_cells, $h;
			
			$cells_cnt += 1
				if $h -> {order} && exists $_QUERY -> {content} -> {columns} -> {$h -> {order}} && $_QUERY -> {content} -> {columns} -> {$h -> {order}} -> {ord};
				
		}		
	
		if (!$is_exists_subheaders) {

			my $i = 0;
			foreach my $h (@header_cells) {
			
				$i ++;
		
				push @_COLUMNS, $h;
			
				if ($_REQUEST {id___query} && !$_REQUEST {__edit__query}) {
					$h -> {ord}    = $cells_cnt && $h -> {order} && exists $_QUERY -> {content} -> {columns} -> {$h -> {order}} ? $_QUERY -> {content} -> {columns} -> {$h -> {order}} -> {ord} : $i;
					$h -> {__hidden} = $h -> {hidden};
					$h -> {hidden} = 1 if $h -> {ord} == 0;
				}
				
				$h -> {filters} = [];

				push @_ORDER, $h;

				$_ORDER {$h -> {order}} = $h
					if $h -> {order};
		
			}
		}
	}
		
	$options -> {type}   ||= $_REQUEST{type};
	
	$options -> {action} ||= 'add';
	$options -> {name}   ||= 'form';
	$options -> {target} ||= 'invisible';

	return '' if $options -> {off};		

	$_REQUEST {__salt} ||= rand () * time ();
	$_REQUEST {__uri_root_common} ||=  $_REQUEST {__uri} . '?salt=' . $_REQUEST {__salt} . '&sid=' . $_REQUEST {sid};

	ref $tr_callback eq ARRAY or $tr_callback = [$tr_callback];
		
	if (ref $options -> {title} eq HASH) {
				
		unless ($_REQUEST {select}) {
		
			$options -> {title} -> {height} ||= 10;
			$options -> {title} -> {label}  ||= '';		
			$options -> {title} = 
				draw_hr (%{$options -> {title}}) .
				draw_window_title ($options -> {title})
			
		}
		else {
			$options -> {title} = draw_window_title ($options -> {title}) 
				if $options -> {title} -> {label};
		}
		
	}
	
	if (ref $options -> {top_toolbar} eq ARRAY) {
		$options -> {top_toolbar} -> [0] -> {_list} = $list;		
		$options -> {top_toolbar} = draw_toolbar (@{ $options -> {top_toolbar} });
	}

	if ($conf -> {core_store_table_order} && !$options -> {no_order}) {
		fix___query ();
	}
	
	if (ref $options -> {path} eq ARRAY) {
		$options -> {path} = draw_path ($options, $options -> {path});
	}
	
	if ($options -> {'..'} && !$_REQUEST{lpt}) {
	
		my $url = $_REQUEST {__path} -> [-1];
		if ($_REQUEST {__last_query_string}) {
			$url = esc_href ();
		}
		
		$_REQUEST {__uri_root} = $_REQUEST {__uri_root_common} . ($_REQUEST {__windows_ce} ? '' : '&__last_scrollable_table_row=' . $scrollable_row_id);
	
		$options -> {dotdot} = draw_text_cell ({
			a_id  => 'dotdot',
			label => '..',
			href  => $url,
			no_select_href => 1,
			colspan => 0 + @$headers,
		});
		
		$scrollable_row_id ++;
		
		$_REQUEST {__uri_root} = $_REQUEST {__uri_root_common};

		hotkey ({code => Esc, data => 'dotdot'});

	}

	$options -> {header}   = draw_table_header ($headers) if @$headers > 0 && $_REQUEST {xls};
	
	$_REQUEST {__get_ids} = {};
	
	$_SKIN -> start_table ($options) if $_SKIN -> {options} -> {no_buffering};

	my $n = 0;
	
	if (ref $list eq 'DBI::st') {
	
		while (our $i = $list -> fetchrow_hashref) {
			draw_table_row ($n++, $tr_callback);
		}
		
		$list -> finish;
		
	}
	else {

		foreach our $i (@$list) {
			draw_table_row ($n++, $tr_callback);
		}
		
	}
	
	if ($_REQUEST {__gantt_from_year}) {
	
		$headers ||= [''];
		
		ref $headers -> [0] eq ARRAY or $headers = [$headers];

		foreach my $year ($_REQUEST {__gantt_from_year} .. $_REQUEST {__gantt_to_year}) {
		
			push @{$headers -> [0]}, {label => $year, colspan => 12};
			$headers -> [1] ||= [];
			push @{$headers -> [1]}, {label => 'I', colspan => 3};
			push @{$headers -> [1]}, {label => 'II', colspan => 3};
			push @{$headers -> [1]}, {label => 'III', colspan => 3};
			push @{$headers -> [1]}, {label => 'IV', colspan => 3};
			$headers -> [2] ||= [];
			
			
			
#			push @{$headers -> [2]}, qw(Я Ф М А М И И А С О Н Д);

			push @{$headers -> [2]}, {
				label => 'Я',
				title => "январь ${year} г.",
				attributes => {id => "gantt_${year}_01"},
			};
			push @{$headers -> [2]}, {
				label => 'Ф',
				title => "февраль ${year} г.",
				attributes => {id => "gantt_${year}_02"},
			};
			push @{$headers -> [2]}, {
				label => 'М',
				title => "март ${year} г.",
				attributes => {id => "gantt_${year}_03"},
			};
			push @{$headers -> [2]}, {
				label => 'А',
				title => "апрель ${year} г.",
				attributes => {id => "gantt_${year}_04"},
			};
			push @{$headers -> [2]}, {
				label => 'М',
				title => "май ${year} г.",
				attributes => {id => "gantt_${year}_05"},
			};
			push @{$headers -> [2]}, {
				label => 'И',
				title => "июнь ${year} г.",
				attributes => {id => "gantt_${year}_06"},
			};
			push @{$headers -> [2]}, {
				label => 'И',
				title => "июль ${year} г.",
				attributes => {id => "gantt_${year}_07"},
			};
			push @{$headers -> [2]}, {
				label => 'А',
				title => "август ${year} г.",
				attributes => {id => "gantt_${year}_08"},
			};
			push @{$headers -> [2]}, {
				label => 'С',
				title => "сентябрь ${year} г.",
				attributes => {id => "gantt_${year}_09"},
			};
			push @{$headers -> [2]}, {
				label => 'О',
				title => "октябрь ${year} г.",
				attributes => {id => "gantt_${year}_10"},
			};
			push @{$headers -> [2]}, {
				label => 'Н',
				title => "ноябрь ${year} г.",
				attributes => {id => "gantt_${year}_11"},
			};
			push @{$headers -> [2]}, {
				label => 'Д',
				title => "декабрь ${year} г.",
				attributes => {id => "gantt_${year}_12"},
			};
			
			

			$list -> [0] -> {__trs} -> [0] .= draw_text_cell ({colspan => 3, rowspan => 0 + @$list});
			$list -> [0] -> {__trs} -> [0] .= draw_text_cell ({colspan => 3, rowspan => 0 + @$list});
			$list -> [0] -> {__trs} -> [0] .= draw_text_cell ({colspan => 3, rowspan => 0 + @$list});
			$list -> [0] -> {__trs} -> [0] .= draw_text_cell ({colspan => 3, rowspan => 0 + @$list});
		
		}
	
	}
	
	$options -> {header}   = draw_table_header ($headers) if @$headers > 0 && !$_REQUEST {xls};
	
	foreach (keys %{$_REQUEST {__get_ids}}) {
	
		$_REQUEST {"__get_ids_$_"} = 1;
	
	}
	
	delete $_REQUEST {__get_ids};
	
	my $html = $_SKIN -> draw_table ($tr_callback, $list, $options);
	
	$lpt = 1 if $options -> {lpt};
	
	delete $_REQUEST {__gantt_from_year};
	delete $_REQUEST {__gantt_to_year};
	
	return $html;

}

################################################################################

sub draw_tree {

	my ($node_callback, $list, $options) = @_;
	
	return '' if $options -> {off};
	
	$options -> {width} ||= 250;
		
	$options -> {in_order} ||= 1 if $options -> {active} >= 2 && $_REQUEST {__parent};
	
	unless ($options -> {in_order}) {
	
		$list = tree_sort ($list);
		
		$options -> {in_order};
	
	}
	
	if ($options -> {active} == 1) {
	
		my $idx = {};
		
		foreach my $i (@$list) {
		
			$i -> {id}     += 0;
			$i -> {parent} += 0;
		
			$idx -> {$i -> {id}} = $i;
			$idx -> {$i -> {parent}} -> {cnt_children} ++;

		}

		my $p = {};

		if ($_REQUEST {__parent}) {
		
			$p -> {$_REQUEST {__parent}} = 1;
		
		}
		else {
		
			my $n = $idx -> {$options -> {selected_node}};
			
			while ($n) {
				$p -> {$n -> {id}} = 1;
				$n = $idx -> {$n -> {parent}};
			}

		}
				
		my @list = ();

		foreach my $i (@$list) {
		
			push @list, $i if $p -> {$i -> {parent}} || (!$_REQUEST {__parent} && $p -> {$i -> {id}});
		
		}

		$list = \@list;
	
	}
	
	if ($options -> {active}) {

		foreach my $i (@$list) {
		
			$i -> {id}     += 0;
			$i -> {parent} += 0;
		
			$idx -> {$i -> {id}} = $i;
			$idx -> {$i -> {parent}} -> {cnt_actual_children} ++;

		}

	}

	check_href ($options -> {top}) if $options -> {top};
	
	my $__parent = delete $_REQUEST {__parent};
	
	$options -> {href} ||= {};
	
	check_href ($options);
	
	my $url_base = {
		href	=> $options -> {url_base} || '',
	};
	
	if ($options -> {url_base}) {

		my $__last_query_string = $_REQUEST {__last_query_string};
		$_REQUEST {__last_query_string} = $options -> {no_no_esc} ? $__last_query_string : -1;
		check_href ($url_base);
		$url_base -> {href} .= '&__tree=1' if (!$options -> {no_tree} && $url_base -> {href} !~ /^javascript:/i);
		$_REQUEST {__last_query_string} = $__last_query_string;
		
		$options -> {url_base} = $url_base -> {href};
	}
	

	$_REQUEST {__parent} = $__parent;

	$_REQUEST {__salt} ||= rand () * time ();

	if (ref $options -> {title} eq HASH) {
				
		$options -> {title} -> {height} ||= 10;
		$options -> {title} = draw_window_title ($options -> {title}) if $options -> {title} -> {label};
		
	}

	my $n = 0;
	my $root_cnt;

	foreach our $i (@$list) {
		$i -> {__n} = $n;		
		
		$i -> {__node} = &$node_callback ();
	}
	
	
	my $html = $_SKIN -> draw_tree ($node_callback, $list, $options);

	return $html;

}

################################################################################

sub draw_node {

	my $options = shift;
	
	my $result = '';
	
	if ($options -> {href}) {

		my $__last_query_string = $_REQUEST {__last_query_string};
		$_REQUEST {__last_query_string} = $options -> {no_no_esc} ? $__last_query_string : -1;
		check_href ($options);
		$options -> {href} .= '&__tree=1' if (!$options -> {no_tree} && $options -> {href} !~ /^javascript:/i);
		$_REQUEST {__last_query_string} = $__last_query_string;

	} elsif ($options -> {url_tail}) {
	
		$options -> {href} = $options -> {url_tail};
		 
	}
	
	$options -> {parent} = -1 if ($options -> {parent} == 0);
	
	my @buttons;
	
	foreach my $button (@{$_ [0]}) {
	
		next if $button -> {off};
	
		$button -> {href} .= '&__tree=1';
		check_href ($button);
		
		$button -> {target} ||= '_content_iframe';

		if ($button -> {confirm}) {
			my $salt = rand;
			my $msg = js_escape ($button -> {confirm});
			$button -> {href} =~ s{\%}{\%25}gsm; 		# wrong, but MSIE uri_unescapes the 1st arg of window.open :-(
			$button -> {href} = qq [javascript:if (confirm ($msg)) {nope('$$button{href}', '$$button{target}')} else {document.body.style.cursor = 'default'; nop ();}];
		}

		check_title ($button, $i);
		
		push @buttons, $button; 
	
	}

	$i -> {__menu} = draw_vert_menu ($i, \@buttons) if ((grep {$_ ne BREAK} @buttons) > 0);
		
	return 	$_SKIN -> draw_node ($options, $i);
	
}

################################################################################

sub draw_suggest_page {

	my ($data) = @_;
	
	return $_SKIN -> draw_suggest_page ($data);

}

################################################################################

sub draw_page {

	my ($page) = @_;
	
	$_REQUEST {error} and return draw_error_page ($page);
	
	setup_skin ();

	$_SKIN -> {options} -> {no_presentation} and return $_SKIN -> draw_page ($page);

	$_REQUEST {__read_only} = 0 if $_REQUEST {__only_field};

	if (ref $page -> {content} eq HASH) {

		$page -> {content} -> {__read_only} = $_REQUEST {__read_only};
	
		$_REQUEST {__edit} = 1 if $conf -> {core_auto_edit} && $_REQUEST {id} && $page -> {content} -> {fake} > 0;	

	}

	our @scan2names            = ();	
	$page -> {scan2names}      = \@scan2names;

	our $scrollable_row_id     = 0;
	our $lpt                   = 0;

	$_REQUEST {__script}      .= "; the_page_title = '$_REQUEST{__page_title}';";
	$_REQUEST {__on_load}     .= "; if (!window.top.title_set) window.top.document.title = the_page_title;";

	$_REQUEST {__invisibles}   = ['invisible'];

	eval {
		$_SKIN -> {subset}       = $_SUBSET;
		$_SKIN -> start_page ($page) if $_SKIN -> {options} -> {no_buffering};
		$page  -> {auth_toolbar} = draw_auth_toolbar ();
		$page  -> {body} 	 = call_for_role (($_REQUEST {id} ? 'draw_item_of_' : 'draw_') . $page -> {type}, $page -> {content}) unless $_REQUEST {__only_menu}; 
		$page  -> {menu_data}    = Storable::dclone ($page -> {menu});
		$page  -> {menu}         = draw_menu ($page -> {menu}, $page -> {highlighted_type}, {lpt => $lpt});
	};
	
	$@ and return draw_error_page ($page, $@);
	
	($_REQUEST {__only_field} ? $_JS_SKIN : $_SKIN) -> draw_page ($page);

}

################################################################################

sub draw_error_page {

	my $page = $_[0];
	
	$_REQUEST {error} ||= $_[1];
	
	Carp::cluck $_REQUEST {error};
	
	if ($_REQUEST {error} =~ s{^\#(\w+)\#\:}{}) {
	
		$page -> {error_field} = $1;
	
		($_REQUEST {error}) = split / at/sm, $_REQUEST {error}; 
	
	}

	setup_skin ();
		
	$_REQUEST {__response_started} and $_REQUEST {error} =~ s{\n}{<br>}gsm and return $_REQUEST {error};

	return $_SKIN -> draw_error_page ($page);

}

################################################################################

sub draw_redirect_page {

	my ($page) = @_;

	setup_skin ({kind => 'redirect'});

	return $_SKIN -> draw_redirect_page ($page);

}

################################################################################

sub lrt_print {
	$_SKIN -> lrt_print (@_);
}

################################################################################

sub lrt_println {
	$_SKIN -> lrt_println (@_);
}

################################################################################

sub lrt_ok {
	$_SKIN -> lrt_ok (@_);
}

################################################################################

sub lrt_start {

	setup_skin ();
	
	$_REQUEST {__response_started} = 1;
	$_REQUEST {__response_sent} = 1;

	$_SKIN -> lrt_start (@_);
	
}

################################################################################

sub lrt_finish {

	my ($banner, $href, $options) = @_;

	if ($_USER -> {peer_server}) {
	
		$_REQUEST {sid} = sql_select_scalar ("SELECT peer_id FROM $conf->{systables}->{sessions} WHERE id = ?", $_REQUEST {sid});
	
	}

	$href = check_href ({href => $href});
	
	
	if ($options -> {kind} eq 'download') {
	
		$options -> {toolbar} = draw_centered_toolbar ({}, [
			{
				icon   => 'print',
				label  => $i18n -> {download},
				href   => $href,
				target => 'invisible',
				id     => 'download',
			},
			{
				icon   => 'cancel',
				label  => $i18n -> {cancel},
				href   => 'javaScript:history.go(-1)',
			},
		]);

	}
		
	$_SKIN -> lrt_finish ($banner, $href, $options);
	
}

################################################################################

sub dialog_close {

	my ($result) = @_;
	
	$result ||= {};
	
	setup_skin ();
	
	$_SKIN -> dialog_close ($result);
	
	$_REQUEST {__response_sent} = 1;

}

################################################################################

sub dialog_open {

	my ($arg, $options) = @_;
	
	$options -> {id} = ++ $_REQUEST {__dialog_cnt};
	
	$options -> {dialogHeight} ||= $options -> {height} || 'screen.availHeight - (screen.availHeight <= 600 ? 50 : 100)';
	$options -> {dialogWidth}  ||= $options -> {width}  || 'screen.availWidth - (screen.availWidth <= 800 ? 50 : 100)';

	$arg ||= {};
	
	check_href ($arg);

	$_REQUEST {__script} .= <<EOJS;
		var dialog_open_$options->{id} = @{[ $_JSON -> encode ($arg) ]};
		var dialog_open_$options->{id}_width = $options->{dialogWidth};
		var dialog_open_$options->{id}_height = $options->{dialogHeight};
EOJS
		
	$options -> {dialogHeight} .= 'px';
	$options -> {dialogWidth} .= 'px';
	
	return $_SKIN -> dialog_open ($arg, $options);

}

################################################################################

sub out_html {

	my ($options, $html) = @_;

	$html or return;
	
	return if $_REQUEST {__response_sent};

	my $time = time;

	$_REQUEST {__out_html_time} = $time;  

	if ($conf -> {core_sweep_spaces}) {
		$html =~ s{^\s+}{}gsm;
		$html =~ s{[ \t]+}{ }g;
	}

	unless ($preconf -> {core_no_morons}) {
		$html =~ s{window\.open}{nope}gsm;
	}
	
	if ($] > 5.007) {
		require Encode;
		$html = Encode::encode ('windows-1252', $html);
	}

	if ($_REQUEST {__response_started}) {
		print $html;
		return;
	}

	$_REQUEST {__content_type} ||= 'text/html; charset=' . $i18n -> {_charset};

	$r -> content_type ($_REQUEST {__content_type});
	$r -> headers_out -> {'X-Powered-By'} = 'Eludia/' . $Eludia::VERSION;
	$r -> headers_out -> {'P3P'} = 'CP="IDC DSP COR ADM DEVi TAIi PSA PSD IVAi IVDi CONi HIS OUR IND CNT"';

	$preconf -> {core_mtu} ||= 1500;
	
	if (
		$preconf -> {core_gzip} &&
		400 + length $html > $preconf -> {core_mtu} &&
		($r -> headers_in -> {'Accept-Encoding'} =~ /gzip/)
	) {
		
		$r -> content_encoding ('gzip');
		
		unless ($_REQUEST {__is_gzipped}) {
			
			my $time = time;
			my $old_size = length $html;
			
			my $z;
			my $x = new Compress::Raw::Zlib::Deflate (-Level => 9, -CRC32 => 1);
			$x -> deflate ($html, $z) ;
			$x -> flush ($z) ;
			$html = "\37\213\b\0\0\0\0\0\0\377" . substr ($z, 2, (length $z) - 6) . pack ('VV', $x -> crc32, length $html);
			$_REQUEST {__is_gzipped} = 1;
			
			my $new_size = length $html;

			my $ratio = int (10000 * ($old_size - $new_size) / $old_size) / 100;
			
			__log_profilinig ($time, " <gzip: $old_size -> $new_size, $ratio%>");

		}
	}

	$r -> headers_out -> {'Content-Length'} = length $html;

	send_http_header ();

	$r -> header_only && !MP2 or print $html;
	
	$_REQUEST {__response_sent} = 1;

	__log_profilinig ($time, ' <out_html: ' . (length $html) . ' bytes>');
	
	return _ok ();

}

#################################################################################

sub setup_skin {

	my ($options) = @_;

	eval {$_REQUEST {__skin} ||= get_skin_name ()};

	unless ($_REQUEST {__skin}) {

		delete $_REQUEST {__x} if $preconf -> {core_no_xml};

		if ($_REQUEST {xls}) {
			$_REQUEST {__skin} = 'XL';
		}
		elsif (($_REQUEST {__dump} || $_REQUEST {__d}) && $preconf -> {core_show_dump}) {
			$_REQUEST {__skin} = 'Dumper';
		}
		elsif ($_REQUEST {__proto}) {
			$_REQUEST {__skin} = 'XMLProto';
		}
		elsif ($_REQUEST {__x}) {
			$_REQUEST {__skin} = 'XMLDumper';
		}
		elsif ($_REQUEST {__windows_ce}) {
			$_REQUEST {__skin} = 'WinCE';
		}

	}

	$_REQUEST {__skin} ||= $preconf -> {core_skin};
	$_REQUEST {__skin} ||= 'Classic';

	$_REQUEST {__skin}   = 'TurboMilk_Gecko' if $_REQUEST {__skin} =~ /^TurboMilk/ && $r -> headers_in -> {'User-Agent'} =~ /Gecko/;

	$options -> {kind} = 'error' if $_REQUEST {error};

	if ($options -> {kind} && !$_REQUEST {__response_started}) {
		eval "require Eludia::Presentation::Skins::$_REQUEST{__skin}";
		$_REQUEST {__skin} = (${"Eludia::Presentation::Skins::$_REQUEST{__skin}::replacement"} -> {$options->{kind}} ||= $_REQUEST {__skin});
	}

	our $_SKIN = "Eludia::Presentation::Skins::$_REQUEST{__skin}";
	eval "require $_SKIN";
	warn $@ if $@;

	our $_JS_SKIN = "Eludia::Presentation::Skins::JS";
	eval "require $_JS_SKIN";
	warn $@ if $@;
	
	$_REQUEST {__static_site} = '';
	
	if ($preconf -> {static_site}) {
	
		if (ref $preconf -> {static_site} eq CODE) {
		
			$_REQUEST {__static_site} = &{$preconf -> {static_site}} ();
		
		}
		elsif (! ref $preconf -> {static_site}) {

			$_REQUEST {__static_site} = $preconf -> {static_site};

		}
		else {
		
			die "Invalid \$preconf -> {static_site}: " . Dumper ($preconf -> {static_site});
		
		}
			
	}	
	
	$_REQUEST {__static_url}  = '/i/_skins/' . $_REQUEST {__skin};
	$_REQUEST {__static_salt} = $_REQUEST {sid} || rand ();

	foreach my $package ($_SKIN, $_JS_SKIN) {

		attach_globals ($_PACKAGE => $package, qw(
			_PACKAGE
			_REQUEST
			_COOKIE
			_COOKIES
			_USER
			_QUERY
			SQL_VERSION
			conf
			preconf
			r
			i18n
			create_url
			dump_attributes
			dump_tag
			_SUBSET
			_JSON
			tree_sort
			adjust_esc
			out_html
			user_agent
			dump_hiddens
			darn
		));

	}

	$_SKIN -> {options} ||= $_SKIN -> options;

	$_REQUEST {__no_navigation} ||= $_SKIN -> {options} -> {no_navigation};
	
	check_static_files ();
	
	$_REQUEST {__static_site} ||= $r -> document_root () if $ENV {REMOTE_ADDR} eq '127.0.0.1' and $^O eq 'MSWin32';
	
	$_REQUEST {__static_url} = $_REQUEST {__static_site} . $_REQUEST {__static_url} if $_REQUEST {__static_site};

	setup_json ();

}

#################################################################################

sub check_static_files {

	return if $_SKIN -> {static_ok} -> {$_NEW_PACKAGE};
	return if $_SKIN -> {options} -> {no_presentation};
	return if $_SKIN -> {options} -> {no_static};
	$r or return;
	
	my $time = time();
	
	my $skin_root = $r -> document_root () . $_REQUEST {__static_url};
		
	-d $skin_root or mkdir $skin_root or die "Can't create $skin_root: $!";

	my $static_path = $_SKIN -> static_path;

	opendir (DIR, $static_path) || die "can't opendir $static_path: $!";
	my @files = readdir (DIR);
	closedir DIR;

	foreach my $src (@files) {
		$src =~ /\.pm$/ or next;
		unlink $skin_root . '/' . $`;
		File::Copy::copy ($static_path . $src, $skin_root . '/' . $`) or die "can't copy ${static_path}${src} to ${skin_root}/${`}: $!";
	}
	
	my $favicon = $r -> document_root () . '/i/favicon.ico';
	
	if (-f $favicon) {
		
		File::Copy::copy ($favicon, $skin_root . '/favicon.ico') or die "can't copy favicon.ico: $!";
		
	}

	my $over_root = $r -> document_root () . '/i/skins/' . $_REQUEST {__skin};

	if (-d $over_root) {

		opendir (DIR, $over_root) || die "can't opendir $over_root: $!";
		my @files = readdir (DIR);
		closedir DIR;

		foreach my $src (@files) {
			$src =~ /\w\.\w+$/ or next;
			File::Copy::copy ($over_root . '/' . $src,  $skin_root . '/' . $src) or die "can't copy $src: $!";
		}

	}
		
 	if ($preconf -> {core_gzip}) {

		foreach my $fn ('navigation.js', 'eludia.css', 'navigation_setup.js') {
		
			if (-f "$skin_root/$fn") {
			
				my $x = new Compress::Raw::Zlib::Deflate (-Level => 9, -CRC32 => 1);
	
				open (IN, "$skin_root/$fn");
				my $js = join ('', <IN>);
				close IN;
	
				open (OUT, ">$skin_root/$fn.gz");
				binmode (OUT);
	
				my $z;
				$x -> deflate ($js, $z) ;
				$x -> flush ($z) ;
	
				print OUT "\37\213\b\0\0\0\0\0\0\377" . substr ($z, 2, (length $z) - 6) . pack ('VV', $x -> crc32, length $js);
				close OUT;
			}
		}
	}

	$_SKIN -> {static_ok} -> {$_NEW_PACKAGE} = 1;

	__log_profilinig ($time, ' check_static_files');

}

1;
