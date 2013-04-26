no warnings;

################################################################################

sub js ($)    {$_REQUEST {__script} .= ";\n$_[0];\n"; return ''}

sub j  ($)    {js "\$(document).ready (function () { $_[0] })"}

sub function (@)  {

	my $name = shift;
	my $code = pop;
	my $args = join ',', @_;
	
	js ("function $name ($args) {$code}");

}

################################################################################

sub json_dump_to_function {

	my ($name, $data) = @_;

	return "\n function $name () {\n return " . $_JSON -> encode ($data) . "\n}\n";

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

	return $s if $_SKIN -> {options} -> {no_trunc_string};
	
	my $cached = $_REQUEST {__trunc_string} -> {$s, $len};
	
	return $cached if $cached;
	
	my $length = length $s;
	
	return $s if $length <= $len;
	
	my $has_ext_chars = $s =~ /(\&[a-z]+)|(\&#\d+)/;
	
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
	
	$href =~ s{&__only_table=\w+}{};

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
	
	my $title = exists $options -> {title} ? $options -> {title} : '' . $options -> {label};

	$title =~ s{\<.*?\>}{}g;
	$title =~ s{^(\&nbsp\;|\s)+}{};
	
	$title = HTML::Entities::decode_entities ($title) if $title =~ /\&/;
	$title =~ s{\"}{\&quot\;}g;

	$options -> {attributes} -> {title} = $title;

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
				$h {$k} = encode_entities ($h {$k}, '"');

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

	$options -> {label} = $i18n -> {$options -> {label}}
		if $options -> {label};

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

	$options -> {path} ||= $data -> {path};

	__profile_in ('draw.form' => {label => ref $options -> {path} eq ARRAY && @{$options -> {path}} > 0 ? $options -> {path} -> [0] -> {name} : undef}); 

	$options -> {hr} = defined $options -> {hr} ? $options -> {hr} : 10;
	$options -> {hr} = $_REQUEST {__tree} ? '' : draw_hr (height => $options -> {hr});
	
	if (ref $data eq HASH && $data -> {fake} == -1 && !exists $options -> {no_edit}) {
		$options -> {no_edit} = 1;
	}
	
	$options -> {data} = $data;
	
	$options -> {name}    ||= 'form';
	
	unless (!$_REQUEST {__only_form} or $_REQUEST {__only_form} eq $options -> {name}) {
	
		__profile_out ('draw.form'); 
	
		return '';
		
	}

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
			foreach (map {_adjust_field ($_)} @$field) {
				next if $_ -> {off} && $data -> {id};
				next if $_REQUEST {__read_only} && $_ -> {type} eq 'password';
				push @row, $_;
			}
			next if @row == 0;
			$row = \@row;
		}
		else {
			ref $field or $field = {name => $field};
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
	
	my $html = $_SKIN -> draw_form ($options);
		
	__profile_out ('draw.form'); 

	return $html;

}

################################################################################

sub _adjust_field {

	my ($field, $data) = @_;
	
	ref $field or $field = {name => $field};

	my $table_def = $DB_MODEL -> {tables} -> {$_REQUEST {__the_table} ||= $_REQUEST {type}};
	
	if ($table_def) {
	
		my $field_def = $table_def -> {columns} -> {$field -> {name}};

		if ($field_def) {
		
			my %field_options = %{$field_def -> {FIELD_OPTIONS} || {}};
			
			$field_options {type}  ||= $field_def -> {TYPE};
			
			unless ($field -> {label_off}) {

				$field_options {label} ||= $field_def -> {REMARKS};
		
				$field_options {label} ||= $field_def -> {label};

			}

			%$field = (%field_options, %$field);
		
		}
	
	}

	$field -> {label} = $i18n -> {$field -> {label}}
		if $field -> {label};
	$field -> {empty} = $i18n -> {$field -> {empty}}
		if $field -> {empty};

	$field -> {data_source} and $field -> {values} ||= ($data -> {$field -> {data_source}} ||= sql_select_vocabulary ($field -> {data_source}));
	
	return $field;

}

################################################################################

sub draw_form_field_of_type {

	my ($field) = @_;

	return call_from_file ("Eludia/Presentation/FormFields/$field->{type}.pm", "draw_form_field_$$field{type}", @_);

}

################################################################################

sub draw_form_field {

	my ($field, $data, $form_options) = @_;

	$field = _adjust_field ($field, $data);

	if (
		($_REQUEST {__read_only} or $field -> {read_only})
		 &&  $field -> {type} ne 'hgroup'
		 &&  $field -> {type} ne 'banner'
		 &&  $field -> {type} ne 'button'
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
	
	$field -> {html} = draw_form_field_of_type ($field, $data, $form_options);
	
	$conf -> {kb_options_focus} ||= $conf -> {kb_options_buttons};
	$conf -> {kb_options_focus} ||= {ctrl => 1, alt => 1};

	register_hotkey ($field, 'focus', '_' . $field -> {name}, $conf -> {kb_options_focus});

	$field -> {label} .= $field -> {label} ? ':' : '&nbsp;';

	$field -> {colspan} ||= $_REQUEST {__max_cols} - 1;

	$field -> {state}     = $data -> {fake} == -1 ? 'deleted' : $_REQUEST {__read_only} ? 'passive' : 'active';

	$field -> {label_width} = '20%' unless $field -> {is_slave};	

	$_REQUEST {__no_navigation} ||= $_REQUEST {__only_field};

	return $_REQUEST {__only_field} ? $_SKIN -> draw_form_field__only_field ($field) : $_SKIN -> draw_form_field ($field);

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

sub adjust_form_field_options {

	return if $_SKIN -> {options} -> {no_server_html};

	my ($options) = @_;
	
	foreach (map {$_SKIN . '::__adjust_form_field' . $_} ('', "_$options->{type}")) {

		eval {&$_ ($options)};

	}

}

################################################################################

sub js_detail {

	return &{$_SKIN . '::js_detail'} (@_);

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

			$button -> {html} = call_from_file ("Eludia/Presentation/ToolbarElements/$button->{type}.pm", 'draw_toolbar_' . $button -> {type}, $button, $options -> {_list}) unless $_REQUEST {__edit_query};

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

	$_SKIN -> __adjust_button_href ($options);

	return $_SKIN -> draw_centered_toolbar_button (@_);

}

################################################################################

sub draw_centered_toolbar {

	$_REQUEST {lpt} and return '';

	my ($options, $list) = @_;
	
	$options -> {off} and return '';

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
			href => $_SKIN -> __submit_href ($name), 
			off  => $_REQUEST {__read_only} || $options -> {no_ok},
			(exists $options -> {confirm_ok} ? (confirm => $options -> {confirm_ok}) : ()),
		},
		{
			preset => 'edit',
			label => $options -> {label_edit}, 
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
			href  => js_set_select_option ('', {
				id       => $data -> {id}, 
				label    => $options -> {choose_select_label} || $data -> {label},
				question => $data -> {question},
			}),
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
	
		push @$types, $_SKIN -> draw_dump_button ();
	
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

	$conf -> {kb_options_menu} ||= {ctrl => 1, alt => 1};

	foreach my $type (@$types)	{
	
		next if $type -> {off};

		$type -> {href}   ||= "/?type=$$type{name}" if $type -> {name};

		$type -> {href} .= "&role=$$type{role}" if $type -> {role};
			
		check_href ($type);

		$type -> {name}   ||= ('' . $type -> {items} || '' . $type);

		$type -> {side}   ||= 'left_items';
		
		$type -> {target} ||= '_self';

		register_hotkey ($type, 'href', 'main_menu_' . $type -> {name}, $conf -> {kb_options_menu});
		
		if (ref $type -> {items} eq ARRAY && (!$_REQUEST {__edit} || $_SKIN -> {options} -> {core_unblock_navigation})) {

			$type -> {vert_menu} = draw_vert_menu ($type -> {name}, $type -> {items}, 0, 1);

		} 
		
		$_SKIN -> {options} -> {no_server_html} or $_SKIN -> __adjust_menu_item ($type);
		
		push @{$_options -> {$type -> {side}}}, $type;
	
	}
	
	return $_SKIN -> draw_menu ($_options);

}

################################################################################

sub draw_vert_menu {

	my ($name, $types, $level, $is_main) = @_;
	
	$level ||= 1;
	
	$types = [grep {!$_ -> {off}} @$types];
	
	my @types = ();
	
	foreach my $type (@$types) {
	
		next if $type -> {off};
	
		if (ref $type -> {items} eq ARRAY && !$_REQUEST {__edit}) {

			$type -> {name}     ||= '' . $type if $type -> {items};
			
			$type -> {vert_menu}  = draw_vert_menu ($type -> {name}, $type -> {items}, $level + 1, $is_main);
			
		}
		else {
			
			$type -> {href}     ||= "/?type=$$type{name}";
			
			$type -> {href}      .= "&role=$$type{role}" if $type -> {role};

			check_href ($type);

			$type -> {target}   ||= "_self";

		}

		$_SKIN -> {options} -> {no_server_html} or $_SKIN -> __adjust_vert_menu_item ($type, $name, $types, $level, $is_main);

		push @types, $type;

	}

	return $_SKIN -> draw_vert_menu ($name, \@types, $level);

}

################################################################################

sub js_set_select_option {
	return $_SKIN -> js_set_select_option (@_);
}

################################################################################

sub draw_cells {

	my $options = (ref $_[0] eq HASH) ? shift () : {};

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

		my $max_ord = 0;
		foreach my $i (@_COLUMNS) {
			$max_ord = $i -> {ord} if $max_ord < $i -> {ord} && !$i -> {hidden};
		}
		my $power = length ($max_ord) - 1;
		my @__COLUMNS;
		foreach my $i (@_COLUMNS) {
			if ($i -> {has_child}) {
				push @__COLUMNS, {has_child => 1};
				next;
			}
			my $i_power = length ($i -> {ord}) - 1;
			$i_power = int ($i_power / 3)
				if $i_power % 3;
			my $ii = {%$i};
			$ii -> {ord} *= 1 . (0 x ($power - $i_power))
				unless $i_power == $power;
			push @__COLUMNS, $ii;
		}

		for (my ($i, $j) = 0; $i < @__COLUMNS; $i ++) {

			my $h = $__COLUMNS [$i];

			ref $h eq HASH && !$h -> {has_child} or next;

			last if $j >= @{$_ [0]};
			
			$_ [0] [$j] = {label => $_ [0] [$j]} unless ref $_ [0] [$j] eq HASH;

			$_ [0] [$j] -> {ord} ||= $__COLUMNS [$i] -> {ord};

			$_ [0] [$j] -> {hidden} ||= $__COLUMNS [$i] -> {hidden};

			$j++;
		}

	}

	my @cells = order_cells (@{$_[0]});

	$options -> {target} ||= '_self';
	
	foreach my $cell (@cells) {
	
		ref $cell or $cell = {label => $cell, type => 'text'};

		if ($options -> {href}) {

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

		$options -> {__fixed_cols} ++ if $cell -> {no_scroll};

		$cell -> {type}   = 'text' if ($cell -> {off} || $cell -> {read_only}) && !$cell -> {icon};

		$cell -> {type} ||= 
		
			$cell -> {icon}           ? 'button'   :
			exists $cell -> {checked} ? 'checkbox' :
			'text';

	}
	
	if ($_REQUEST {select} && !$options -> {select_label}) {

		foreach my $cell (@cells) {

			next if $cell -> {no_select_href} ||  $cell    -> {label}        eq '';

			$cell         -> {select_href}    and $options -> {select_label} =  $cell -> {label} and last;

			$options      -> {select_label}   ||= $cell    -> {label};

		}

	}
	
	$result .= call_from_file ("Eludia/Presentation/TableCells/$_->{type}.pm", "draw_$_->{type}_cell", $_, $options) foreach @cells;

	if ($options -> {gantt}) {

		my $g = $i -> {__gantt} = $options -> {gantt};
		
		$_REQUEST {__gantt_from_year} ||= 3000;
		$_REQUEST {__gantt_to_year}   ||= 1;

		foreach my $v (values %$g) {
				
			foreach my $ft ('from', 'to') {				

				$v -> {$ft} =~ s{^(\d\d).(\d\d).(\d\d\d\d)$}{$3-$2-$1};
				$v -> {$ft} =~ /^(\d\d\d\d)/;

				$_REQUEST {__gantt_from_year} <= $1 or $_REQUEST {__gantt_from_year} = $1;
				$_REQUEST {__gantt_to_year}   >= $1 or $_REQUEST {__gantt_to_year}   = $1;

			}
			
		}

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

	return if $_SKIN -> {options} -> {no_server_html};

	&{"${_SKIN}::__adjust_row_cell_style"} (@_);

}

################################################################################

sub draw_row_button { draw_button_cell (@_) }

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
		next if ref $c eq HASH && $c -> {hidden};
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

	$cell -> {label} = $i18n -> {$cell -> {label}}
		if $cell -> {label};


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

###############################################################################

sub get_table_header_field {

	my ($headers) = @_;

	my $result_headers = [];

	if (ref $headers -> [0] eq ARRAY) {

		my $result_headers = get_composite_table_headers ({headers => $headers});

		return $result_headers -> {headers};
	}

	for (my $i = 0; $i < @$headers; $i++) {

		push @$result_headers, $headers -> [$i];

	}

	return $result_headers;
}


###############################################################################

sub get_composite_table_headers {

	my ($options) = @_;

	my $headers = $options -> {headers};
	my $i       = $options -> {i} + 0;
	my $first   = $options -> {first} + 0;
	my $colspan = $options -> {colspan} || 65535;

	my $result_headers = [];

	my $cnt = @{$headers -> [$i]};

	my $f = $first;
	my $colspan1 = $colspan;

	my $j = $f;

	for (; $j < $cnt && $j < $colspan + $f && $colspan1 > 0; $j++) {

		push @$result_headers, $headers -> [$i] -> [$j];

		if ($headers -> [$i] -> [$j] -> {colspan}) {

			my $result = get_composite_table_headers ({
				headers => $headers,
				i       => $i + 1,
				first   => $first,
				colspan => $headers -> [$i] -> [$j] -> {colspan},
			});

			for (my $k = 0; $k < @{$result -> {headers}}; $k++) {

				$result -> {headers} -> [$k] -> {parent} = $headers -> [$i] -> [$j];
				$headers -> [$i] -> [$j] -> {has_child} ++;

				push @$result_headers, $result -> {headers} -> [$k];
			}

			$first += $result -> {count};

			$colspan1 -= $headers -> [$i] -> [$j] -> {colspan};

		}

	}

	return {headers => $result_headers, count => ($j - $f)};

}

################################################################################

sub is_not_possible_order {

	my ($headers) = @_;

	foreach my $h (@{$headers}) {
		if (ref $h eq ARRAY) {
			return 1 if is_not_possible_order ($h);
		} else {
			return 1 unless ref $h eq HASH && ($h -> {order} || $h -> {no_order});
		}
	}

	return 0;

}
################################################################################

sub draw_table {

	return '' if $_REQUEST {__only_form};

	my $headers = [];

	unless (ref $_[0] eq CODE or (ref $_[0] eq ARRAY and ref $_[0] -> [0] eq CODE)) {
		$headers = shift;
	}

	my ($tr_callback, $list, $options) = @_;

	__profile_in ('draw.table' => {label => exists $options -> {title} && $options -> {title} ? $options -> {title} -> {label} : $options -> {name}});

	$options -> {no_order} = is_not_possible_order ($headers) unless (exists $options -> {no_order});

	if ($options -> {no_order}) {
		$_REQUEST {__no_order} = 1;
	} else {
		delete $_REQUEST {__no_order};
	}

	my @old_headers = @$headers;

	if ($conf -> {core_store_table_order} && !$options -> {no_order}) {

		our @_ORDER = ();
		our @_COLUMNS = ();
		our %_ORDER = ();

		my @header_cells = ();
		
		my $is_exists_subheaders;
		my $cells_cnt;

		$headers = get_table_header_field ($headers);

		foreach my $h (@$headers) {

			ref $h eq HASH or ($h = {label => $h});

			push @header_cells, $h;

			$cells_cnt += 1
				if (($h -> {order} || $h -> {no_order})
					&& exists $_QUERY -> {content} -> {columns} -> {$h -> {order} || $h -> {no_order}}
					&& $_QUERY -> {content} -> {columns} -> {$h -> {order} || $h -> {no_order}} -> {ord});

		}

		foreach my $h (@header_cells) {

			push @_COLUMNS, $h;

			if ($_REQUEST {id___query} && !$_REQUEST {__edit_query}) {
				if ($cells_cnt && ($h -> {order} || $h -> {no_order}) && exists $_QUERY -> {content} -> {columns} -> {$h -> {order} || $h -> {no_order}}) {
					if ($_QUERY -> {content} -> {columns} -> {$h -> {order} || $h -> {no_order}} -> {ord} == 0) {
						my $p = $h -> {parent};
						while ($p -> {label}) {
							$p -> {colspan} --;
							$p -> {hidden} = 1 if $p -> {colspan} == 0;
							$p = $p -> {parent};
						}
					} else {
						$h -> {ord} = ($h -> {parent} -> {ord}) * 1000 + $_QUERY -> {content} -> {columns} -> {$h -> {order} || $h -> {no_order}} -> {ord};
					}
				}
				$h -> {__hidden} = $h -> {hidden};
				$h -> {hidden}   = 1 if ($h -> {ord} == 0 || defined $h -> {parent} -> {ord} && $h -> {parent} -> {ord} == 0);
			}

			$h -> {filters} = [];

			push @_ORDER, $h;

			$_ORDER {$h -> {order} || $h -> {no_order}} = $h
				if ($h -> {order} || $h -> {no_order});

		}
	}

	$options -> {type}   ||= $_REQUEST{type};
	
	$options -> {action} ||= 'add';
	$options -> {name}   ||= 'form';
	$options -> {target} ||= 'invisible';

	if ($options -> {off}) {
	
		__profile_out ('draw.table' => {label => "[OFF] $options->{title}->{label}"});
		
		return '';

	}

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

	$headers = \@old_headers;

	$options -> {header}   = draw_table_header ($headers) if @$headers > 0 && $_REQUEST {xls};

	$_REQUEST {__get_ids} = {};
	
	$_SKIN -> start_table ($options) if $_SKIN -> {options} -> {no_buffering};

	my $n = 0;
	
	local $i;
	
	foreach $i (@$list) {

		$i -> {__n} = ++ $n;
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
			
			$tr or next;

			if ($_SKIN -> {options} -> {no_buffering}) {
			
				$_SKIN -> draw_table_row ($tr);
			
			}
			else {

				push @{$i -> {__trs}}, $tr;

			}

			$scrollable_row_id ++;

		}

		if (@{$i -> {__types}} > 0) {			
		
			$i -> {__menu} = draw_vert_menu ($i, $i -> {__types});
			
		}
		
	}		
	
	$_REQUEST {__uri_root} = $_REQUEST {__uri_root_common};

	if ($_REQUEST {__gantt_from_year}) {
	
		$headers ||= [''];
		
		ref $headers -> [0] eq ARRAY or $headers = [$headers];

		foreach my $year ($_REQUEST {__gantt_from_year} .. $_REQUEST {__gantt_to_year}) {
		
			push @{$headers -> [0]}, {label => $year, colspan => 12};
			$headers -> [1] ||= [];

			push @{$headers -> [1]}, {label => $_, colspan => 3} foreach qw (I II III IV);
			$headers -> [2] ||= [];
			
			push @{$headers -> [2]}, {
				label => (substr $i18n -> {month_names_1} -> [$_ - 1], 0, 1),
				title => $i18n -> {month_names_1} -> [$_ - 1] . " ${year}",
				attributes => {id => sprintf ('gantt_%04d_%02d', $year, $_)},
			} foreach (1 .. 12);

			$list -> [0] -> {__trs} -> [0] .= draw_text_cell ({colspan => 3, rowspan => 0 + @$list}) x 4;
		
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

	__profile_out ('draw.table');

	return $html;

}

################################################################################

sub draw_tree {

	my ($node_callback, $list, $options) = @_;
	
	return '' if $options -> {off};
	
	__profile_in ('draw.tree');
	
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

	__profile_out ('draw.tree');

	return $html;

}

################################################################################

sub draw_node {

	my $options = shift;
	
	my $result = '';

	$options -> {label} =~ s/[\r\n]+/ /g;

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

sub draw_calendar_year {

	my ($callback, $options) = @_;

	my $empty      = {label => '', bgcolor => '#EFEFEF'};

	my @wdays      = map {{label => $_, bold => 1, bgcolor => '#FFFFEF', attributes => {align => 'center'}}} @{$i18n -> {wd}};

	my $spacer     = $_REQUEST {xls} ? '' : '<img src="/i/_skins/TurboMilk/0.gif" border=0 height=10 width=6>';
	
	my $spacer1    = $_REQUEST {xls} ? '' : '<img src="/i/_skins/TurboMilk/0.gif" border=0 height=1 width=1>';

	my $lines = [map {
	
		ref $_ ne HASH ? {fields => $_} :
			
		$_ -> {type} eq 'finish_quarter' ? () :
		
		(
		
			{type => 'month_names', quarter => $_ -> {quarter}},
			
			{type => 'day_names'},

		)
	
	} @{cal_year ($options -> {year} || $_REQUEST {year}) -> {lines}}];
	
	my $empty_cell = "<td class='row-cell-transparent' bgcolor='#efefef'>$spacer1</td>";

	my $xlempty    = $_REQUEST {xls} ? $empty_cell : '';

	my $day_names = $xlempty . draw_cells ({}, [
		@wdays, $empty,
		@wdays, $empty,
		@wdays
	]);			

	my $day = {
		no_check_href => 1,
		a_class => 'row-cell',
		attributes	=> {
			align	=> 'center',
			class   => 'row-cell-transparent',
		},
	};


		draw_table (

			sub {
			
				$i -> {type} eq 'day_names' and return $day_names;

				$i -> {type} eq 'month_names' and return
				
					$xlempty .
					
					(join $empty_cell, map {
					
						draw_text_cell ({
						
							label => $spacer . $i18n -> {month_names_1} -> [$_ -> {month} - 1],
							colspan => 7,
							bgcolor => '#FFFFEF',
							bold => 1,
							max_len => 10000,
							
						})} @{$i -> {quarter} -> {months}
					
					});
												
				my $s = '';
				
				foreach my $week (@{$i -> {fields}}) {
				
					$s .= $empty_cell if $s;
					
					for (my $wd = 0; $wd < 7; $wd ++) {
					
						my $d = $week -> [$wd];
												
						$day -> {label} = $d -> {day};
						
						$day -> {attributes} -> {id} = "day_$d->{iso}";

						&$callback ($day, $d);
											
						$s .= $_SKIN -> draw_text_cell ($day);
																	
					}
				
				}
				
				return $s;
							
			},

			$lines,
			
			$options,
			
		);


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
	$_REQUEST {__on_load}     .= "; try {if (!window.top.title_set) window.top.document.title = the_page_title;} catch(e) {}";

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
	
	$_REQUEST {__only_field} ? $_SKIN -> draw_page__only_field ($page) : $_SKIN -> draw_page ($page);

}

################################################################################

sub draw_error_page {

	my $page = $_[0];
	
	$_REQUEST {error} ||= $_[1];
		
	if ($_REQUEST {error} =~ s{^\#(\w+)\#\:}{}) {
	
		$page -> {error_field} = $1;
	
		($_REQUEST {error}) = split / at/sm, $_REQUEST {error}; 
	
	}
	else {

		Carp::cluck ($_REQUEST {error});

	}

	$_REQUEST {error} = $i18n -> {$_REQUEST {error}}
		if $_REQUEST {error};

	setup_skin ();
		
	$_REQUEST {__response_started} and $_REQUEST {error} =~ s{\n}{<br>}gsm and return $_REQUEST {error};

	return $_SKIN -> draw_error_page ($page);

}

################################################################################

sub draw_redirect_page {

	my ($page) = @_;

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

#################################################################################

sub gzip_in_memory {

	my ($html) = @_;

	my $z;
			
	my $x = new Compress::Raw::Zlib::Deflate (-Level => 9, -CRC32 => 1);
	
	$x -> deflate ($html, $z);
	
	$x -> flush ($z);
	
	"\37\213\b\0\0\0\0\0\0\377" . substr ($z, 2, (length $z) - 6) . pack ('VV', $x -> crc32, length $html);

}

#################################################################################

sub gzip_if_it_is_needed (\$) {

	my ($ref_html) = @_;
	
	my $old_size = length $$ref_html;

	$preconf -> {core_gzip} 
		
		and $r -> headers_in -> {'Accept-Encoding'} =~ /gzip/
		
		and (400 + $old_size) > ($preconf -> {core_mtu} ||= 1500)
		
		and !$_REQUEST {__is_gzipped}
			
		or return;
	
	__profile_in ('core.gzip'); 

	eval {$$ref_html = gzip_in_memory ($$ref_html)};
			
	my $new_size = length $$ref_html;

	my $ratio = int (10000 * ($old_size - $new_size) / $old_size) / 100;
			
	__profile_out ('core.gzip' => {label => sprintf ("%d -> %d, %.2f\%", $old_size, $new_size, 100 * ($old_size - $new_size) / $old_size)});

	$r -> content_encoding ('gzip');

	$_REQUEST {__is_gzipped} = 1;	

}

################################################################################

sub out_json ($) {

	out_html ({}, $_JSON -> encode ($_[0]));

}

################################################################################

sub out_script {

	my $html = '<html><head><script>';
	
	setup_json ();

	$html .= 'var data = ' . $_JSON -> encode ($_[1]) . ';' if $_[1];

	my $is_function_name = $_[0] =~ /^\w+$/;
	
	$html .= 'parent.' if $is_function_name;

	$html .= $_[0];

	$html .= '(data)' if $is_function_name;

	$html .= '</script></head></html>';

	out_html ({}, $html);

}

################################################################################

sub out_html {

	my ($options, $html) = @_;

	$html and !$_REQUEST {__response_sent} or return;

	__profile_in ('core.out_html'); 

	if ($conf -> {core_sweep_spaces}) {
		$html =~ s{^\s+}{}gsm;
		$html =~ s{[ \t]+}{ }g;
	}

	$preconf -> {core_no_morons} or $html =~ s{window\.open}{nope}gsm;

	$html = Encode::encode ('windows-1252', $html);

	return print $html if $_REQUEST {__response_started};

	$r -> content_type ($_REQUEST {__content_type} ||= 'text/html; charset=' . $i18n -> {_charset});
	
	gzip_if_it_is_needed ($html);

	$r -> headers_out -> {'Content-Length'} = my $length = length $html;

	$r -> headers_out -> {'X-Powered-By'} = 'Eludia/' . $Eludia::VERSION;
	
	$r -> headers_out -> {'P3P'} = 'CP="IDC DSP COR ADM DEVi TAIi PSA PSD IVAi IVDi CONi HIS OUR IND CNT"';
	
	send_http_header ();

	$r -> header_only && !MP2 or print $html;
	
	$_REQUEST {__response_sent} = 1;

	__profile_out ('core.out_html' => {label => "$length bytes"});

}

#################################################################################

sub setup_skin {

	my ($options) = @_;

	eval {$_REQUEST {__skin} ||= get_skin_name ()};

	unless ($_REQUEST {__skin}) {

		if ($_COOKIE {ExtJs}) {
		
			$_REQUEST {__skin} = 'ExtJs';
			
		}
		elsif ($_REQUEST {xls}) {
		
			$_REQUEST {__skin} = 'XL';
			
		}
		elsif (($_REQUEST {__dump} || $_REQUEST {__d}) && ($preconf -> {core_show_dump} || $_USER -> {peer_server})) {
		
			$_REQUEST {__skin} = 'Dumper';
			
		}
		elsif ($r -> headers_in -> {'User-Agent'} eq 'Want JSON') {
		
			$_REQUEST {__skin} = 'JSONDumper';
			
		}
		else {

			$_REQUEST {__skin} = ($preconf -> {core_skin} ||= 'Classic');

		}

	}

	our $_SKIN = "Eludia::Presentation::Skins::$_REQUEST{__skin}";
	
	my $path = $_SKIN;
	
	$path    =~ s{\:\:}{/}gsm;
	
	require $path . '.pm';
	
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

	foreach my $package ($_SKIN) {

		attach_globals ($_PACKAGE => $package, qw(
			SQL_VERSION
			_COOKIE
			_COOKIES
			_JSON
			_PACKAGE
			_QUERY
			_REQUEST
			_REQUEST_VERBATIM
			_SKIN
			_SO_VARIABLES
			_SUBSET
			_USER
			adjust_esc
			check_href
			conf
			create_url
			darn
			dump_attributes
			dump_hiddens
			dump_tag
			hotkey
			i18n
			out_html
			preconf
			r
			scan2names
			tree_sort
			trunc_string
			user_agent
		));

	}

	$_SKIN -> {options} ||= $_SKIN -> options;

	$_REQUEST {__no_navigation} ||= $_SKIN -> {options} -> {no_navigation};
	
	check_static_files ();

	$_REQUEST {__static_url} = $_REQUEST {__static_site} . $_REQUEST {__static_url} if $_REQUEST {__static_site};

	setup_json ();

}

#################################################################################

sub check_static_files {

	return if $_SKIN -> {static_ok} -> {$_NEW_PACKAGE};
	return if $_SKIN -> {options} -> {no_presentation};
	return if $_SKIN -> {options} -> {no_static};
	$r or return;
	
	__profile_in ('core.check_static_files'); 
	
	my $skin_root = $r -> document_root () . $_REQUEST {__static_url};
		
	-d $skin_root or mkdir $skin_root or die "Can't create $skin_root: $!";	
	
	if ($Eludia::VERSION =~ /^\d/ && open (V, "$skin_root/VERSION")) {
	
		my $version = <V>;
	
		close (V);
		
		if ($Eludia::VERSION eq $version) {
		
			$_SKIN -> {static_ok} -> {$_NEW_PACKAGE} = 1;

			__profile_out ('core.check_static_files' => {label => "= $version"});
			
			return;
		
		}

	}
	
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
			
			my ($from, $to) = map {"$_/$src"} ($over_root, $skin_root);
			
			$to =~ s{\.pm$}{};
						
			File::Copy::copy ($from, $to) or die "can't copy '$from' -> '$to': $!\n";
			
		}

	}
		
	if ($preconf -> {core_gzip}) {

		foreach my $fn ('navigation.js', 'eludia.css') {
		
			if (-f "$skin_root/$fn") {

				my $js = '';
				open (IN, "$skin_root/$fn");
				$js .= $_ while (<IN>);
				close IN;
	
				open (OUT, ">$skin_root/$fn.gz");
				binmode (OUT);	
				print OUT gzip_in_memory ($js);
				close OUT;

			}
		}
	}

	$_SKIN -> {static_ok} -> {$_NEW_PACKAGE} = 1;
	
	if ($Eludia::VERSION =~ /^\d/) {
	
		my $fn = "$skin_root/VERSION";
		
		open (V, ">$fn") or die "Can't write to $fn:$!\n";

		print V $Eludia::VERSION;

		close (V);
	
	}

	__profile_out ('core.check_static_files' => {label => "-> $Eludia::VERSION"});

}

#################################################################################

sub file_icon {

	my ($s) = @_;
	
	$s = $s -> {file_name} if ref $s eq HASH;
	
	$s =~ /\.docx?$/        ? (status => {icon => 'msword', label => 'MS Word'})  :
	$s =~ /\.xlsx?$/        ? (status => {icon => 'excel',  label => 'MS Excel'}) :
	$s =~ /\.vdx$/          ? (status => {icon => 'visio',  label => 'MS Visio'}) :
	$s =~ /\.pdf$/          ? (status => {icon => 'pdf',    label => 'Adode PDF'}) :
	$s =~ /\.(zip|rar|gz)$/ ? (status => {icon => 'zip',    label => 'ZIP'}) :
				  (status => {icon => 'file'});

}

1;
