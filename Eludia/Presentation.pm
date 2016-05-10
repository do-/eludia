no warnings;

################################################################################

sub css ($)    {$_REQUEST {__css} .= "\n$_[0]\n"; return ''}

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

		if ($data -> {$_} =~ s/(\d\d\d\d)-(\d\d)-(\d\d)/$3.$2.$1/ or $data -> {$_} =~ m{(\d\d)\.(\d\d)\.(\d\d\d\d)}) {

			$data -> {$_} =~ s{00\.00\.0000}{};
			$data -> {$_} =~ s{31\.12\.9999(\s00:00:00)?}{};
			$data -> {$_} =~ s{(:\d+)\.\d+$}{$1};
		}
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
	$s = encode_entities ($s, "<>��-���-��\xA0�����-��-��-��") if $has_ext_chars && $i18n -> {_charset} ne 'UTF-8';

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
				order     => $order,
			)
		:
			(
				href      => create_url ($name_order => $order, $name_desc => 0, __last_last_query_string => $_REQUEST {__last_last_query_string}),
				href_asc  => create_url ($name_order => $order, $name_desc => 0, __last_last_query_string => $_REQUEST {__last_last_query_string}),
				href_desc => create_url ($name_order => $order, $name_desc => 1, __last_last_query_string => $_REQUEST {__last_last_query_string}),
				order     => $order,
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

	my ($data, $options) = @_;

	my $title = (exists $data -> {title} ? $data -> {title} : undef)
		|| (exists $options -> {title} ? $options -> {title} : undef)
		|| '' . $data -> {label};

	$title =~ s{\<.*?\>}{}g;
	$title =~ s{^(\&nbsp\;|\s)+}{};

	$title =~ s{\"}{\&quot\;}g;

	$data -> {attributes} -> {title} = $title ;

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

	$url .= "&__salt=$_REQUEST{__salt}"
		if $h {action};

	if ($h {action} eq 'download' || $h {xls}) {
		$options -> {no_wait_cursor} = 1;
	}

	if ($options -> {dialog}) {

		$url = dialog_open (
			{
				title  => $options -> {dialog} -> {title},
				href   => $url . '#',
				after  => $options -> {dialog} -> {after} . ';setCursor (); try {top.setCursor (top)} catch (e) {}; void (0)',
				before => $options -> {dialog} -> {before},
				off    => $options -> {dialog} -> {off},
			},
			$options -> {dialog} -> {options}
		);

	}

	map { $url .= "&${_}=$_REQUEST{$_}" } grep { $_ =~ /^__select_type_/ } keys %_REQUEST if $_REQUEST {select};

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

	return '' if $options -> {off} || !$options -> {label};

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
		$options -> {esc} ||= create_url (
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

	return '' if $options -> {off} && $data || $_REQUEST {__only_table};

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

		for (my $i = 0; $i < @$row; $i++) {
			next
				unless $row -> [$i] -> {draw_hidden};

			my @right_siblings = grep {!$_ -> {off} && !$_ -> {draw_hidden}}
				($i + 1 < @$row? @$row [$i + 1 .. @$row - 1] : ());
			my @left_siblings = grep {!$_ -> {off} && !$_ -> {draw_hidden}}
				($i - 1 >= 0? @$row [0 .. $i - 1] : ());
			my $sibling = $left_siblings [0] || $right_siblings [0];

			!$sibling or $sibling -> {colspan} += 1 + ($sibling -> {label_off}? 0 : 1);
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

				$item -> {href} =~ s{\&?__last_query_string=-?\d*}{}gsm;
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
	push @keep_params, {name  => '__salt',                      value => rand () * time ()                       };
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

		push @keep_params, {name => $key, value => $_REQUEST {$key} }
			if ($_REQUEST {select} && $key =~ /^__select_type_/ || $key =~ /^__checkboxes_/);

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
		 &&  $field -> {type} ne 'color_excel'
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

		my $fields = [split (',', $_REQUEST {__only_field})];

		if ($field -> {type} eq 'hgroup') {
			my $html = '';
			foreach (@{$field -> {items}}) {$html .= draw_form_field ($_, $data)}
			return $html;
		}
		elsif ($field -> {type} eq 'radio' && !($field -> {name} ~~ $fields)) {
			my $html = '';
			foreach (@{$field -> {values}}) {$html .= draw_form_field ($_, $data)}
			return $html;
		}
		else {
			(grep {$_ eq $field -> {name}} @$fields) > 0 or return '';
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

			my @items;
			if (defined $button -> {items}) {
				@items = grep { !$_ -> {off} } @{$button -> {items}};
				next unless @items;
			}

			$button = @items [0] if (@items == 1);

			if (@items > 1) {

				map { $_ -> {parent} = 1; $_SKIN -> __adjust_button ($_); } @items;

				$button -> {items} = \@items;

				eval { $button -> {__menu} = draw_toolbar_button_vert_menu ($button -> {items}, $button -> {items}); };

			}

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

sub draw_toolbar_button_vert_menu {

	my ($name, $types, $level, $is_main) = @_;

	$level ||= 1;

	$types = [grep {!$_ -> {off}} @$types];

	my @types = ();

	foreach my $type (@$types) {

		next if $type -> {off};

		if (ref $type -> {items} eq ARRAY && !$_REQUEST {__edit}) {

			$type -> {name}     ||= '' . $type if $type -> {items};

			$type -> {vert_menu}  = draw_toolbar_button_vert_menu ($type -> {name}, $type -> {items}, $level + 1, $is_main);

		}
		else {

			$type -> {href}     ||= "/?type=$$type{name}";

			$type -> {href}      .= "&role=$$type{role}" if $type -> {role};

			check_href ($type);

			$type -> {target}   ||= "_self";

		}

		$_SKIN -> {options} -> {no_server_html} or $_SKIN -> __adjust_toolbar_btn_vert_menu_item ($type, $name, $types, $level, $is_main);

		push @types, $type;

	}

	return $_SKIN -> draw_toolbar_button_vert_menu ($name, \@types, $level);
}

################################################################################

sub draw_centered_toolbar_button {

	my ($options) = @_;

	my @items;
	if (defined $options -> {items}) {
		@items = grep { !$_ -> {off} } @{$options -> {items}};
		return '' unless @items;
	}

	$_ [0] = $options = @items [0] if (@items == 1);

	if (@items > 1) {

		map { $_ -> {parent} = 1; $_SKIN -> __adjust_button ($_); } @items;

		$options -> {items} = \@items;

		eval { $options -> {__menu} = draw_toolbar_button_vert_menu ($options -> {items}, $options -> {items}); };

	}

	$_SKIN -> __adjust_button ($options);

	return $_SKIN -> draw_centered_toolbar_button (@_);

}

################################################################################

sub draw_centered_toolbar {

	$_REQUEST {lpt} and return '';

	my ($options, $list) = @_;

	$options -> {off} and return '';

	$options -> {cnt} = 0;

	foreach my $i (@$list) {

		$i -> {off} ||= !(grep {!$_ -> {off}} @{$i -> {items}}) if (exists $i -> {items} && @{$i -> {items}} > 0);

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
			off   => (!$_REQUEST {__read_only} || !$_REQUEST {select}) || $_REQUEST {"__select_type_" . $_REQUEST {select}} ne $_REQUEST {type},
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
			href => 'javascript: window.parent.close()',
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

	return $_SKIN -> draw_menu (@_)
		if $_SKIN -> {options} -> {skip_menu_ajusting};


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
	}
	push @{$i -> {__href}}, $options -> {href};
	push @{$i -> {__target}}, $options -> {target};



	$options -> {__fixed_cols} = 0;

	my $row = $_ [0];

	if ($conf -> {core_store_table_order} && !$_REQUEST {__no_order}) {

		my ($i, $j, $k) = (0, 0, 0);

		while ($i < @_COLUMNS && $j < @$row) {

			if ($_COLUMNS [$i] -> {children}) {
				$i ++;
				next;
			}


			if ($row -> [$j] -> {hidden} || $row -> [$j] -> {icon}) {
				$j ++;
				next;
			}

			$row -> [$j] = {label => $row -> [$j]} unless ref $row -> [$j] eq HASH;

			$row -> [$j] -> {hidden} ||= $_COLUMNS [$i] -> {hidden};
			$row -> [$j] -> {ord} ||= $COLUMNS_BY_ORDER {$k};

			$i ++; $j ++; $k ++;

		}

	}

	if ($_REQUEST {select} && !$options -> {select_label}) {

		foreach my $cell (@$row) {

			next if $cell -> {no_select_href};

			$cell         -> {select_href}    and $options -> {select_label} =  $cell -> {label};

			$options      -> {select_label}   ||= ref $cell eq 'HASH' ? $cell -> {label} : $cell;

			$options      -> {select_label}   and last;

		}

	}

	my @cells = order_cells (@$row);

	if ($_REQUEST {__multi_select_checkbox} == 1) {
		unshift @cells, {
			type       => 'checkbox',
			name       => "_id_$$i{id}",
			attributes => {
				id    => $i -> {id},
				class => 'id_checkbox row-cell',
			},
			off => $i -> {no_multi_select_checkbox},
		};
	}

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

	!$options -> {__fixed_cols}
		or $cells [$options -> {__fixed_cols}] -> {__is_first_not_fixed_cell} = 1;

	my $url = create_url();

	foreach my $cell (@cells) {

		$cell -> {href} ||= $options -> {href};

		delete $cell -> {editor} if (exists $_REQUEST {__edited_cells_table} && ($i -> {fake} != 0 || $_REQUEST {xls}));

		if (exists $cell -> {editor} && $_REQUEST {__edited_cells_table}) {

			my $id_cell = $cell -> {editor} -> {name} || $cell -> {editor} -> {attributes} -> {id} || $cell -> {editor};

			next unless ($id_cell =~ /^(\w+)_(\d+)$/);

			my $name = $1;
			my $id_edit_cell = $2;
			my $id_type = $_REQUEST {id} ? "&id=$_REQUEST{id}" : "";

			$cell -> {attributes} -> {id} ||= "_div_" . $_REQUEST {__edited_cells_table} . '_' . $id_cell;

			$cell -> {editor} -> {attributes} -> {id} ||= "_editor_div_" . $_REQUEST {__edited_cells_table} . '_' . $id_cell;

			$cell -> {editor} -> {name} = '_' . $_REQUEST {__edited_cells_table} . '_' . $cell -> {editor} -> {name};

			$cell -> {editor} -> {label} ||= $cell -> {label} if $cell -> {editor} -> {type} ~~ ['input', 'date', 'datetime'];

			$cell -> {editor} -> {hidden} ||= $_REQUEST {xls};

			$cell -> {editor} -> {attributes} -> {style} .= "display:none;";

			$cell -> {editor} -> {edit} = 1;

			$cell -> {editor} = call_from_file ("Eludia/Presentation/TableCells/$cell->{editor}->{type}.pm", "draw_$cell->{editor}->{type}_cell", $cell -> {editor}, {id => $id_cell, editor => 1});

			$options -> {action} ||= $cell -> {editor} -> {action};
			$options -> {action} ||= 'add';

			$cell -> {attributes} -> {ondblclick} ||= <<EOJS;
				var url_options = '$url&__edited_cells_table=$_REQUEST{__edited_cells_table}&action=$$options{action}&type=$_REQUEST{type}&action_type=$$options{action_type}&id_edit_cell=${id_edit_cell}${id_type}&__only_table=$_REQUEST{__edited_cells_table}&__only_field=$id_cell';
				open_edit_cell ('$id_cell', '$name', url_options, '$_REQUEST{__edited_cells_table}');
EOJS
			if ($_REQUEST {__only_field} && $_REQUEST {__only_field} eq $id_cell) {
				$result = call_from_file ("Eludia/Presentation/TableCells/$cell->{type}.pm", "draw_$cell->{type}_cell", $cell, $options);
				return {id => $id_cell, html => $result};
			}

		}

		$result .= call_from_file ("Eludia/Presentation/TableCells/$cell->{type}.pm", "draw_$cell->{type}_cell", $cell, $options);

	}

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

	return @result if $_REQUEST {__no_order} || 0 == %ord;

	my $n = 1;

	for (my $i = 0; $i < @result; $i++) {

		if ($result [$i] -> {parent_header} && $result [$i] -> {parent_header} -> {ord}) {

			$result [$i] -> {ord} = $result [$i] -> {parent_header} -> {ord}

				+ $result [$i] -> {ord} / 1000 + $i / 10000;

			next;
		}

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

	if ($cell -> {order} && !defined $cell -> {href}) {

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

sub get_composite_table_headers {

	my ($options) = @_;

	my $headers = $options -> {headers};
	my $i       = $options -> {i} + 0;
	my $colspan = $options -> {colspan} || 65535;

	my $result_headers = [];

	my $cnt = @{$headers -> [$i]};
	$options -> {level_indexes} -> [$i] ||= 0;

	if ($cnt == 0 && $colspan > 0 && $colspan != 65535) {
		return {
			headers => [map {my $id = get_super_table_cell_id ({}); {label => '', id => $id, no_order => $id}} (1 .. $colspan)],
		}
	}

	for (; $options -> {level_indexes} -> [$i] < $cnt && $colspan > 0; $options -> {level_indexes} -> [$i] ++) {

		my $j = $options -> {level_indexes} -> [$i];

		push @$result_headers, $headers -> [$i] -> [$j];

		if ($headers -> [$i] -> [$j] -> {colspan}) {

			my $result = get_composite_table_headers ({
				headers       => $headers,
				level_indexes => $options -> {level_indexes},
				i             => $i + 1,
				colspan       => $headers -> [$i] -> [$j] -> {colspan},
			});

			for (my $k = 0; $k < @{$result -> {headers}}; $k++) {
				$result -> {headers} -> [$k] -> {parent_header} ||= $headers -> [$i] -> [$j];
				push @{$headers -> [$i] -> [$j] -> {children}}, $result -> {headers} -> [$k];
				$headers -> [$i] -> [$j] -> {has_child} ++;

				push @$result_headers, $result -> {headers} -> [$k];
			}

		}

		$colspan -= $headers -> [$i] -> [$j] -> {colspan} || 1
			if !$headers -> [$i] -> [$j] -> {hidden}
				|| $headers -> [$i] -> [$j] -> {parent} eq $headers -> [$i - 1] -> [$options -> {level_indexes} -> [$i - 1]] -> {id};

# Get tail children with hidden == 1
		if (
			$colspan == 0
			&& $options -> {level_indexes} -> [$i] + 1 < $cnt
			&& $headers -> [$i] -> [$options -> {level_indexes} -> [$i] + 1] -> {hidden}
			&& (
				!$headers -> [$i] -> [$options -> {level_indexes} -> [$i] + 1] -> {parent}
				||
				$headers -> [$i] -> [$options -> {level_indexes} -> [$i] + 1] -> {parent} eq $headers -> [$i - 1] -> [$options -> {level_indexes} -> [$i - 1]] -> {id}
			)
		) {

			$colspan ++;
		}


	}

	return {headers => $result_headers};

}

################################################################################

sub _adjust_table_options {

	my ($options, $list) = @_;

	$options -> {id_table} ||= $_REQUEST {type} . '_' . $options -> {name}
		if $options -> {name};

	if (ref $options -> {title} eq 'HASH' && exists $options -> {title} -> {label} && !$options -> {id_table}) {

		$options -> {id_table} = $_REQUEST {type} . '_' . $options -> {title} -> {label};

		utf8::encode ($options -> {id_table})
			if $i18n -> {_charset} eq 'UTF-8';

		$options -> {id_table} = Digest::MD5::md5_hex ($options -> {id_table});



	}

	$options -> {id_table} ||= $_REQUEST {type} . '_' . $_REQUEST {__table_ids_cnt}++;

	$options -> {super_table} ||= $_REQUEST {__skin} eq 'Mint' || $_REQUEST {__core_skin} eq 'Mint';

	if ($options -> {super_table} && !$options -> {pager}) {

		if (ref $options -> {top_toolbar} eq 'ARRAY') {
			my ($pager_button) = grep {$_ -> {type} eq 'pager'} @{ $options -> {top_toolbar} };
			$options -> {pager} -> {total}   = 0 + $pager_button -> {total} || $_REQUEST {__page_content} -> {cnt};
			$options -> {pager} -> {cnt}     = 0 + $pager_button -> {cnt};
			$options -> {pager} -> {portion} = 0 + $pager_button -> {portion} || $_REQUEST {__page_content} -> {portion} || $conf -> {portion};;
		}

		$options -> {pager} -> {cnt} ||= @$list;
		$options -> {pager} -> {total} ||= @$list;
	}
}

################################################################################

sub _load_super_table_dimensions {

	my ($options, $headers, $list) = @_;

	if ($options -> {no_resize}) {
		return;
	}
	my $column_dimensions = $_QUERY -> {content} -> {columns};

	my $max_fixed_cols_cnt = 0;

	ref $headers -> [0] eq ARRAY or $headers = [$headers];
# Duplicate header to fix programmer's bug: use same hash to describe multiple header cells
	my $header_copy = [];

	for (my $i = 0; $i < @$headers; $i ++) {

		my $row = $headers -> [$i];
		my $fixed_cols_cnt = 0;

		for (my $j = 0; $j < @$row; $j ++) {

			ref $row -> [$j] eq HASH or $row -> [$j] = {label => $row -> [$j]};
			my $cell = {%{$row -> [$j]}};

			push @{$header_copy -> [$i]}, $cell
				unless $cell -> {hidden} && !$_REQUEST {__edit_query};

			$fixed_cols_cnt ++ if $cell -> {no_scroll};

			$cell -> {id} ||= get_super_table_cell_id ($cell);
			$cell -> {order}
				or $cell -> {no_order} && $cell -> {no_order} != 1
				or $cell -> {no_order} = $cell -> {id};

			my $cell_dimensions = $column_dimensions -> {$cell -> {id}};
			$cell_dimensions or next;

			$cell -> {width} = $cell_dimensions -> {width};
			$cell -> {height} = $cell_dimensions -> {height};
			$cell -> {sort}   = $cell -> {order} && (
				$_REQUEST {order} eq $cell -> {order}
				|| !$_REQUEST {order} && $column_dimensions -> {$cell -> {id}} -> {sort}
			);
			if ($cell -> {sort} && $_REQUEST {order} eq $cell -> {order}) {
				$cell -> {$_REQUEST {desc} ? 'desc' : 'asc'} = 1;
			} elsif ($cell -> {sort}) {
				$cell -> {$column_dimensions -> {$cell -> {id}} -> {desc} ? 'desc' : 'asc'} = 1;
			}

		}

		$fixed_cols_cnt <= $max_fixed_cols_cnt or $max_fixed_cols_cnt = $fixed_cols_cnt;
	}

	@{$headers} = @{$header_copy};

	$options -> {__fixed_cols} ||= $max_fixed_cols_cnt;
}

####################################################################

sub get_super_table_cell_id {

	my ($cell) = @_;

	if ($cell -> {order} || $cell -> {no_order}) {
		return $cell -> {order} || $cell -> {no_order};
	}

	$_REQUEST {__generated_cell_ids} ||= {};
	my $id = Digest::MD5::md5_hex ($i18n -> {_charset} eq 'UTF-8' ? Encode::encode ('utf-8', $cell -> {label}) : $cell -> {label});

	while ($_REQUEST {__generated_cell_ids} -> {$id}) {
		$id .= '0';
	}

	$_REQUEST {__generated_cell_ids} -> {$id} = 1;

	return $id;
}

################################################################################

sub _adjust_super_table_headers {

	my ($options, $cells) = @_;

	return
		unless $options -> {__fixed_cols};

	my $row_idx = 0;

	foreach my $h (@$cells) {

		my $row = $h;

		ref $row eq ARRAY or $row = [$row];

		my $first_not_fixed_idx = $row_idx? 0 : $options -> {__fixed_cols};

		$row -> [$first_not_fixed_idx] -> {__is_first_not_fixed_cell} = 1;

		$row_idx++;
	}
}

################################################################################

sub set_body_table_cells_ord {

	my ($header_row) = @_;

	my $sorted_header_row = [sort {$a -> {ord} <=> $b -> {ord}} @$header_row];

	foreach my $cell (@$sorted_header_row) {

		$cell -> {hidden} and next;

		if ($cell -> {children}) {
			set_body_table_cells_ord ([grep {$_ -> {parent_header} eq $cell} @{$cell -> {children}}]);
		} else {
			$COLUMNS_BY_ORDER {$cell -> {ord_source_code}} ||= $showing_ord ++;
		}
	}

}

################################################################################

sub draw_table {

	return '' if $_REQUEST {__only_form};

	my $headers = [];

	unless (ref $_[0] eq CODE or (ref $_[0] eq ARRAY and ref $_[0] -> [0] eq CODE)) {
		$headers = shift;
		ref $headers -> [0] eq ARRAY or ($headers = [$headers]);
	}

	my ($tr_callback, $list, $options) = @_;

	_adjust_table_options ($options, $list);

	!exists $_REQUEST {__only_table}
		or $_REQUEST {__only_table} eq $options -> {id_table}
		or $_REQUEST {__only_field} && $_REQUEST {__only_table} eq $options -> {name}
		or return '';

	my $table_label = exists $options -> {title} && $options -> {title} ?
		$options -> {title} -> {label} : $options -> {name};

	__profile_in ('draw.table' => {label => $table_label});

	if ($options -> {off}) {

		__profile_out ('draw.table' => {label => "[OFF] $table_label"});

		return '';

	}

	_load_super_table_dimensions ($options, $headers, $list);

	_adjust_super_table_headers ($options, $headers);

	$options -> {headers} = $headers;

	my $is_table_columns_order_editable = $_SKIN -> {options} -> {table_columns_order_editable};
	my $is_table_columns_showing_editable = $options -> {custom__edit_query} || $_REQUEST {first_table_columns_showing_editable};

	foreach my $top_toolbar_field (@{$options -> {top_toolbar}}) {

		$_REQUEST {first_table_columns_showing_editable} = 1
			if ($is_table_columns_showing_editable && $_REQUEST {multi_select});
		last
			if $is_table_columns_showing_editable;

		$is_table_columns_showing_editable ||= ref $top_toolbar_field eq HASH
			&& exists $top_toolbar_field -> {href}
			&& (
				ref $top_toolbar_field -> {href} eq HASH && $top_toolbar_field -> {href} -> {__edit_query} == 1
				|| $top_toolbar_field -> {href} =~ /\b__edit_query\b/
			);

	}

	$options -> {is_not_first_table_on_page} = $_REQUEST {is_not_first_table_on_page};

	if (@_COLUMNS && !$_REQUEST {multi_select}) {
		$options -> {is_not_first_table_on_page} = 1;
		delete $_REQUEST {id___query};
		$_QUERY = undef;
		$_REQUEST {__allow_check___query} = 1;
		check___query ($options -> {id_table});
		$_REQUEST {__allow_check___query} = 0;
	}

	$options -> {no_order} = !($is_table_columns_order_editable || $is_table_columns_showing_editable)
		unless exists $options -> {no_order};

# Check broken $_QUERY -> {content} -> {columns} because of application code modification. If !$is_table_columns_showing_editable all columns should have ord
	if ($is_table_columns_order_editable && !$is_table_columns_showing_editable) {
		foreach my $column (keys %{$_QUERY -> {content} -> {columns}}) {
			if (!$_QUERY -> {content} -> {columns} -> {$column} -> {ord}) {
				$options -> {no_order} = 1;
				delete $_REQUEST {id___query};
				$_QUERY = undef;
				last;
			}
		}
	}

	if ($options -> {no_order}) {
		$_REQUEST {__no_order} = 1;
	} else {
		delete $_REQUEST {__no_order};
	}

	our @_COLUMNS = ();
	our %_ORDER = ();

	my $flat_headers = (get_composite_table_headers ({headers => $headers})) -> {headers};
	my $ord_source_code = 0;

	@_COLUMNS = @$flat_headers;

	my $is_exist_default_ords = 0 + grep {$_ -> {ord} || $_ -> {ord_fixed}} @$flat_headers;

	foreach my $h (@$flat_headers) {

		$h -> {ord_source_code} ||= $ord_source_code ++
			unless $h -> {children};

		if (
			$conf -> {core_store_table_order} && !$options -> {no_order} && ($is_exist_default_ords || $_REQUEST {id___query})
		) {

			my $column_order = $_REQUEST {id___query} ? $_QUERY -> {content} -> {columns} -> {$h -> {order} || $h -> {no_order}} : undef;

			if ($h -> {ord_fixed}) {

				$h -> {ord} = $h -> {ord_fixed};

			} elsif (!defined ($column_order) || !defined ($column_order -> {ord})) {

				if ($_REQUEST {id___query} && $h -> {parent_header}) {

					my $max_ord;

					foreach (@{$h -> {parent_header} -> {children}}) {
						$max_ord = $_ -> {ord}
							if $_ -> {ord} > $max_ord;
					}

					$h -> {ord} = $max_ord || 0 if ( !defined $h -> {ord} );
					my $p = $h -> {parent_header};

					if ($max_ord == 0 && $p -> {label}) {
						$p -> {hidden} = 1;
					}

				} elsif ($_REQUEST {id___query}) {
# The column did not exist before (may be it was hidden (8086))
					$h -> {ord} = $h -> {ord_source_code} if ( !defined $h -> {ord} );
				}

			} elsif ($column_order -> {ord} == 0) {

				$h -> {ord} = 0;
				my $p = $h -> {parent_header};

				while ($p -> {label}) {
					$p -> {colspan} --;
					$p -> {hidden} = 1 if $p -> {colspan} == 0;
					$p = $p -> {parent_header};
				}

			} else {

				$h -> {ord} = $column_order -> {ord};

			}
# Save original hidden value for draw_item_of___queries
			$h -> {__hidden} = $h -> {hidden};

			$h -> {hidden}   = 1
				if $is_table_columns_showing_editable && (
					$h -> {ord} == 0
					|| defined $h -> {parent_header} && defined $h -> {parent_header} -> {ord} && $h -> {parent_header} -> {ord} == 0
				);
		}

		$h -> {filters} = [];

		$_ORDER {$h -> {order} || $h -> {no_order}} = $h
			if $h -> {order} || $h -> {no_order};

	}

	local %COLUMNS_BY_ORDER = ();
	local $showing_ord = 1;

	set_body_table_cells_ord ($headers -> [0])
		if $conf -> {core_store_table_order} && !$options -> {no_order} && ($is_exist_default_ords || $_REQUEST {id___query});

	$options -> {type}   ||= $_REQUEST{type};

	$options -> {action} ||= 'add';
	$options -> {name}   ||= 'form';
	$options -> {target} ||= 'invisible';

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

	if ($_REQUEST {multi_select}
		&& ($preconf -> {core_multi_select_checkbox} || $options -> {multi_select_checkbox})
		&& !$options -> {no_multi_select_checkbox}
		&& !$_REQUEST {__multi_select_checkbox}
	) {
		# � ������ �������������� ������ ��������� ������ �������
		my $toolbar_options = shift @{$options -> {top_toolbar}};
		unshift @{$options -> {top_toolbar}}, {
			icon    => 'choose',
			label   => $i18n -> {Select},
			href    => "javascript: set_choose_ids()",
		};
		unshift @{$options -> {top_toolbar}}, $toolbar_options;

		my $href = {href => {ids => undef, add_id => undef}};
		check_href ($href);
		$_REQUEST {ids} ||= '-1';

		$_REQUEST {__script} .= <<EOS;
var href = "$href->{href}";
var ids = '$_REQUEST{ids}';
EOS

		$_REQUEST {__script} .= <<'EOJS';
function set_choose_ids () {
	var add_id = '';
	$(".id_checkbox").children().each(function() {
		if ($(this).is(":checked")) {
			if (add_id != '') add_id = add_id + ',';
			add_id = add_id + $(this).parent().attr("id");
		}
	});
	setCursor();
	if (add_id == '') return;
	nope (href + '&ids=' + ids + ',' + add_id + '&add_id=' + add_id, '_self');
}
EOJS

	}

	if (ref $options -> {top_toolbar} eq ARRAY) {

		$options -> {top_toolbar} -> [0] -> {_list} = $list;
		$options -> {top_toolbar} = draw_toolbar (@{ $options -> {top_toolbar} });
	}

	fix___query ($options -> {is_not_first_table_on_page} && !$_REQUEST {multi_select} ? $options -> {id_table} : ());

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
			colspan => 0 + @$flat_headers,
		});

		$scrollable_row_id ++;

		$_REQUEST {__uri_root} = $_REQUEST {__uri_root_common};

		hotkey ({code => Esc, data => 'dotdot'});

	}

	if ($_REQUEST {multi_select}
		&& ($preconf -> {core_multi_select_checkbox} || $options -> {multi_select_checkbox})
		&& !$options -> {no_multi_select_checkbox}
		&& !$_REQUEST {__multi_select_checkbox}
	) {
		# � ������ �������������� ������ ��������� ������ �������� ��������

		my $headers_rowspan = @$headers > 0 ? ref $headers -> [0] eq ARRAY ? @$headers + 0 : 1 : 0;

		if ($headers_rowspan > 0) {

			unshift @{ref $headers -> [0] eq ARRAY ? $headers -> [0] : $headers}, {
				label      => '<input type="checkbox" id="check_all" class="row-cell">',
				attributes => {width => '1%'},
				rowspan    => $headers_rowspan,
				ord        => -10,
			};

			$_REQUEST {__on_load} .= <<'EOJS';
				$(document).on("click", "#check_all", function() {
					$(".id_checkbox").children().prop("checked", $(this).is(":checked"));
				});
EOJS
		}

		$_REQUEST {__multi_select_checkbox} = 1;

	}

	$options -> {header}   = draw_table_header ($headers) if @$headers > 0 && $_REQUEST {xls};

	$_REQUEST {__get_ids} = {};

	$_SKIN -> start_table ($options) if $_SKIN -> {options} -> {no_buffering};

	my $n = 0;

	local $i;

	delete $_REQUEST {__edited_cells_table} if exists $_REQUEST {__edited_cells_table};
	$_REQUEST{__edited_cells_table} = $options -> {name} if ($options -> {edited_cells} == 1);

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

			local $_REQUEST {_edit_row_id} = $i -> {id} if ($options -> {edited_cells} == 1);

			my $tr = &$callback ();

			$tr or next;

			return $tr -> {html}
				if ($_REQUEST {__only_field} && $tr -> {id} eq $_REQUEST {__only_field});

			if ($_SKIN -> {options} -> {no_buffering}) {

				$_SKIN -> draw_table_row ($tr);

			}
			else {

				push @{$i -> {__trs}}, $tr;

			}

			$scrollable_row_id ++;

		}

		if (@{$i -> {__types}} > 0) {

			if (exists ($i -> {__menu}) && ref ($i -> {__menu}) eq '') {

				$i -> {__menu} .= draw_vert_menu ($i, $i -> {__types});

			} else {

				$i -> {__menu} = draw_vert_menu ($i, $i -> {__types});

			}


		}

	}

	if ($_REQUEST {multi_select}) {
		$_REQUEST {__multi_select_checkbox} = 2;
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

		$button -> {href} .= '&__tree=1' if (!$button -> {no_tree} && $button -> {href} !~ /^javascript:/i);
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

	$_REQUEST {"__select_type_" . $_REQUEST {select}} = $_REQUEST {type}
		if ($_REQUEST {select} && !$_REQUEST {"__select_type_" . $_REQUEST {select}} && $_REQUEST {id});

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

	push @{$_REQUEST {__invisibles}}, 'invisible';

	eval {
		$_SKIN -> {subset}       = $preconf -> {hide_subsets} ? undef : $_SUBSET;
		$_SKIN -> start_page ($page) if $_SKIN -> {options} -> {no_buffering};
		$page  -> {auth_toolbar} = draw_auth_toolbar ();
		$page  -> {body}         = call_for_role (($_REQUEST {id} ? 'draw_item_of_' : 'draw_') . $page -> {type}, $page -> {content}) unless $_REQUEST {__only_menu} || !$_REQUEST_VERBATIM {type} && !$_REQUEST_VERBATIM {__subset};
		$page  -> {menu_data}    = Storable::dclone ($page -> {menu});
		$page  -> {menu}         = draw_menu ($page -> {menu}, $page -> {highlighted_type}, {lpt => $lpt});
	};

	if ($@) {

		$_REQUEST {error} ||= $@;

		return draw_error_page ($page, $@);
	}

	$_REQUEST {__only_field} ? $_SKIN -> draw_page__only_field ($page) : $_SKIN -> draw_page ($page);

}

################################################################################

sub draw_error_page {

	my ($page, $error) = @_;

	ref $error or $error = investigate_error ({error => $error});

	$error -> {label} = $i18n -> {$error -> {label}}
		if $error -> {label};

	if ($_REQUEST {__lrt_time}) {
		lrt_finish ($error -> {msg}, create_url (action => undef));
		return '';
	}

	$_REQUEST {error} ||= $error -> {label};

	$page -> {error_field} = $error -> {field};

	setup_skin ();

	$_REQUEST {__response_started} and $_REQUEST {error} =~ s{\n}{<br>}gsm and return $_REQUEST {error};

	if ($error -> {kind}) {

		return $_SKIN -> draw_fatal_error_page ($page, $error);
	}

	return $_SKIN -> draw_error_page ($page, $error);

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

	$arg ||= {};

	check_href ($arg);

	$arg -> {height} ||= $options -> {height} || delete $options -> {dialogHeight};
	$arg -> {width}  ||= $options -> {width}  || delete $options -> {dialogWidth};

	delete $arg -> {height} unless $arg -> {height};
	delete $arg -> {width}  unless $arg -> {width};

	$arg -> {title} ||= $i18n -> {voc_title};

	foreach (qw(status resizable help)) {$options -> {$_} ||= 'no'}

	$arg -> {options} = join ';', map {"$_:$options->{$_}"} keys %$options;

	$_REQUEST {__script} .= 'var results; window.dialogs = window.dialogs || {};'
		unless $_REQUEST {__script} =~ /var results/;

	my ($before, $after, $off) = (delete $arg -> {before}, delete $arg -> {after}, delete $arg -> {off});

	$_REQUEST {__script} .= <<EOJS;
dialogs[$options->{id}] = @{[ $_JSON -> encode ($arg) ]};
EOJS

	if ($before) {
		$before = "function() {$before}"
			unless ($before =~ /^\s+function\b/);
		$_REQUEST {__script} .= "\ndialogs[$options->{id}].before = $before;"
	}

	if ($after) {
		$after = "function(result) {$after}"
			unless ($after =~ /^\s+function\b/);
		$_REQUEST {__script} .= "\ndialogs[$options->{id}].after = $after;"
	}

	if ($off) {
		$off = "function() {$off}"
			unless ($off =~ /^\s+function\b/);
		$_REQUEST {__script} .= "\ndialogs[$options->{id}].off = $off;"
	}

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

	$_REQUEST {__content_type} ||= 'application/json; charset=' . $i18n -> {_charset};

	setup_json ();

	my $data = $_[0];
	$data = $_JSON -> encode ($data) if ref ($data);

	out_html ({}, $data);
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

	if ($i18n -> {_charset} eq 'UTF-8') {
		utf8::encode ($html);
	} else {
		$html = Encode::encode ('windows-1252', $html);
	}

	return print $html if $_REQUEST {__response_started};

	my $charset = $_REQUEST {__charset} || $i18n -> {_charset};

	$r -> content_type ($_REQUEST {__content_type} ||= 'text/html; charset=' . $charset);

	gzip_if_it_is_needed ($html);

	$r -> headers_out -> {'Content-Length'} = my $length = length $html;

	$r -> headers_out -> {'X-Powered-By'} = 'Eludia/' . $Eludia::VERSION;

	$r -> headers_out -> {'P3P'} = 'CP="IDC DSP COR ADM DEVi TAIi PSA PSD IVAi IVDi CONi HIS OUR IND CNT"';

	if ($preconf -> {core_cors}) {
		$r -> headers_out -> {'Access-Control-Allow-Origin'} = $preconf -> {core_cors};
		$r -> headers_out -> {'Access-Control-Allow-Credentials'} = 'true';
		$r -> headers_out -> {'Access-Control-Allow-Headers'} = 'Origin, X-Requested-With, Content-Type, Accept, Cookie';
	}

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
		elsif (($_REQUEST {__dump} || $_REQUEST {__d}) && ($preconf -> {core_show_dump} || $_USER -> {peer_server})) {

			$_REQUEST {__skin} = 'Dumper';

		} else {

			$_REQUEST {__skin} = ($preconf -> {core_skin} ||= 'Classic');

		}

	}

	if ($_REQUEST {xls}) {

		$_REQUEST {__core_skin} ||= $_REQUEST {__skin};

		$_REQUEST {__skin} = 'XL';

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
			out_json
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

################################################################################

sub draw_chart {

	my ($options, $data) = @_;

	__profile_in ('draw.chart');

	return '' if $options -> {off};

	$_REQUEST {__charts_count} ||= 0;
	$_REQUEST {__charts_count} ++;

	$options -> {name} ||= 'chart' . sprintf('%05d', $_REQUEST {__charts_count});

	push @{$_REQUEST {__charts_names}}, $options -> {name};

	$_REQUEST {"is_chart_$$options{name}"} ||= $options -> {no_params} && $options -> {no_grid};

	my $href = create_url ("is_chart_$$options{name}" => undef, "is_grid_$$options{name}" => undef);

	my $html = $options -> {no_params} && $options -> {no_grid} ? "" : draw_form (
		{
			no_esc  => 1,
			no_ok   => 1,
			no_edit => 1,
			name    => 'form_menu_' . $options -> {name},
			menu    => [
				{
					href      => "$href&is_chart_$$options{name}=1",
					label     => '������',
					is_active => $_REQUEST {"is_chart_$$options{name}"} || $options -> {no_params} && !$_REQUEST {"is_grid_$$options{name}"},
					off       => $options -> {no_chart} && !$options -> {no_grid} && !$options -> {no_params},
				},
				{
					href      => "$href&is_grid_$$options{name}=1",
					label     => '������',
					is_active => $_REQUEST {"is_grid_$$options{name}"},
					off       => $options -> {no_grid} || (ref $options -> {grid} eq HASH && @{$options -> {grid} -> {columns}} == 0),
				},
				{
					href      => $href,
					label     => '���������',
					is_active => !$_REQUEST {"is_chart_$$options{name}"} && !$_REQUEST {"is_grid_$$options{name}"},
					off       => $options -> {no_params}
				},
			],
		},
		{},
		[]
	);

	if ($_REQUEST {"is_chart_$$options{name}"} || $options -> {no_params} && !$_REQUEST {"is_grid_$$options{name}"}) { # ������

		my $top_toolbar = draw_toolbar (@{$options -> {top_toolbar}}) if (ref $options -> {top_toolbar} eq ARRAY);
		my $title = draw_window_title ($options -> {title}) if (ref $options -> {title} eq HASH && $options -> {title} -> {label});

		$html .= "$title$top_toolbar";

		$html .= $_SKIN -> draw_chart ($options, $data);

	} elsif ($_REQUEST {"is_grid_$$options{name}"}) { # ������

		if (ref $options -> {grid} eq HASH) {
			$html .= draw_table (

				[
					@{$options -> {grid} -> {columns}}
				],

				sub {

					draw_cells ({},[
						map {{
							label   => $i -> {$_ -> {field}},
							picture => $_ -> {picture},
							off     => $_ -> {off} || $_ -> {picture} && $i -> {$_ -> {field}} == 0,
							hidden  => $_ -> {hidden},
							href    => ($_ -> {href} || $i -> {$_ -> {field} . '_href'}) ? _new_window_href ($_ -> {href} || $i -> {$_ -> {field} . '_href'}) : undef,
							(map { ($_ => $i -> {$_}) } @{$_ -> {fields}} ),
						}} @{$options -> {grid} -> {columns}},
					])

				},

				$data,

				{
					name  => 't_' . $options -> {name},
					title => {label => $options -> {title} -> {label}},
					top_toolbar => $options -> {top_toolbar},
				}

			);
		} else {
			$html .= $options -> {grid};
		}

	} else { # ���������

		if ($options -> {params}) {
			if (ref $options -> {params} eq ARRAY) {
				$html .= draw_form (@{$options -> {params}});
			} else {
				$html .= $options -> {params};
			}

		}

	}

	__profile_out ('draw.chart');

	return $html;

}

################################################################################

sub draw_print_chart_images {

	my ($options) = @_;

	__profile_in ('draw.print_chart_images');

	return '' if $options -> {off};

	my   @keep_params = map {{name => $_, value => $_REQUEST {$_}}} @{$options -> {keep_params}};
	push @keep_params, {name  => 'sid',                         value => $_REQUEST {sid}                         };
	push @keep_params, {name  => 'select',                      value => $_REQUEST {select}                      };
	push @keep_params, {name  => '__no_navigation',             value => $_REQUEST {__no_navigation}             };
	push @keep_params, {name  => '__tree',                      value => $_REQUEST {__tree}                      };
	push @keep_params, {name  => 'type',                        value => $options -> {type} || $_REQUEST {type}  };
	push @keep_params, {name  => 'id',                          value => $options -> {id} || $_REQUEST {id}      };
	push @keep_params, {name  => 'action',                      value => $options -> {action} || 'print'         };
	push @keep_params, {name  => '__last_query_string',         value => $_REQUEST {__last_last_query_string}    };
	push @keep_params, {name  => '__form_checkboxes',           value => $_REQUEST {__form_checkboxes}           } if $_REQUEST {__form_checkboxes};
	push @keep_params, {name  => '__last_scrollable_table_row', value => $_REQUEST {__last_scrollable_table_row} } unless ($_REQUEST {__windows_ce});

	foreach my $key (keys %_REQUEST) {

		$key =~ /^__checkboxes_/ or next;

		push @keep_params, {name => $key, value => $_REQUEST {$key} };

	}

	$options -> {keep_params} = \@keep_params;

	my $html .= $_SKIN -> draw_print_chart_images ($options);

	__profile_out ('draw.print_chart_images');

	return $html;

}

################################################################################

sub get_chart_image_pathes {

	my ($data) = @_;

	my $chart_image_pathes;

	my $chart_image_path = 'i/report_charts_images/';

	-d $preconf -> {_} -> {docroot} . $chart_image_path or mkdir $preconf -> {_} -> {docroot} . $chart_image_path;

	my @chart_keys;

	foreach my $key (keys %_REQUEST, keys %$data) {
		next unless ($key =~ /^svg_text_(\w+)$/);

		push @chart_keys, $1;
	}

	@chart_keys or return [];

	my $chart_names = [sort {$a cmp $b} @chart_keys];

	my $rsvg;

	if ($i18n -> {_charset} eq 'windows-1251') {
		eval { require Image::LibRSVG; };
		if ($@) {
			warn $@;
			return [];
		}

		$rsvg = new Image::LibRSVG ();
	}

	foreach my $name (@$chart_names) {

		$data -> {"chart_image_path_$name"} = '';

		my $key = "svg_text_$name";
		my $svg_text = $_REQUEST {$key} || $data -> {$key};

		next unless $svg_text;

		push @{$data -> {charts_names}}, $name;

		my $chart_path_relative = $chart_image_path . "$name.svg";

		my $chart_path = $preconf -> {_} -> {docroot} . $chart_path_relative;

		open CHART_IMAGE, '>' . $chart_path
			or die "Couldn't open file '$chart_path': $!";;
		binmode (CHART_IMAGE, ":utf-8");

		$svg_text =~ s/&lt;/</g;
		$svg_text =~ s/&gt;/>/g;
		$svg_text =~ s/&quot;/'/g;
		$svg_text =~ s|<span|<tspan|g;
		$svg_text =~ s|/span>|/tspan>|g;
		$svg_text =~ s|<tspan><tspan|<tspan|g;
		$svg_text =~ s|</tspan></tspan>|</tspan>|g;

		# name cannot be uuid (xml id attribute value must be xml name - can't start width digit)
		$svg_text =~ s| id='[\w-]+'||g;

		$svg_text =~ /^.*width='(\d+)px'.*$/;
		my $width = $1;
		$svg_text =~ /^.*height='(\d+)px'.*$/;
		my $height = $1;

		$data -> {"chart_image_width_$name"} = sprintf ("%.0f", $width / 1.65);
		$data -> {"chart_image_heigth_$name"} = sprintf ("%.0f", $height / 1.65);

		$svg_text = Encode::decode('cp-1251', $svg_text) if $i18n -> {_charset} eq 'windows-1251';
		print CHART_IMAGE $svg_text;

		close CHART_IMAGE;

		if ($i18n -> {_charset} eq 'windows-1251') {

			my $chart_path_png = $chart_path;

			$chart_path_png =~ s/\.svg$/\.png/;

			$rsvg -> convert ($chart_path, $chart_path_png);
			if (! -f $chart_path_png){
				warn "rsvg convert $chart_path FAILED";
				next;
			}

			$chart_path = $chart_path_png;

			$chart_path_relative =~ s/\.svg$/\.png/;
		}

		if (!$data -> {"chart_image_width_$name"} || !$data -> {"chart_image_heigth_$name"}) {
			require Image::Size;
			my ($w, $h, $id) = Image::Size::imgsize ($chart_path);
			$data -> {"chart_image_width_$name"} = 0 + $w;
			$data -> {"chart_image_heigth_$name"} = 0 + $h;
		}

		my $host = $preconf -> {reporting_api} -> {server_name}
			|| $ENV {HTTP_HOST}
			|| $preconf -> {mail} -> {server_name};

		$data -> {"chart_image_path_$name"} = "http://" . $host . "/" . $chart_path_relative if -f $chart_path;

		push @$chart_image_pathes, $chart_path;
	}

	return $chart_image_pathes;
}

1;
