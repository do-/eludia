no warnings;

################################################################################

sub js_escape {
	my ($s) = @_;
	$s =~ s/\"/\'/gsm; #"
	$s =~ s{[\n\r]+}{ }gsm;
	$s =~ s{\\}{\\\\}g; #'
	$s =~ s{\'}{\\\'}g; #'
	return "'$s'";
}

################################################################################

sub draw_gantt_bars {}

################################################################################

sub __submit_href {

	my ($_SKIN, $name, $options) = @_;

	my $js = "javaScript:var f = document.$name;";

	map {$js .= "f.elements['$_'].value='$$options{$_}';" } (keys %$options);

	$js .= "\$(f).submit(); void(0);";

	return $js;
}

################################################################################

sub __adjust_form_field {

	my ($options) = @_;

	my $attributes = ($options -> {attributes} ||= {});

	$attributes -> {class}    ||= $options -> {mandatory} ? 'form-mandatory-inputs' : 'form-active-inputs';

	$attributes -> {tabindex}   = ++ $_REQUEST {__tabindex};

}

################################################################################

sub __adjust_form_field_string {

	my ($options) = @_;

	$options -> {value} =~ s{\"}{\&quot;}gsm;

	my $attributes = ($options -> {attributes} ||= {});

	$attributes -> {value}        ||= \$options -> {value};

	$attributes -> {name}         ||= '_' . $options -> {name};

	$attributes -> {size}         ||= ($options -> {size} ||= 120);

	$attributes -> {maxlength}    ||= $options -> {max_len} || $options -> {size} || 255;

	$attributes -> {autocomplete} ||= 'off' unless exists $attributes -> {autocomplete};

	$attributes -> {id}           ||= 'input_' . $options -> {name};

	if ($options -> {disabled}) {
		$attributes -> {readonly} = 'readonly';
		$attributes -> {class} .= ' disabled';
	}
}

################################################################################

sub __adjust_form_field_date {

	__adjust_form_field_string (@_);

}

################################################################################

sub __adjust_form_field_datetime {

	__adjust_form_field_string (@_);

}

################################################################################

sub __adjust_form_field_suggest {

	my ($_SKIN, $options) = @_;

	__adjust_form_field_string (@_);

}

################################################################################

sub __adjust_form_field_hidden {

	my ($options) = @_;

	$options -> {value} =~ s/\"/\&quot\;/gsm; #";

}

################################################################################

sub __adjust_form_field_select {

	my ($options) = @_;

	if ($options -> {rows}) {

		$options -> {attributes} -> {multiple} = 1;

		$options -> {attributes} -> {size} = $options -> {rows};

	}

	foreach my $value (@{$options -> {values}}) {

		$value -> {label} = trunc_string ($value -> {label}, $options -> {max_len});

		$value -> {id}    =~ s{\"}{\&quot;}g; #";

	}

	if (defined $options -> {detail}) {

		my $js_detail = js_detail ($options);

		$options -> {onChange} .= ";var v = this.options[this.selectedIndex].value; if (v && v != -1){$js_detail}";

	}

	return undef;

}

################################################################################

sub __adjust_form_field_text {

	my ($options) = @_;

	$options -> {value} =~ s/\"/\&quot\;/gsm; #";

	my $attributes = ($options -> {attributes} ||= {});

	$attributes -> {readonly} = 1 if $_REQUEST {__read_only} or $options -> {read_only};

}

################################################################################

sub js_detail {

	my ($options) = @_;

	ref $options -> {detail} eq ARRAY or $options -> {detail} = [$options -> {detail}];

	$options -> {master} ||= [];

	ref $options -> {master} eq ARRAY or $options -> {master} = [$options -> {master}];

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
			element = window.form.elements['_${detail}'];
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

	$options -> {value_src} ||= "(this.type == 'checkbox' ? this.checked ? 1 : 0 : this.value)";

	my $onchange = $_REQUEST {__windows_ce} ? "loadSlaveDiv ('$$h{href}&__only_form=this.form.name&_$$options{name}=this.value&__only_field=" . (join ',', @all_details) : <<EOJS;
		activate_link (

			'$script_name/$href&__only_field=${\(join (',', @all_details))}&__only_form=' +
			window.form.name +
			'&_$$options{name}=' +
			$options->{value_src} +
			'&__src_field=' +
			'$$options{name}' +
			codetails_url +
			tab

			, 'invisible_$$options{name}'

			, 1

		);
EOJS

	push @{$_REQUEST{__invisibles}}, 'invisible_' . $options -> {name};

	my $codetails = $_JSON -> encode ([@all_codetails, @{$options -> {master}}]);
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

			var el = document.getElementsByName('_' + codetails[i]);
			if (el.length > 1) {

				for (j=0; j < el.length; j ++) {

					r = el [j];

					if (r.checked) {
						codetails_url += '&' + '_' + codetails[i] + '=' + r.value;
						break;
					}
				}
				continue;
			}

			if (el.length == 1) {
				var value = el[0].type == 'checkbox' ? el[0].checked ? 1 : 0 : el[0].value;
				codetails_url += '&' + '_' + codetails[i] + '=' + value;
				continue;
			}

		}

		$onchange

EOJS

}

################################################################################

sub __adjust_button {

	my ($_SKIN, $options) = @_;

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

	$options -> {id}     ||= '' . $options;
	$options -> {target} ||= '_self';

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

	$options -> {confirm} = js_escape ($options -> {confirm}) if ($options -> {confirm});
}

################################################################################

sub __adjust_button_href {

	my ($_SKIN, $options) = @_;

	my $js_restore_cursor = "document.body.style.cursor = 'default';";

	my $cursor_state = $options -> {no_wait_cursor} ? ";window.document.body.onbeforeunload=function(){$js_restore_cursor};" : '';

	if ($options -> {confirm}) {

		my $js_action;

		if ($options -> {href} =~ /^javaScript\:/i) {

			$js_action = $'

		}
		else {

			$options -> {target} ||= '_self';

			$options -> {href} =~ s{\%}{\%25}g unless $options -> {parent};

			$js_action = "nope('$options->{href}','$options->{target}')";

		}

		my $condition = 'confirm(' . js_escape ($options -> {confirm}) . ')';

		if ($options -> {preconfirm}) {

			$condition = "!$options->{preconfirm}||($options->{preconfirm}&&$condition)";

		}

		$options -> {href} = qq {javascript:if($condition){$cursor_state$js_action}else{${js_restore_cursor}nop()}};

	}
	elsif ($options -> {no_wait_cursor}) {

		$options -> {onclick} = qq {onclick="$cursor_state void(0);"};

	}

	if ($options -> {href} =~ /^javaScript\:/i) {

		delete $options -> {target};

	}

	$_SKIN -> __adjust_button_blockui ($options);

	$options -> {id} ||= '' . $options;
	$options -> {tabindex} = ++ $_REQUEST {__tabindex};;

	if ((my $h = $options -> {hotkey}) && !$options -> {off}) {

		$h -> {data} = $options -> {id};

		hotkey ($h);

	}

}

################################################################################

sub __adjust_button_blockui {

	my ($_SKIN, $options) = @_;

	if ($preconf -> {core_blockui_on_submit} && $options -> {blockui}) {

		unless ($options -> {href} =~ /^javaScript\:/i) {

			$options -> {target} ||= '_self';

			$options -> {href} =~ s{\%}{\%25}g unless $options -> {parent};

			$options -> {href} = qq {javascript: nope('$options->{href}','$options->{target}')};

			$options -> {target} = '_self';

		}

		$options -> {href} =~ s/\bnope\b/blockui ('', 1);nope/;

	}

}

################################################################################

sub __adjust_row_cell_style {

	my ($data, $options) = @_;

	$data -> {tabindex} = ++ $_REQUEST {__tabindex};

	my $a = ($data -> {attributes} ||= {});

	$a -> {colspan} = $data -> {colspan} if $data -> {colspan};
	$a -> {rowspan} = $data -> {rowspan} if $data -> {rowspan};

	$a -> {$_} ||= ($data -> {$_} || $options -> {$_}) foreach (qw (bgcolor style));

	unless ($a -> {style}) {

		delete $a -> {style};

		$a -> {class} ||= (

			$data    -> {class} ||

			($options -> {class} ||= (

				$options -> {is_total} ? 'row-cell-total' :

				'row-cell'

			))

		);

		$a -> {class} .= '-transparent' if $a -> {bgcolor} && $a -> {class} !~ /-transparent/;

		$a -> {class} .= '-no-scroll' if ($data -> {no_scroll} && $data -> {attributes} -> {class} =~ /row-cell/);

	}

}

################################################################################

sub __adjust_menu_item {

	my ($_SKIN, $type) = @_;

	if ($_REQUEST {__edit} && !($type -> {no_off} || $_SKIN -> {options} -> {core_unblock_navigation})) {

		$type -> {href} = "javaScript:alert('$$i18n{save_or_cancel}'); document.body.style.cursor = 'default'; nop ();";

	}
	elsif ($type -> {no_page}) {

		$type -> {href} = "javaScript:document.body.style.cursor = 'default'; nop ()";

	}

	$type -> {onmouseout} = "menuItemOut ()";

	if (ref $type -> {items} eq ARRAY && (!$_REQUEST {__edit} || $_SKIN -> {options} -> {core_unblock_navigation})) {

		$type -> {onhover} = "menuItemOver(this, '$$type{name}')";

	}
	else {

		$type -> {onhover} = "menuItemOver(this)";

	}

}

################################################################################

sub __adjust_toolbar_btn_vert_menu_item {

	my ($_SKIN, $type, $name, $types, $level, $is_main) = @_;

	$type -> {onmouseout} = "menuItemOutForToolbarBtn ()";

	if (ref $type -> {items} eq ARRAY && !$_REQUEST {__edit}) {

		$type -> {onhover}    = "menuItemOverForToolbarBtn (this, '$$type{name}', '$name', $level)";

	}
	else {

		$type -> {onhover}    = "menuItemOverForToolbarBtn (this, null, '$name', $level)";

		$type -> {onclick}    =

			$type  -> {href} =~ /^javascript\:/i ? $' :

			"activate_link('$$type{href}', '$$type{target}')";

		$type -> {onclick} = "hideSubMenusForToolbarBtn(0);" . $type -> {onclick};


		$type -> {onclick} =~ s{[\n\r]}{}gsm;

	}
}

################################################################################

sub __adjust_vert_menu_item {

	my ($_SKIN, $type, $name, $types, $level, $is_main) = @_;

	$type -> {onmouseout} = "menuItemOut ()";

	if (ref $type -> {items} eq ARRAY && !$_REQUEST {__edit}) {

		$type -> {onhover}    = "menuItemOver (this, '$$type{name}', '$name', $level)";

	}
	else {

		$type -> {onhover}    = "menuItemOver (this, null, '$name', $level)";

		$type -> {onclick}    =

			$type  -> {href} =~ /^javascript\:/i ? $' :

			$_SKIN -> {options} -> {core_unblock_navigation} ? "hideSubMenus(0); if (!check_edit_mode (this, '$$type{href}')) activate_link('$$type{href}', '$$type{target}')" :

			"hideSubMenus(0); activate_link('$$type{href}', '$$type{target}')";

		$type -> {onclick} =~ s{[\n\r]}{}gsm;

	}

}
################################################################################

sub draw_fatal_error_page {

	return draw_error_page (@_);
}

################################################################################

sub draw_error_page {

	my ($_SKIN, $page, $error) = @_;

	$_REQUEST {__content_type} ||= 'text/html; charset=' . $i18n -> {_charset};

	my $data = $_JSON -> encode ([$error -> {label}]);

	if ($page -> {error_field}) {
		$_REQUEST{__script} .= <<EOJ;
			var e = window.parent.document.getElementsByName('$page->{error_field}');
			if (e && e[0]) { try {e[0].focus ()} catch (e) {} }
EOJ
	}


	if ($preconf -> {core_dbl_click_protection}) {
		$_REQUEST{__script} .= <<EOJ;
			var __salt = Math.random ();
			var salt_elements = window.parent.document.getElementsByName('__salt');
			try {
				for (var i=0; i < salt_elements.length; i ++) {
					salt_elements [i].value = __salt;
				}
			} catch (e) {}

			var anchor_elements = window.parent.document.getElementsByTagName('a');

			for (var i=0; i < anchor_elements.length; i ++) {

				try {
					if (anchor_elements [i].href.indexOf('__salt=') != -1)
						anchor_elements [i].href = anchor_elements [i].href.replace (/__salt=([\\d\\.]+)/, '__salt=' + __salt);
				} catch (e) {}

			}

EOJ

	}


	$_REQUEST {__no_back} or $_REQUEST {__script} .= "\n if (window.name != 'invisible') {history.go (-1)}\n";

	$_REQUEST {__script} .= <<EOJ;
			var data = $data;
			alert (data [0]);
			try {window.parent.setCursor ()} catch (e) {}
			window.parent.document.body.style.cursor = 'default';
			try {window.parent.poll_invisibles ()} catch (e) {}
EOJ

	$_REQUEST {__script} = <<EOJ;
function on_load () {
$_REQUEST{__script}
}
EOJ

	return qq{<html><head><script>$_REQUEST{__script}</script></head><body onLoad="on_load ()"></body></html>};

}

################################################################################

sub draw_redirect_page {

	my ($_SKIN, $options) = @_;

	if ($options -> {label}) {
		my $data = $_JSON -> encode ([$options -> {label}]);
		$options -> {before} = "var data = $data; alert(data[0]); ";
	}

	$options -> {$_} ||= '' foreach qw (before window_options);

	if ($options -> {message}) {

		$options -> {message_type} ||= "warning";

		my $data = $_JSON -> encode ([$options]);

		$options -> {before} .= <<EOJS
			if (top.localStorage) {
				var data = $data;
				top.localStorage ['message'] = data [0].message;
				top.localStorage ['message_type'] = data[0].message_type;
			}
EOJS

	}

	my $salt = $options -> {no_check_url}? "''" : "'&salt=' + Math.random ()";
	return <<EOH;
<html>
	<script for=window event=onload>
		$options->{before};
		var w = window,
			target = window.name == 'invisible' ? parent : window;
		w.is_redirecting = 1;
		if ('$$options{target}')
			w.open ('$options->{url}' + $salt, '$$options{target}', '$options->{window_options}');
		else
			target.location.href = '$options->{url}';
	</script>
	<body>
	</body>
</html>
EOH

}

################################################################################

sub draw_page__only_field {

	my ($_SKIN, $page) = @_;

	$_REQUEST {__content_type} ||= 'text/html; charset=' . $i18n -> {_charset};

	return qq{<html><head><script>$_REQUEST{__script}</script></head><body onLoad="$_REQUEST{__on_load}"></body><html>};

}

################################################################################

sub draw_form_field__only_field {

	my ($_SKIN, $field, $data) = @_;


	if ($_REQUEST {__only_form}) {
		my $js;
		my @fields = split (',', $_REQUEST {__only_field});
		my @tabs = split (',', $_REQUEST {__only_tabindex});
		my $i;
		for ($i = 0; $i < @fields; $i ++) {
			last if $fields [$i] eq $field -> {name};
		}

		if ($field -> {type} eq 'date' || $field -> {type} eq 'datetime') {

			$field -> {no_reload_dirty} += 0;

			$_REQUEST{__on_load} .= " load_$field->{name} (); ";

			$_REQUEST {__script} .= <<EOJS;
				function load_$field->{name} () {
					var doc = window.parent.document;
					var element = doc.getElementById ('input$field->{name}');
					if (!element) return;
					if ($field->{no_reload_dirty} && element.is_dirty) return;
					element.value = '$field->{value}';
				}
EOJS
			return '';

		}

		my $a = $_JSON -> encode ([$field -> {html}]);

		$_REQUEST{__on_load} .= " load_$field->{name} (); ";

		my $field_name = $field -> {name};
		$field_name .= '_span' if ($field -> {type} eq 'string_voc');

		$_REQUEST {__script} .= <<EOJS;
	function load_$field->{name} () {
		var a = $a;
		var doc = window.parent.document;
EOJS

		if ($field -> {type} eq 'radio') {
			$_REQUEST {__script} .= <<EOJS;
		var element = doc.getElementById ('input_$field->{name}');
EOJS
		} else {
			$_REQUEST {__script} .= <<EOJS;
		var element = doc.getElementById ('input_$field_name');
		if (!element) element = doc.forms ['$_REQUEST{__only_form}'].elements ['_$field_name'];
		if (!element) element = doc.forms ['$_REQUEST{__only_form}'].all.namedItem ('_$field_name');
EOJS
		}

		$_REQUEST {__script} .= <<EOJS;
		if (!element) return;

		element.outerHTML = a [0];
		element.tabIndex = "$tabs[$i]";
//		if (element.onChange) element.onChange ();
	}
EOJS

		return '';
	}

}

1;
