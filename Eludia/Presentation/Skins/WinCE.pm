package Eludia::Presentation::Skins::WinCE;

use Data::Dumper;

BEGIN {
	require Eludia::Presentation::Skins::Generic;
	delete $INC {"Eludia/Presentation/Skins/Generic.pm"};
	our $lrt_bar = '<!-- L' . ('o' x 8500) . "ong comment -->\n";
}

################################################################################

sub options {
	return {};
}

################################################################################

sub __submit_href {

	"javaScript:var f = document.$_[0].submit()";

}

################################################################################

sub _icon_path {
	-r $r -> document_root . "/i/_skins/Classic/$_[0].gif" ?
	"$_REQUEST{__static_url}/$_[0].gif?$_REQUEST{__static_salt}" :
	"/i/buttons/$_[0].gif"
}

################################################################################

sub trunc_string {
	my ($s, $len) = @_;
	return $s if $_REQUEST {xls};
	return length $s <= $len ? $s : substr ($s, 0, $len - 3) . '...';
}

################################################################################

sub register_hotkey {}

################################################################################

sub static_path {

	my ($package, $file) = @_;
	my $path = __FILE__;

	$path    =~ s{\.pm}{/$file};

	return $path;

};

################################################################################

sub draw_hr {

	my ($_SKIN, $options) = @_;
		
	return <<EOH;
<!--
		<table border=0 cellspacing=0 cellpadding=0 width="100%">
			<tr><td class=$$options{class}><img src="/i/0.gif" width=1 height=$$options{height}></td></tr>
		</table>
-->
EOH
	
}

################################################################################

sub draw_calendar {

	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime (time);
	
	$year += 1900;
	
	$_REQUEST {__clock_separator} ||= ':';

	my $dt = sprintf ("%02d.%02d.%d", $mday, $mon + 1, $year);

	return $dt;

}

################################################################################

sub draw_auth_toolbar {

	my ($_SKIN, $options) = @_;

	return '' if ($_REQUEST {__edit});

#	my $calendar = draw_calendar ();
	
	my $subset_selector = '';
	
	if (@{$_SKIN -> {subset} -> {items}} > 1) {
	
		$subset_selector = <<EOH;
			<td class=bgr1>
			<input type=hidden name=sid value='$_REQUEST{sid}'>
			<input type=hidden name=select value='$_REQUEST{select}'>
			<input type=hidden name=__last_query_string value='$_REQUEST{__last_last_query_string}'>
			<select name=__subset onChange="submit()">
EOH

		foreach my $item (@{$_SKIN -> {subset} -> {items}}) {
			$subset_selector .= "<option value='$$item{name}'";
			$subset_selector .= ' selected' if $item -> {name} eq $_SKIN -> {subset} -> {name};
			$item -> {label} = trunc_string ($item -> {label}, 20);
			$subset_selector .= ">$$item{label}</option>";
		}
		
		$subset_selector .= '</select></td>';
	
	}
	$$options{user_label} =~ s/$i18n->{User}: //;
	$$options{user_label} =~ s/(.+) (.).+ (.).+/$1 $2\.$3\./;
#				<td class=bgr1><A class=lnk2>$calendar</A></td>
	return <<EOH;
<!--
		<table cellSpacing=0 cellPadding=0 border=0 width=100%>
			<tr><td class=bgr1><img height=1 src="/i/0.gif" width=1 height=1 border=0></td></tr>
			<tr><td class=bgr6><img height=1 src="/i/0.gif" width=1 height=1 border=0></td></tr>
		</table>
-->
		<table cellSpacing=0 cellPadding=0 border=0 width=100%>
			<form name=_subset_form>
			<tr>
				<td class=bgr1>&nbsp;&nbsp;</td>

				<td class=bgr1><img src="/i/0.gif" width=4 border=0></td>
				<td class=bgr1 width=100%><A class=lnk2 href="#" accesskey="2">&nbsp;</a><A class=lnk2 accesskey="2">$$options{user_label}</a>&nbsp;&nbsp;</td>

				<td class=bgr1><img src="/i/0.gif" width=4 border=0></td>
				<td class=bgr1><img src="/i/0.gif" width=4 border=0></td>

				<td class=bgr1 nowrap width="100%"></td>				

				@{[ $_REQUEST {__help_url} ? <<EOHELP : '' ]}
				<td class=bgr1><img src="/i/0.gif" width=4 border=0></td>
				<td class=bgr1><A TABINDEX=-1 id="help" class=lnk2 href="$_REQUEST{__help_url}">[$$i18n{F1}]</A>&nbsp;&nbsp;</td>
EOHELP

				$subset_selector

			</tr>
			</form>
		</table>
		$$options{top_banner}

EOH

# 				<td class=bgr1><img height=22 src="/i/0.gif" width=4 border=0></td>
# 				<td class=bgr1><img height=1 src="/i/0.gif" width=7 border=0></td>
}

################################################################################

sub draw_window_title {

	my ($_SKIN, $options) = @_;

	return ''
		if $_REQUEST {select};

	return <<EOH
		<table cellspacing=0 cellpadding=0 width="100%"><tr><td class='header15'><img src="/i/0.gif" width=1 align=absmiddle>&nbsp;&nbsp;&nbsp;$$options{label}</table>
EOH

}

################################################################################
# FORMS & INPUTS
################################################################################

sub _draw_bottom {

	my ($_SKIN, $options) = @_;
	
	unless ($options -> {menu}) {
		return <<EOH;
			<table cellspacing=0 cellpadding=0 width="100%">
				<tr>
					<td class=bgr6><img height=1 src="/i/0.gif" width=1 border=0></td>
				</tr>
			</table>
EOH
	}
	
	
	my $items = $options -> {menu};
		
	my ($tr1, $tr2, $tr3) = ('', '');

	$tr3 .= qq{<td></td>};
	$tr2 .= qq{<td></td>};
	$tr1 .= qq{<td class='bgr6' width=100%><img src="/i/0.gif" border=0 hspace=0 vspace=0 width=1 height=1></td>};

	my $class = $items -> [0] -> {is_active} ? 'bgr0' : 'bgr6';
	
	$tr1 .= qq{<td class='$class'><img src="/i/0.gif" border=0 hspace=0 vspace=0 width=1 height=1></td>};

	$tr3 .= qq{<td rowspan=2 valign=top><img src="$_REQUEST{__static_url}/tab_l_${$$items[0]}{is_active}.gif?$_REQUEST{__static_salt}" border=0 hspace=0 vspace=0 width=6 height=17></td>};

	for (my $i = 0; $i < 0 + @$items; $i++) {

		my $item = $items -> [$i];	
		my $active = $item -> {is_active};

		my $class = $active ? 'bgr0' : 'bgr6';

		$tr1 .= qq{<td class='$class'><img src="/i/0.gif" border=0 hspace=0 vspace=0 width=1 height=1></td>};

		my $accesskey = '';
		if ($items -> [$i] -> {hotkey}) {
			$items -> [$i] -> {hotkey} =~ s/\D//gsm;
			$accesskey = 'accesskey="' . $items -> [$i] -> {hotkey} . '"';
		}

		$tr2 .= qq{<td class="tabs-$active"><a id="$item" href="$$item{href}" class="main-menu" $accesskey>&nbsp;$$item{label}&nbsp;</a></td>};

		$tr3 .= qq{<td background="$_REQUEST{__static_url}/tab_b_$active.gif?$_REQUEST{__static_salt}"><img src="/i/0.gif" border=0 hspace=0 vspace=0 width=1 height=2></td>};

		if ($i < -1 + @$items) {
			my $aa = $active . ($items -> [$i + 1] -> {is_active});
			my $class = $aa ne '00' ? 'bgr0' : 'bgr6';
			$tr1 .= qq{<td class='$class'><img src="/i/0.gif" border=0 hspace=0 vspace=0 width=1 height=1></td>};
			$tr3 .= qq{<td rowspan=2><img src="$_REQUEST{__static_url}/tab_$aa.gif?$_REQUEST{__static_salt}" border=0 hspace=0 vspace=0 width=8 height=17></td>};
		}
		else {
			my $class = $active ? 'bgr0' : 'bgr6';
			$tr1 .= qq{<td class='$class'><img src="/i/0.gif" border=0 hspace=0 vspace=0 width=1 height=1></td>};
			$tr3 .= qq{<td rowspan=2 valign=top><img src="$_REQUEST{__static_url}/tab_r_${$$items[-1]}{is_active}.gif?$_REQUEST{__static_salt}" border=0 hspace=0 vspace=0 width=6 height=17></td>};
		}

	}
			
	$tr3 .= qq{<td rowspan=2 valign=top><img src="/i/0.gif" border=0 hspace=0 vspace=0 width=1 height=1></td>};
	$tr1 .= qq{<td class='bgr6' width=30><img src="/i/0.gif" border=0 hspace=0 vspace=0 width=1 height=1></td>};

	return <<EOH;
		<table border=0 cellspacing=0 cellpadding=0 width=100%>
			<tr>$tr3
			<tr>$tr2
			<tr>$tr1
		<table>
EOH

}

################################################################################

sub _draw_input_datetime {

	my ($_SKIN, $options) = @_;

	my $form_name = 'toolbar_form_' . $_REQUEST {__toolbars_number};

#	$r -> header_in ('User-Agent') =~ /MSIE 5\.0/ or return draw_form_field_string (@_);

	$options -> {id} ||= '' . $options;

	$options -> {onClose}    ||= 'null';
	$options -> {onChange}   ||= 'document.$form_name.submit()';

	$options -> {no_read_only} or $options -> {attributes} -> {readonly} = 1;
	$options -> {attributes} -> {size} = 6;
	my $attributes = dump_attributes ($options -> {attributes});

	my $shows_time = $options -> {no_time} ? 'false' : 'true';

#		<button id="calendar_trigger_$$options{id}" class="form-active-ellipsis">...</button>
#			autocomplete="off" 
	my $html = <<EOH;
		<div id="input_$$options{name}">
		<input 
			type="text" 
			name="$$options{name}" 
			$attributes 
			onFocus="q_is_focused = true;" 
			onBlur="q_is_focused = false"
			onChange="nope('javascript:$$options{onChange}');" 
		>
		</div>
EOH

	return $html;
	
}

################################################################################

sub draw_form {

	my ($_SKIN, $options) = @_;
		
	if ($_REQUEST {__only_field}) {
		my $html .= '';
		foreach my $row (@{$options -> {rows}}) {
			foreach (@$row) { $html .= $_ -> {html} };
		}
		return $html;	
	}
			
	my $html = $options -> {hr};
	
	$html .= _draw_bottom (@_);
	
	$html .= $options -> {path};
	
	$html .= $options -> {bottom_toolbar};

	$options -> {name} .= '_' . $_REQUEST {select} if ($_REQUEST {select});

	$html .=  <<EOH;
		<table cellspacing=1 width="100%">
			<form 
				name="$$options{name}"
				method="$$options{method}"
				enctype="$$options{enctype}"
				action="$_REQUEST{__uri}"
			>
EOH
	
	foreach (@{$options -> {keep_params}}) {
		$html .= qq{\n\t\t\t\t<input type=hidden name="$$_{name}" value="$$_{value}">};
	}
	
	foreach my $row (@{$options -> {rows}}) {
		my $tr_id = $row -> [0] -> {tr_id};
#		$html .= qq{<tr id="$tr_id">};
		foreach (@$row) { $html .= qq{<tr id="$tr_id">$_->{html}</tr>} };
#		$html .= qq{</tr>};
	}

	$html .=  '</form></table>';
	
	$html .= $options -> {bottom_toolbar};
	
	return $html;	

}

################################################################################

sub draw_path {

	my ($_SKIN, $options, $list) = @_;

	return '' if ($_REQUEST {__edit});

	my $path = <<EOH;
		<table cellspacing=0 cellpadding=0 width="100%" border=0>
			<tr>
				<td class=bgr8>
					<table cellspacing=0 cellpadding=0 width="100%" border=0>
						<tr height=18>
							<td class=bgr0 $$options{nowrap}>&nbsp;
EOH

	if ($conf -> {core_show_icons} || $_REQUEST {__core_show_icons}) {
#		$path .= qq{<img src="$_REQUEST{__static_url}/folder.gif?$_REQUEST{__static_salt}" border=0 hspace=3 vspace=1 align=absmiddle>&nbsp;};
	}

	for (my $i = 0; $i < @$list; $i ++) {

		if ($i > 0) {
			$path .= '&nbsp;/&nbsp;';
			if ($options -> {multiline}) {
				$path .= '<br>';
				for (my $j = 0; $j < $i + 2; $j++) { $path .= '&nbsp;&nbsp;' }
			}
		}

		my $item = $list -> [$i];		

		$path .= qq{<a class=path ${\($$item{href} ? "href='$$item{href}'" : '')} TABINDEX=-1>$$item{label}</a>};

	}

	$path .= <<EOH;
&nbsp;</td>
						</tr>
<!--
						<tr>
							<td class=bgr8 colspan=4><img height=1 src="/i/0.gif" width=1 border=0></td>
						</tr>
						<tr>
							<td class=bgr6 colspan=4><img height=1 src="/i/0.gif" width=1 border=0></td>
						</tr>
-->
					</table>
				</td>
			</tr>
		</table>
EOH

	return $path;

}

################################################################################

sub draw_form_field {

	my ($_SKIN, $field, $data) = @_;

	if ($_REQUEST {__only_field} && $_REQUEST {__only_field} eq $field -> {name}) {
		return $field -> {html};
	}

	if ($field -> {type} eq 'banner') {
		my $colspan     = 'colspan=' . ($field -> {colspan} + 1);
		return qq{<td class='form-$$field{state}-label' $colspan nowrap align=center>$$field{html}</td>};
	}
	elsif ($field -> {type} eq 'hidden') {
		return $field -> {html};
	}

#	my $colspan     = $field -> {colspan}     ? 'colspan=' . $field -> {colspan}     : '';
	my $label_width = $field -> {label_width} ? 'width='   . $field -> {label_width} : '';	
	my $cell_width  = $field -> {cell_width}  ? 'width='   . $field -> {cell_width}  : '';
	$$field{label} =~ s/\&//g;
	return <<EOH;
		<td class='form-$$field{state}-label' nowrap align=right $label_width>\n$$field{label}</td>
		<td class='form-$$field{state}-inputs' $colspan $cell_width>\n$$field{html}</td>
EOH

}

################################################################################

sub draw_form_field_banner {
	my ($_SKIN, $field, $data) = @_;
	return $field -> {label};
}

################################################################################

sub draw_form_field_button {
	my ($_SKIN, $options, $data) = @_;
	return qq {<input type="button" name="_$$options{name}" value="$$options{value}" onClick="$$options{onclick}" tabindex=$tabindex>};
}

################################################################################

sub draw_form_field_string {
	my ($_SKIN, $options, $data) = @_;
	$options -> {attributes} -> {class} ||= 'form-active-inputs';

	return '<div id="input' . $options -> {attributes} -> {name} . '"><input type="text"' . dump_attributes ($options -> {attributes}) . ' onChange="is_dirty=true" onFocus="q_is_focused = true" onBlur="q_is_focused = false"></div>';
}

################################################################################

sub draw_form_field_datetime {

	my ($_SKIN, $options, $data) = @_;
		
	$options -> {attributes} -> {class} ||= 'form-active-inputs';	
	$options -> {name} = '_' . $options -> {name};

	return $_SKIN -> _draw_input_datetime ($options);
	
}

################################################################################

sub draw_form_field_file {

	my ($_SKIN, $options, $data) = @_;	
		
	return <<EOH;
		<div id="input_$$options{name}">
		<input 
			type="file"
			name="_$$options{name}"
			size=$$options{size}
			onFocus="q_is_focused = true"
			onBlur="q_is_focused = false"
			onChange="is_dirty=true; $$options{onChange}"
			tabindex=-1
		>
		</div>
EOH

}

################################################################################

sub draw_form_field_hidden {
	my ($_SKIN, $options, $data) = @_;
	return qq {<input type="hidden" name="_$$options{name}" value="$$options{value}">};
}

################################################################################

sub draw_form_field_hgroup {

	my ($_SKIN, $options, $data) = @_;
	my $html = '';
	foreach my $item (@{$options -> {items}}) {
		next if $item -> {off};
		$html .= $item -> {label} if $item -> {label};
		$html .= $item -> {html};
		$html .= '&nbsp;';
	}
	return $html;
	
}

################################################################################

sub draw_form_field_text {

	my ($_SKIN, $options, $data) = @_;
	my $attributes = dump_attributes ($options -> {attributes});
	return <<EOH;
		<div id="input_$$options{name}">
		<textarea 
			$attributes 
			onFocus="q_is_focused = true" 
			onBlur="q_is_focused = false" 
			rows=$$options{rows}
			cols=$$options{cols}
			name="_$$options{name}" 
			onchange="is_dirty=true;"
		>$$options{value}</textarea>
		</div>
EOH

}

################################################################################

sub draw_form_field_password {
	my ($_SKIN, $options, $data) = @_;
	my $attributes = dump_attributes ($options -> {attributes});
	return qq {<div id="input_$$options{name}"><input type="password" name="_$$options{name}" size="$$options{size}" onChange="is_dirty=true" $attributes onFocus="q_is_focused = true" onBlur="q_is_focused = false"></div>};
}

################################################################################

sub draw_form_field_static {
		
	my ($_SKIN, $options, $data) = @_;

	my $html = "<div id=\"input_$$options{name}\">";

	if ($options -> {href}) {
		my $state = $data -> {fake} == -1 ? 'deleted' : $_REQUEST {__read_only} ? 'passive' : 'active';
		$options -> {a_class} ||= "form-$state-inputs";
		$html = qq{<a href="$$options{href}" class="$$options{a_class}">};
	}
	
	$html .= "<font color='$$options{color}'>" if ($options -> {color});

	if (ref $options -> {value} eq ARRAY) {
	
		for (my $i = 0; $i < @{$options -> {value}}; $i++) {
			$html .= '<br>' if $i;
			$html .= $options -> {value} -> [$i] -> {label};
		}
		
	}
	else {
		$html .= $options -> {value};
	}

	$html .= '</font>' if ($options -> {color});

	if ($options -> {href}) {
		$html .= '</a>';
	}
	
	$html .= qq {<input type=hidden name="$$options{hidden_name}" value="$$options{hidden_value}">} if ($options -> {add_hidden});

	$html .= '</div>';

	return $html;
	
}

################################################################################

sub draw_form_field_checkbox {

	my ($_SKIN, $options, $data) = @_;
	
	my $attributes = dump_attributes ($options -> {attributes});
	
	return qq {<div id="input_$$options{name}"><input type="checkbox" name="_$$options{name}" $attributes $checked value=1 onChange="is_dirty=true"></div>};
	
}

################################################################################

sub draw_form_field_radio {

	my ($_SKIN, $options, $data) = @_;
				
	my $html = '<div id="input_' . $options -> {name}. '"><table border=0 cellspacing=2 cellpadding=0 width=100%>';
	
	foreach my $value (@{$options -> {values}}) {
	
		delete $value -> {attributes} -> {name};
		delete $value -> {attributes} -> {value};
		delete $value -> {attributes} -> {id};
	
		my $attributes = dump_attributes ($value -> {attributes});

		$html .= qq {\n<tr><td valign=top width=1%><input $attributes id="$value" onFocus="q_is_focused = true" onBlur="q_is_focused = false" type="radio" name="_$$options{name}" value="$$value{id}" onClick="is_dirty=true">&nbsp;$$value{label}};
							
		$value -> {html} or next;
		
		$html .= qq{\n\t\t<td><div style="display:expression(getElementById('$value').checked ? 'block' : 'none')">$$value{html}</div>};
				
	}
	
	$html .= '</table>';
		
	return $html;
	
}

################################################################################

sub draw_form_field_select {

	my ($_SKIN, $options, $data) = @_;

	my $attributes = dump_attributes ($options -> {attributes});

	if (defined $options -> {other}) {

		$options -> {other} -> {width}  ||= 600;
		$options -> {other} -> {height} ||= 400;

		$options -> {no_confirm} ||= $conf -> {core_no_confirm_other};

		if ($options -> {no_confirm}) {

			$options -> {onChange} .= <<EOJS;

				if (this.options[this.selectedIndex].value == -1) {

					switchDiv(); 
					loadSlaveDiv('${$$options{other}}{href}&select=$$options{name}');

				}
EOJS
		} else {

			$options -> {onChange} .= <<EOJS;

				if (this.options[this.selectedIndex].value == -1) {

					if (window.confirm ('$$i18n{confirm_open_vocabulary}')) {

						switchDiv(); 
						loadSlaveDiv('${$$options{other}}{href}&select=$$options{name}');

					} else {

						this.selectedIndex = 0;

					}
				}
EOJS
		}
	}









	my $html = <<EOH;
		<div id="input_$$options{name}">
		<select 
			name="_$$options{name}"
			id="_$$options{name}_select"
			$attributes
			onChange="is_dirty=true; $$options{onChange}"
		>
EOH

	if (defined $options -> {empty}) {
		$html .= qq {<option value="0" $selected>$$options{empty}</option>\n};
	}

	foreach my $value (@{$options -> {values}}) {
		$html .= qq {<option value="$$value{id}" $$value{selected}>$$value{label}</option>\n}; 
	}

	if (defined $options -> {other}) {
		$html .= qq {<option value=-1>${$$options{other}}{label}</option>};
		$html .= qq {<option id='_$$options{name}_select_other' value=''></option>};
	}

	$html .= '</select></div>';

	return $html;

}

################################################################################

sub draw_form_field_checkboxes {

	my ($_SKIN, $options, $data) = @_;

	my $html = '';

	my $tabindex = $_REQUEST {__tabindex} + 1;

	my $v = $data -> {$options -> {name}};

	if (ref $v eq ARRAY) {

		my $n = 0;

		$html .= '<table border=0 cellpadding=0 cellspacing=0><tr>';

		foreach my $value (@{$options -> {values}}) {

			my $checked = 0 + (grep {$_ eq $value -> {id}} @$v) ? 'checked' : '';

			my $id = 'div_' . $value;
			$id =~ s/[\(\)]//g;
			my $subhtml = '';
			my $subattr = '';

			my $display = $checked || $options -> {expand_all} ? '' : "style='display:none'";

			if ($value -> {html}) {

				$subhtml .= $value -> {inline} ? qq{&nbsp;<span id="$id" $display>} : qq{&nbsp;</td><td id="$id" $display>};
				$subhtml .= $value -> {html};
				$subhtml .= $value -> {inline} ? qq{</span>} : '';

				$subattr = qq{onClick="setVisible('$id', checked)"} unless $options -> {expand_all};

			}
			elsif ($value -> {items} && @{$value -> {items}} > 0) {

				foreach my $subvalue (@{$value -> {items}}) {

					my $subchecked = 0 + (grep {$_ eq $subvalue -> {id}} @$v) ? 'checked' : '';

					$tabindex++;

					$subhtml .= $subvalue -> {no_checkbox} ?
						qq{&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;$$subvalue{label} <br>}
					:
						qq {&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<input type="checkbox" name="_$$options{name}_$$subvalue{id}" value="1" $subchecked onChange="is_dirty=true" tabindex=$tabindex>&nbsp;$$subvalue{label} <br>};

				}

				$subhtml = <<EOH;
					<div id="$id" $display>
						$subhtml
					</div>
EOH

				$subattr = qq{onClick="setVisible('$id', checked)"} unless $options -> {expand_all};

			}

			$tabindex ++;
			$n ++;

			$html .= qq {<td><input $subattr type="checkbox" name="_$$options{name}_$$value{id}" value="1" $checked onChange="is_dirty=true" tabindex=$tabindex>&nbsp;$$value{label} $subhtml</td>};
			$html .= '</tr><tr>' unless $n % $options -> {cols};

		}

		$html =~ s{\<tr\>$}{};		
		$html .= '</table>';

	}
	else {

		foreach my $value (@{$options -> {values}}) {
			my $checked = $v eq $value -> {id} ? 'checked' : '';
			$tabindex++;
			$html .= qq {<input type="checkbox" name="_$$options{name}" value="$$value{id}" $checked onChange="is_dirty=true" tabindex=$tabindex>&nbsp;$$value{label} <br>};
		}

	}

	if ($options -> {height}) {
		$html = <<EOH;
			<div class="checkboxes" style="height:$$options{height}px;" id="input_$$options{name}">
				$html
			</div>
EOH
	}

	$_REQUEST {__tabindex} = $tabindex;

	return $html;

}

################################################################################

sub draw_form_field_image {

	my ($_SKIN, $options, $data) = @_;
	
	return <<EOH;
		<div id="input_$$options{name}">
		<input type="hidden" name="_$$options{name}" value="$$options{id_image}">
		<img src="$$options{src}" id="$$options{name}_preview" width = "$$options{width}" height = "$$options{height}">&nbsp;
		<input type="button" value="$$i18n{Select}" onClick="nope('$$options{new_image_url}', 'selectImage' , '');">
		</div>
EOH

}

################################################################################

sub draw_form_field_iframe {

	return '';

}

################################################################################

sub draw_form_field_dir {

	my ($_SKIN, $options, $data) = @_;

	my $salt = rand ();

	$_REQUEST {__on_load} = qq{davdiv.navigateFrame("$$options{url}/", "$$options{name}");} . $_REQUEST {__on_load};

	return <<EOH;
		<iframe name="$$options{name}" src="" width="$$options{width}" height="$$options{height}" application="yes"></iframe>
EOH

}

################################################################################

sub draw_form_field_color {
	
	my ($_SKIN, $options, $data) = @_;
	
	my $html = <<EOH;
		<div id="input_$$options{name}">
		<table 
			align="absmiddle" 
			cellspacing=0
			cellpadding=0
			style="height:20px;width:40px;border:solid black 1px;background:#$$options{value}"
EOH
	
	if (!$_REQUEST {__read_only}) {
	
		$html .= <<EOH;
			onClick="
				var color = showModalDialog('$_REQUEST{__static_url}/colors.html?$_REQUEST{__static_salt}', window, 'dialogWidth:600px;dialogHeight:400px;help:no;scroll:no;status:no');
				document.all.td_color_$$options{name}.style.background = color;
				document.all.input_color_$$options{name}.value = color.substr (1);
			"
EOH

	}

	$html .= <<EOH;
		>
			<tr height=20>
				<td id="td_color_$$options{name}" >
					<input id="input_color_$$options{name}" type="hidden" name="_$$options{name}" value="$$options{value}">
				</td>
			</tr>
		</table>
		</div>
EOH

	return $html;

}

################################################################################

sub draw_form_field_htmleditor {
	
	my ($_SKIN, $options, $data) = @_;
	
	return '' if $options -> {off};
	
	push @{$_REQUEST{__include_js}}, 'rte/fckeditor';
	
	return <<EOH;
		<SCRIPT language="javascript">
			<!--
				var oFCKeditor_$$options{name};
				oFCKeditor_$$options{name} = new FCKeditor('_$$options{name}', '$$options{width}', '$$options{height}', '$$options{toolbar}');
				oFCKeditor_$$options{name}.Value = '$$options{value}';
				oFCKeditor_$$options{name}.Create ();
			//-->
		</SCRIPT>
EOH

}

################################################################################
# TOOLBARS
################################################################################

################################################################################

sub draw_toolbar {

	my ($_SKIN, $options) = @_;

	if ($_REQUEST {select}) {

		my $button = {		
			icon    => 'cancel',
			id      => 'cancel',
			label   => $i18n -> {close},
			href    => "javaScript:switchDiv();",
		};
		
		$button -> {html} = $_SKIN -> draw_toolbar_button ($button);

		unshift @{$options -> {buttons}}, $button;

	}

	my $form_name = 'toolbar_form_' . $_REQUEST {__toolbars_number};

	my $html = <<EOH;
		<table class=bgr8 cellspacing=0 cellpadding=0 width="100%" border=0>
			<form action=$_REQUEST{__uri} name="$form_name">
EOH

	foreach (@{$options -> {keep_params}}) {
		$html .= qq{<input type="hidden" name="$_" value="$_REQUEST{$_}">}	
	}

#					<td class=bgr8 width=30><img height=1 src="/i/0.gif" width=20 border=0></td>
	$html .= <<EOH;
					<input type=hidden name=sid value=$_REQUEST{sid}>
					<input type=hidden name=__last_query_string value="$_REQUEST{__last_query_string}">
					<input type=hidden name=__last_last_query_string value="$_REQUEST{__last_last_query_string}">

<!--
				<tr>
					<td class=bgr0 colspan=20><img height=1 src="/i/0.gif" width=1 border=0></td>
				</tr>
				<tr>
					<td class=bgr6 colspan=20><img height=1 src="/i/0.gif" width=1 border=0></td>
				</tr>
-->
				<tr>
EOH

	foreach (@{$options -> {buttons}}) {	$html .= $_ -> {html};	}

#					<td class=bgr8 width=100%><img height=1 src="/i/0.gif" width=1 border=0></td>
	$html .= <<EOH;
				</tr>
<!--
				<tr>
					<td class=bgr8 colspan=20><img height=1 src="/i/0.gif" width=1 border=0></td>
				</tr>
				<tr>
					<td class=bgr6 colspan=20><img height=1 src="/i/0.gif" width=1 border=0></td>
				</tr>
-->
			</form>
		</table>
EOH

	return $html;

}

################################################################################

sub draw_toolbar_break {

	my ($_SKIN, $options) = @_;

	my $html = <<EOH;
				</tr>
				<tr>
					<td class=bgr8 colspan=20><img height=1 src="/i/0.gif" width=1 border=0></td>
				</tr>
				<tr>
					<td class=bgr6 colspan=20><img height=1 src="/i/0.gif" width=1 border=0></td>
				</tr>
EOH

	if ($options -> {break_table}) {		
		$html .= '</table><table class=bgr8 cellspacing=0 cellpadding=0 width="100%" border=0>';		
	}

#					<td class=bgr8 width=30><img height=1 src="/i/0.gif" width=20 border=0></td>
	$html .= <<EOH;
				<tr>
					<td class=bgr0 colspan=20><img height=1 src="/i/0.gif" width=1 border=0></td>
				</tr>
				<tr>
					<td class=bgr6 colspan=20><img height=1 src="/i/0.gif" width=1 border=0></td>
				</tr>
				<tr>
EOH

	return $html;

}

################################################################################

sub draw_toolbar_button {

	my ($_SKIN, $options) = @_;

	$options -> {href} = "javascript:loadSlaveDiv('$$options{href}');" if ($_REQUEST {select} && $options -> {href} && $options -> {href} !~ /switchDiv/);

	my $accesskey = defined $options -> {accesskey} ? "accesskey=\"$$options{accesskey}\"" : ''; 

	if ($options -> {href} =~ /action=create/ && !$accesskey) {
		$accesskey = 'accesskey="0"';
	}

	my $html = <<EOH;
		<td class="button"nowrap><a TABINDEX=-1 class=button href="$$options{href}" $onclick id="$$options{id}" $accesskey>
EOH

	if ($options -> {icon}) {
		my $img_path = _icon_path ($options -> {icon});
		$html .= qq {<img src="$img_path" alt="$label" border=0 hspace=0 vspace=1 align=absmiddle>};
	}
	
#	$html .= $options -> {label};

	$html .= <<EOH;
			</a>
		</td>
		<td><img height=15 vspace=1 hspace=4 src='$_REQUEST{__static_url}/razd1.gif?$_REQUEST{__static_salt}' width=2 border=0></td>
EOH

	return $html;
	
}

################################################################################

sub draw_toolbar_input_select {

	my ($_SKIN, $options) = @_;
	
	my $form_name = 'toolbar_form_' . $_REQUEST {__toolbars_number};

	my $html = '<td nowrap>';
		
	if ($options -> {label} && $options -> {show_label}) {
		$html .= $options -> {label};
		$html .= ': ';
	}
	
	$html .= <<EOH;
		<select name="$$options{name}" onChange="nope('javascript:document.$form_name.submit()')">
EOH

	foreach my $value (@{$options -> {values}}) {
		next if $value -> {id} == -1;
		$html .= qq {<option value="$$value{id}" $$value{selected}>$$value{label}</option>};
	}

	$html .= "</select><td><img height=15 vspace=1 hspace=4 src='$_REQUEST{__static_url}/razd1.gif?$_REQUEST{__static_salt}' width=2 border=0></td>";

	return $html;
	
}

################################################################################

sub draw_toolbar_input_checkbox {

	my ($_SKIN, $options) = @_;
	
	my $form_name = 'toolbar_form_' . $_REQUEST {__toolbars_number};

	my $html = '<td nowrap>';
		
	if ($options -> {label}) {
		$html .= $options -> {label};
		$html .= ': ';
	}

	$html .= qq {<input type=checkbox value=1 $$options{checked} name="$$options{name}" onClick="nope('javascript:document.$form_name.submit()');">};

	$html .= "<td><img height=15 vspace=1 hspace=4 src='$_REQUEST{__static_url}/razd1.gif?$_REQUEST{__static_salt}' width=2 border=0></td>";
	
	return $html;

}

################################################################################

sub draw_toolbar_input_submit {

	my ($_SKIN, $options) = @_;

	my $form_name = 'toolbar_form_' . $_REQUEST {__toolbars_number};

	my $html = '<td nowrap>';
		
	if ($options -> {label}) {
		$html .= $options -> {label};
		$html .= ': ';
	}

	$html .= qq {<input type=submit name="$$options{name}" value="$$options{label}">};

	$html .= "<td><img height=15 vspace=1 hspace=4 src='$_REQUEST{__static_url}/razd1.gif?$_REQUEST{__static_salt}' width=2 border=0></td>";
	
	return $html;

}

################################################################################

sub draw_toolbar_input_text {

	my ($_SKIN, $options) = @_;
	
	my $form_name = 'toolbar_form_' . $_REQUEST {__toolbars_number};

	my $html = '<td nowrap>';
		
	if ($options -> {label} && 0) {
		$html .= $options -> {label};
		$html .= ': ';
	}

	$options -> {size} = 2;

	my $accesskey = defined $options -> {accesskey} ? "accesskey=\"$$options{accesskey}\"" : '';

	$html .= <<EOH;
		<input 
			onChange="nope('javascript:document.$form_name.submit()');" 
			type=text 
			size=$$options{size} 
			name=$$options{name} 
			value="$$options{value}" 
			onFocus="q_is_focused = true" 
			onBlur="q_is_focused = false"
			$accesskey
		>
EOH

	foreach my $key (@{$options -> {keep_params}}) {
		next if $key eq $options -> {name} or $key =~ /^_/ or $key eq 'start' or $key eq 'sid';
		$html .= qq {<input type=hidden name=$key value="$_REQUEST{$key}">};
	}

	$html .= "<td><img height=15 vspace=1 hspace=4 src='$_REQUEST{__static_url}/razd1.gif?$_REQUEST{__static_salt}' width=2 border=0></td>";

	return $html;

}

################################################################################

sub draw_toolbar_input_datetime {

	my ($_SKIN, $options) = @_;

	my $form_name = 'toolbar_form_' . $_REQUEST {__toolbars_number};

#	$options -> {onClose}    = "function (cal) { cal.hide (); $$options{onClose}; cal.params.inputField.form.submit () }";	

	my $html = '<td nowrap>';
		
	if ($options -> {label}) {
		$html .= $options -> {label};
		$html .= ': ';
	}

	$html .= $_SKIN -> _draw_input_datetime ($options);

	$html .= "<td><img height=15 vspace=1 hspace=4 src='$_REQUEST{__static_url}/razd1.gif?$_REQUEST{__static_salt}' width=2 border=0></td>";

	return $html;

}

################################################################################

sub draw_toolbar_pager {

	my ($_SKIN, $options) = @_;

	my $html = '<td nowrap>';

	if ($_REQUEST {select}) {
		$options -> {rewind_url} = "javascript:loadSlaveDiv('$$options{rewind_url}')" if ($options -> {rewind_url});
		$options -> {back_url}   = "javascript:loadSlaveDiv('$$options{back_url}')" if ($options -> {back_url});
		$options -> {next_url}   = "javascript:loadSlaveDiv('$$options{next_url}')" if ($options -> {next_url});
	}

	if ($options -> {total}) {

		if ($options -> {rewind_url}) {
			$html .= qq {&nbsp;<a TABINDEX=-1 href="$$options{rewind_url}" class=lnk0>&lt;&lt;</a>&nbsp;&nbsp;};
		}

		if ($options -> {back_url}) {
			$html .= qq {&nbsp;<a TABINDEX=-1 href="$$options{back_url}" class=lnk0 id="_pager_prev" accesskey="7">&lt;</a>&nbsp;&nbsp;};
		}

#		$html .= ($options -> {start} + 1);
#		$html .= ' - ';
#		$html .= ($options -> {start} + $options -> {cnt});
##		$html .= qq |$$i18n{toolbar_pager_of}<a TABINDEX=-1 class=lnk0 href="$$options{infty_url}">$$options{infty_label}</a>|;
#		$html .= qq |$$i18n{toolbar_pager_of}$$options{infty_label}|;

		$html .= ($options -> {start} / $options -> {cnt} + 1);
#		my $count = $options -> {infty_label} eq $i18n -> {infty} ? $i18n -> {infty} : int($options -> {infty_label} / $options -> {cnt}) + 1;
#		$html .= "/$count";

		if ($options -> {next_url}) {
			$html .= qq {&nbsp;<a TABINDEX=-1 href="$$options{next_url}" class=lnk0 id="_pager_next" accesskey="9">&gt;</a>&nbsp;&nbsp;};
		}

	}
	else {
		$html .= $i18n -> {toolbar_pager_empty_list};	
	}

	$html .= "<td><img height=15 vspace=1 hspace=4 src='$_REQUEST{__static_url}/razd1.gif?$_REQUEST{__static_salt}' width=2 border=0></td>";

	return $html;

}

################################################################################

sub draw_centered_toolbar_button {

	my ($_SKIN, $options) = @_;

	my $hotkey = '';
	$hotkey = 1 if ($options -> {hotkey} -> {code} == 115 || ($options -> {hotkey} -> {code} == 13 && $options -> {hotkey} -> {ctrl}));
	$hotkey = 3 if ($options -> {hotkey} -> {code} == 27);
	my $accesskey = $hotkey ? 'accesskey="' . $hotkey . '"' : '';

	my $html = <<EOH;
		<td class="button" nowrap><a TABINDEX=-1 class=button href="$$options{href}" id="$$options{id}" $accesskey>
EOH

	my $img_path = "$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}";

	if ($options -> {icon}) {
		$img_path = _icon_path ($options -> {icon});
		$html .= qq {<img src="$img_path" border=0 hspace=0 vspace=1 align=absmiddle>}
	}

#			$$options{label} 
	$html .= <<EOH;
		</a></td>
		<td><img vspace=1 hspace=4 src="$_REQUEST{__static_url}/razd1.gif?$_REQUEST{__static_salt}" width=2 border=0></td>
EOH

	return $html;

}

################################################################################

sub draw_centered_toolbar {

	my ($_SKIN, $options, $list) = @_;

	our $__last_centered_toolbar_id = 'toolbar_' . int $list;

	my $colspan = 3 * (1 + $options -> {cnt}) + 1;

	my $html = <<EOH;
		<table cellspacing=0 cellpadding=0 width="100%" border=0 id="$__last_centered_toolbar_id">
			<tr>
				<td class=bgr8>
					<table cellspacing=0 cellpadding=0 width="100%" border=0>
<!--
						<tr>
							<td class=bgr0 colspan=$colspan><img height=1 src="/i/0.gif" width=1 border=0></td>
						</tr>
						<tr>
							<td class=bgr6 colspan=$colspan><img height=1 src="/i/0.gif" width=1 border=0></td>
						</tr>
-->
						<tr>
							<td width="45%">
								<table cellspacing=0 cellpadding=0 width="100%" border=0>
									<tr>
										<td _background="/i/toolbars/6ptbg.gif"><img hspace=0 src="/i/0.gif" width=1 border=0></td>
									</tr>
								</table>
							</td>
							<td><img height=15 vspace=1 hspace=4 src="$_REQUEST{__static_url}/razd1.gif?$_REQUEST{__static_salt}" width=2 border=0></td>
EOH

	foreach (@$list) {
		$html .= $_ -> {html};
	}

	$html .= <<EOH;
							<td width="45%">
								<table cellspacing=0 cellpadding=0 width="100%" border=0>
									<tr>
										<td _background="/i/toolbars/6ptbg.gif"><img hspace=0 src="/i/0.gif" width=1 border=0></td>
									</tr>
								</table>
							</td>
							<td align=right><img height=23 src="/i/0.gif" width=4 border=0></td>
						</tr>
<!--
						<tr>
							<td class=bgr8 colspan=$colspan><img height=1 src="/i/0.gif" width=1 border=0></td>
						</tr>
						<tr>
							<td class=bgr6 colspan=$colspan><img height=1 src="/i/0.gif" width=1 border=0></td>
						</tr>
-->
					</table>
				</td>
			</tr>
		</table>
	
EOH
	
	return $html;

}

################################################################################

sub draw_dump_button {

	return {
		label  => 'Dump',
		name   => '_dump',
		href   => create_url () . '&__dump=1',
		side   => 'right_items',
		target => '_blank',
		no_off => 1,
	};
}

################################################################################
# MENUS
################################################################################

################################################################################

sub draw_menu {

	my ($_SKIN, $_options) = @_;

	return if ($_REQUEST {__edit});

# 							var value = document.getElementById('left_menu_select_id').value;
# 							alert (value);
# 							if (value != '') document.location.href = value;
	my $html = <<EOH;

		<table width="100%" class=bgr8 cellspacing=0 cellpadding=0 border=0>
<!--
			<tr>
				<td class=bgr8 colspan=3 width=100%><img height=2 src="/i/0.gif" width=1 border=0></td>
			<tr>
-->
			<tr>
				<td class=bgr1>
					<select
						id='left_menu_id'
						name='left_menu_select'
						onChange="
 							var value = document.all.left_menu_id.value;
 							if (value != '') document.location.href = value;
						"
					>
						<option value=''></option>
@{[_draw_menu_items ($_options -> {left_items})]}
					</select>
				</td>
				<td class=bgr8 width=100%><img height=1 src="/i/0.gif" width=1 border=0></td>
				<td class=bgr1>
					<select
						id='right_menu_id'
						name='right_menu_select'
						onChange="
 							var value = document.all.right_menu_id.value;
 							if (value != '') document.location.href = value;
						"
					>
						<option value=''></option>
@{[_draw_menu_items ($_options -> {right_items})]}
					</select>
				</td>
			</tr>
<!--
			<tr>
				<td class=bgr8 colspan=3 width=100%><img height=2 src="/i/0.gif" width=1 border=0></td>
			<tr>
				<td class=bgr6 colspan=3 width=100%><img height=1 src="/i/0.gif" width=1 border=0></td>
			<tr>
				<td class=bgr0 colspan=3 width=100%><img height=1 src="/i/0.gif" width=1 border=0></td>
-->
		</table>
EOH

	return $html;

}

################################################################################

sub _draw_menu_items {

	my ($items, $shift) = @_;

	$shift += 0;
	my $sh = '&nbsp;' x ($shift * 3);

	my $html;

	foreach my $item (@{$items}) {
		$item -> {href} = '' if ($item -> {no_page});
		$html .= <<EOH;
						<option value='$$item{href}'>$sh$$item{label}</option>
EOH
		$html .= _draw_menu_items ($item -> {items}, $shift + 1) if ($item -> {items}); 
	}

	return $html;

}

################################################################################

sub draw_vert_menu {
	return undef;
}

################################################################################
# TABLES
################################################################################

################################################################################

sub js_set_select_option {
	my ($_SKIN, $name, $item, $fallback_href) = @_;
	return ($fallback_href || $i) unless $_REQUEST {select};
	my $question = js_escape ($i18n -> {confirm_close_vocabulary} . ' ' . $item -> {label} . '?');
	$name ||= '_' . $_REQUEST {select};
	return 'javaScript:if (window.confirm(' . $question . ')) {parent.setSelectOption(' . js_escape ($name) . ', '	. $item -> {id} . ', ' . js_escape ($item -> {label}) . ');}';
}

################################################################################

sub draw_text_cell {

	my ($_SKIN, $data, $options) = @_;

	my $html = "\n\t<td ";
	delete $data -> {attributes} -> {title};
	$html .= dump_attributes ($data -> {attributes}) if $data -> {attributes};
	$html .= '>';
	
	unless ($data -> {off}) {
	
		$data -> {label} =~ s{^\s+}{};
		$data -> {label} =~ s{\s+$}{};

		$html .= qq {<img src='/i/_skins/Classic/status_$data->{status}->{icon}.gif' border=0 alt='$data->{status}->{label}' align=absmiddle hspace=5>} if $data -> {status};

		$html .= '&nbsp;';		

		$html .= '<b>'      if $data -> {bold}   || $options -> {bold};
		$html .= '<i>'      if $data -> {italic} || $options -> {italic};
		$html .= '<strike>' if $data -> {strike} || $options -> {strike};

		$html .= qq {<a id="$$data{a_id}" class=$$data{a_class} href="$$data{href}">} if $data -> {href};

		$html .= $data -> {label};
		
		$html .= '</a>' if $data -> {href};

		$html .= '&nbsp;';		
		
	}
	
	$html .= '</td>';
	
	return $html;

}

################################################################################

sub draw_radio_cell {

	my ($_SKIN, $data, $options) = @_;

	my $attributes = dump_attributes ($data -> {attributes});

	return qq {<td $$options{data} $attributes><input type=radio name=$$data{name} $$data{checked} value='$$data{value}'></td>};

}

################################################################################

sub draw_checkbox_cell {

	my ($_SKIN, $data, $options) = @_;

	my $attributes = dump_attributes ($data -> {attributes});

	return qq {<td $$options{data} $attributes><input type=checkbox name=$$data{name} $$data{checked} value='$$data{value}'></td>};

}

################################################################################

sub draw_select_cell {

	my ($_SKIN, $data, $options) = @_;

	my $attributes = dump_attributes ($data -> {attributes});

	my $multiple = $data -> {rows} > 1 ? "multiple size=$$data{rows}" : '';
	my $html = qq {<td $attributes><select name="$$data{name}" onChange="is_dirty=true; $$options{onChange}" $multiple>};

	$html .= qq {<option value="0">$$data{empty}</option>\n} if defined $data -> {empty};

	foreach my $value (@{$data -> {values}}) {
		$html .= qq {<option value="$$value{id}" $$value{selected}>$$value{label}</option>\n};
	}
	
	$html .= qq {</select></td>};
	
	return $html;

}

################################################################################

sub draw_input_cell {

	my ($_SKIN, $data, $options) = @_;

	my $attributes = dump_attributes ($data -> {attributes});

	$data -> {label} =~ s{\"}{\&quot;}gsm;

	return qq {<td $attributes><input onFocus="q_is_focused = true; left_right_blocked = true;" onBlur="q_is_focused = false; left_right_blocked = false;" type="text" name="$$data{name}" value="$$data{label}" maxlength="$$data{max_len}" size="$$data{size}"></td>};

}

################################################################################

sub draw_row_button {

	my ($_SKIN, $options) = @_;

	if ($options -> {off} || $_REQUEST {lpt}) {	
		return $conf -> {core_hide_row_buttons} == 2 ? '' : '<td class=bgr0 valign=top nowrap width="1%">&nbsp;</td>';
	}
	
	if ($conf -> {core_show_icons} || $_REQUEST {__core_show_icons}) {

		my $label = $options -> {label};
		my $img_path = _icon_path ($options -> {icon});

		$options -> {label} = qq|<img src="$img_path" alt="$$options{label}" border=0 hspace=0 vspace=0 align=absmiddle>|;
		$options -> {label} .= "&nbsp;$label" if $options -> {force_label} || $conf -> {core_hide_row_buttons} > -1;

	}
	else {
		$options -> {label} = "\&nbsp;[$$options{label}]\&nbsp;";
	}
	
	my $vert_line = {label => $options -> {label}, href => $options -> {href}, target => $options -> {target}};
	$vert_line -> {label} =~ s{[\[\]]}{}g;
	push @{$_SKIN -> {__current_row} -> {__types}}, $vert_line;
		
	if ($conf -> {core_hide_row_buttons} == 2) {
		return '';
	}
	elsif ($conf -> {core_hide_row_buttons} == 1) {
		return $_SKIN -> draw_text_cell ({label => '&nbsp;'});
	}
	else {
		return qq {<td class="row-button" valign=top nowrap width="1%"><a TABINDEX=-1 class="row-button" href="$$options{href}">$$options{label}</a></td>};
	}

}

####################################################################

sub draw_table_header {
	
	my ($_SKIN, $data_rows, $html_rows) = @_;
	my $html = '<thead>';
	foreach (@$html_rows) {$html .= $_};
	$html .= '</thead>';
	
}

####################################################################

sub draw_table_header_row {
	
	my ($_SKIN, $data_cells, $html_cells) = @_;
	
	my $html = '<tr>';
	foreach (@$html_cells) {$html .= $_};
	$html .= '</tr>';
	
	return $html;
	
}

####################################################################

sub draw_table_header_cell {
	
	my ($_SKIN, $cell) = @_;
	
	return '' if $cell -> {hidden} || $cell -> {off} || (!$cell -> {label} && $conf -> {core_hide_row_buttons} == 2);

	$cell -> {label} .= "\&nbsp;\&nbsp;<a class=lnk4 href=\"$$cell{href_asc}\"><b>\&uarr;</b></a>"  if $cell -> {href_asc};
	$cell -> {label} .= "\&nbsp;\&nbsp;<a class=lnk4 href=\"$$cell{href_desc}\"><b>\&darr;</b></a>" if $cell -> {href_desc};

	if ($cell -> {href}) {
		$cell -> {label} = "<a class=lnk4 href=\"$$cell{href}\"><b>" . $cell -> {label} . "</b></a>";
	}	

	my $attributes = dump_attributes ($cell -> {attributes});
	
	return "<th $attributes>\&nbsp;$$cell{label}\&nbsp;</th>";

}

####################################################################

sub draw_table {

	my ($_SKIN, $tr_callback, $list, $options) = @_;

	$options -> {height}     ||= 10000;
	$options -> {min_height} ||= 200;
	
	$$options{toolbar} =~ s{^\s+}{}sm;
	$$options{toolbar} =~ s{\s+$}{}sm;

	my $html = <<EOH;
	
		$$options{title}
		$$options{path}
		$$options{top_toolbar}
		
		<table cellspacing=0 cellpadding=0 width="100%">		
			<tr>		
				<form name=$$options{name} action=$_REQUEST{__uri} method=post enctype=multipart/form-data>
					<input type=hidden name=type value=$$options{type}>
					<input type=hidden name=action value=$$options{action}>
					<input type=hidden name=sid value=$_REQUEST{sid}>
					<input type=hidden name=__last_query_string value="$_REQUEST{__last_last_query_string}">
EOH

	foreach my $key (keys %_REQUEST) {
		next if $key =~ /^_/ or $key =~/^(type|action|sid|__last_query_string)$/;
		$html .= qq {<input type=hidden name=$key value="$_REQUEST{$key}">\n};
	}

#	$options -> {no_scroll} = 1;
	$html .= $options -> {no_scroll} ?
#		qq {<td class=bgr8><div class="table-container-x">} :
		qq {<td>} :
		qq {<td class=bgr8><div class="table-container" style="height: expression(actual_table_height(this,$$options{min_height},$$options{height},'$__last_centered_toolbar_id'));">};
		
	$html .= qq {<table cellspacing=1 cellpadding=0 width="100%" lpt=$$options{lpt}>\n};

	$html .= $options -> {header} if $options -> {header};

	$html .= qq {<tbody>\n};

	if ($options -> {dotdot}) {
		$html .= $options -> {dotdot};
	}

	my $menus = '';

	foreach our $i (@$list) {
		
		foreach my $tr (@{$i -> {__trs}}) {

#			$html .= "<tr id='$$i{__tr_id}'";
			$html .= "<tr";
			
			if (@{$i -> {__types}} && $conf -> {core_hide_row_buttons} > -1 && !$_REQUEST {lpt}) {
#				$menus .= $i -> {__menu};
#				$html  .= qq{ oncontextmenu="open_popup_menu('$i'); blockEvent ();"};
			}

			$html .= '>';
			$html .= $tr;
			$html .= '</tr>';
			
		}
		
	}

#			</tbody></table></div>$$options{toolbar}</td></form></tr></table>
	$html .= <<EOH;
			</tbody></table>$$options{toolbar}</td></form></tr></table>
		$menus
		
EOH

	$__last_centered_toolbar_id = '';
		
	return $html;

}

################################################################################

sub draw_one_cell_table {

	my ($_SKIN, $options, $body) = @_;
	
	return <<EOH			
		<table cellspacing=0 cellpadding=0 width="100%">
				<form name=form action=$_REQUEST{__uri} method=post enctype=multipart/form-data>
					<tr><td class=bgr8>$body</td></tr>
				</form>
		</table>
EOH

}

################################################################################

sub draw_error_page {

	my ($_SKIN, $page) = @_;

	my $message = js_escape ($_REQUEST {error});

	if ($_REQUEST {select}) {

		my $html = <<EOS;
nop(); alert ($message);
EOS

		return $html;

	}

	my $html = <<EOH;
		<html>
			<head></head>
			<body onLoad="
EOH
#"
	if ($page -> {error_field}) {
		$html .= <<EOJ;
			var e = window.parent.document.getElementsByName('$page->{error_field}');
			if (e && e[0]) { e[0].focus () }
EOJ
	}

	$html .= <<EOH;
		history.go (-1); 
		alert ($message);
		window.parent.document.body.style.cursor = 'default';
	">
				</body>
			</html>				
EOH
#"
	return $html;

}

################################################################################

sub start_page {
}

################################################################################

sub draw_page {

	my ($_SKIN, $page) = @_;

	if ($_REQUEST {__only_form}) {

		$page -> {body} =~ s{\\}{\\\\}gsm;
		$page -> {body} =~ s{\"}{\\\"}gsm; #"
		$page -> {body} =~ s{[\n\r\s]+}{ }gsm;
		$page -> {body} =~ s{<div.*?>}{}gsm;
		$page -> {body} =~ s{</div>}{}gsm;

		return <<EOH;
nop();
					var element = document.all.input_$_REQUEST{__only_field};
					element.innerHTML = "$page->{body}";
EOH

	}

	return $$page{body} if ($_REQUEST {select});

	my $meta_refresh = $_REQUEST {__meta_refresh} ? qq{<META HTTP-EQUIV=Refresh CONTENT="$_REQUEST{__meta_refresh}; URL=@{[create_url()]}&__no_focus=1">} : '';	

	my $request_package = ref $apr;
	my $mod_perl = $ENV {MOD_PERL};
	$mod_perl ||= 'NO mod_perl AT ALL';

	my $timeout = 1000 * (60 * $conf -> {session_timeout} - 1);

	$_REQUEST {__select_rows} += 0;
	$_REQUEST {__blur_all}    += 0;
	$_REQUEST {__no_focus}    += 0;
	$_REQUEST {__pack}        += 0;
	$_REQUEST {__on_load}     .= $_REQUEST {__doc_on_load};

	if ($_REQUEST {sid}) {

		$_REQUEST {__on_load} .= <<EOH;
			; keepaliveID = setTimeout ("nope('$_REQUEST{__uri}?keepalive=$_REQUEST{sid}', 'invisible'); clearTimeout (keepaliveID)", $timeout);
EOH

	}

	return <<EOH;
		<html>		
			<head>
				<title>$$i18n{_page_title}</title>

				<meta name="Generator" content="Eludia ${Eludia::VERSION} / $$SQL_VERSION{string}; parameters are fetched with $request_package; gateway_interface is $ENV{GATEWAY_INTERFACE}; $mod_perl is in use">
				<meta http-equiv=Content-Type content="text/html; charset=$$i18n{_charset}">
				
				$meta_refresh
				
				<LINK href="$_REQUEST{__static_url}/eludia.css?$_REQUEST{__static_salt}" type=text/css rel=STYLESHEET>
				@{[ map {<<EOJS} @{$_REQUEST{__include_css}} ]}
					<LINK href="/i/$_.css" type=text/css rel=STYLESHEET>
EOJS

					<script src="$_REQUEST{__static_url}/navigation.js?$_REQUEST{__static_salt}">
					</script>
				@{[ map {<<EOCSS} @{$_REQUEST{__include_js}} ]}
					<script type="text/javascript" src="/i/${_}.js">
					</script>
EOCSS
			
				<script>
					var select_rows = $_REQUEST{__select_rows};
					var is_dirty = false;					
					var q_is_focused = false;					
					var left_right_blocked = false;					
					var td2sr = new Array ();
					var td2sc = new Array ();
					var ms_word = null;
					var keepaliveID = null;
					var slave_div = 0;

					var clockID = 0;
					var clockSeparators = new Array (' ', '$_REQUEST{__clock_separator}');
					var clockSeparatorID = 0;

					function body_on_load () {

						initialize_controls ($_REQUEST{__no_focus}, $_REQUEST{__pack}, '$_REQUEST{__focused_input}', $_REQUEST{__blur_all});

						$_REQUEST{__on_load}

					}

				</script>

			</head>
			<body
				bgcolor=white
				leftMargin=0
				topMargin=0
				marginwidth=0
				marginheight=0
				name="body"
				id="body"
				scroll="auto"
				onload= "body_on_load (); try {StartClock ()} catch (e) {}"
				onbeforeunload="document.body.style.cursor = 'wait'"
				onunload=" try {KillClock ()} catch (e) {}"
				${\($conf -> {classic_menu_style} ? 'onmousemove="check_popup_menus(event)"' : '')}
			>

				@{[ $_REQUEST{__help_url} ? <<EOHELP : '' ]}
					<script for="body" event="onhelp">
						nope ('$_REQUEST{__help_url}', '_blank', 'toolbar=no,resizable=yes');
						event.returnValue = false;
					</script>						
EOHELP

				<div id="bodyArea" style="display:block" _style='height:100%; padding:0px; margin:0px'>

					<div id="davdiv" style="behavior:url(#default#httpFolder)">
					</div>
					$$page{auth_toolbar}
					$$page{menu}
					$$page{body}
				</div>
				<div id="slave_div" style="display:none; position:absolute; z-index:100" ></div>
				<a href="#" accesskey="8">&nbsp;</a>
			</body>
		</html>
EOH

}

################################################################################

sub handle_hotkey_focus {

	my ($r) = @_;
	
	<<EOJS
		if (window.event.keyCode == $$r{code} && window.event.altKey && window.event.ctrlKey) {
			document.form.$$r{data}.focus ();
			blockEvent ();
		}
EOJS

}

################################################################################

sub handle_hotkey_href {

	my ($r) = @_;
	
	my $ctrl = $r -> {ctrl} ? '' : '!';
	my $alt  = $r -> {alt}  ? '' : '!';
	
	my $condition = 
		$r -> {off}     ? '0' :
		$r -> {confirm} ? 'window.confirm(' . js_escape ($r -> {confirm}) . ')' : 
		'1';

	if ($r -> {href}) {
			
		return <<EOJS
			if (window.event.keyCode == $$r{code} && $alt window.event.altKey && $ctrl window.event.ctrlKey) {
				if ($condition) {
					nope ('$$r{href}&__from_table=1&salt=' + Math.random (), '_self');
				}
				blockEvent ();
			}
EOJS

	}
	else {
		
		return <<EOJS
			if (window.event.keyCode == $$r{code} && $alt window.event.altKey && $ctrl window.event.ctrlKey) {
				if ($condition) {
					var a = document.getElementById ('$$r{data}');
					activate_link (a.href);
				}
				blockEvent ();
			}
EOJS
	}

}




################################################################################

sub lrt_print {

	my $_SKIN = shift;

	my $id = int (time * rand);
	$r -> print ("<span id='$id'>");
	$r -> print (@_);
	$r -> print ("</span>");
	$r -> print ($lrt_bar);	
	$r -> print (<<EOH);
	<script>
		document.getElementById ('$id').scrollIntoView (false);
	</script>
	</body></html>
EOH


}

################################################################################

sub lrt_println {

	my $_SKIN = shift;

	$_SKIN -> lrt_print (@_, '<br>');
	
}

################################################################################

sub lrt_ok {
	my $_SKIN = shift;
	my $color = $_[1] ? 'red' : 'yellow';
	my $label = $_[1] ? 'Îøèáêà' : 'ÎÊ';
	$_SKIN -> lrt_println ("$_[0] <font color='$color'><b>[$label]</b></font>");
}

################################################################################

sub lrt_start {

	my $_SKIN = shift;

	$|=1;
	
	$r -> content_type ('text/html; charset=windows-1251');
	$r -> send_http_header ();
	
	$_SKIN -> lrt_print (<<EOH);
		<html><BODY BGCOLOR='#000000' TEXT='#dddddd'><font face='Courier New'>
			<iframe name=invisible src="$_REQUEST{__uri}0.html" width=0 height=0 application="yes">
			</iframe>
EOH

}

################################################################################

sub lrt_finish {

	my $_SKIN = shift;

	my ($banner, $href) = @_;
	
	$_SKIN -> lrt_print (<<EOH);
	<script>
		alert ('$banner');
		document.location = '$href';
	</script>
	</body></html>
EOH

}

1;
