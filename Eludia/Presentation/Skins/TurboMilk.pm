package Eludia::Presentation::Skins::TurboMilk;

use Data::Dumper;

BEGIN {

	require Eludia::Presentation::Skins::Generic;
	delete $INC {"Eludia/Presentation/Skins/Generic.pm"};

	our $replacement = {
		error    => 'JS',
		redirect => 'JS',
	};

}

################################################################################

sub options {
	return {};
}

################################################################################

sub register_hotkey {

	my ($_SKIN, $hashref) = @_;

	$hashref -> {label} =~ s{\&(.)}{<u>$1</u>} or return undef;

	my $c = $1;
		
	if ($c eq '<') {
		return 37;
	}
	elsif ($c eq '>') {
		return 39;
	}
	elsif (lc $c eq 'ж') {
		return 186;
	}
	elsif (lc $c eq 'э') {
		return 222;
	}
	else {
		$c =~ y{ЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮйцукенгшщзхъфывапролджэячсмитьбю}{qwertyuiop[]asdfghjkl;'zxcvbnm,.qwertyuiop[]asdfghjkl;'zxcvbnm,.};
		return (ord ($c) - 32);
	}

}

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
EOH
	
}
################################################################################

sub draw_calendar {

	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime (time);
	
	$year += 1900;
	
	$_REQUEST {__clock_separator} ||= ':';
	
	return <<EOH;
		$mday $i18n->{months}->[$mon] $year&nbsp;&nbsp;&nbsp;<span id="clock_hours"></span><span id="clock_separator" style="width:5px"></span><span id="clock_minutes"></span>
EOH
	
}

################################################################################

sub draw_auth_toolbar {

	my ($_SKIN, $options) = @_;

	my $logout_url = $conf -> {exit_url} || create_url (type => '_logout', id => '');

	my ($header, $header_height, $logo_url, $subset_div, $subset_div, $subset_cell);
	
	my $header_prefix = 'out';
	
	if ($_USER -> {id}) {
	
		$$options {user_label} = '<nobr><b>' . $_USER -> {f} . ' ' . substr ($_USER -> {i}, 0, 1) . '. ' . substr ($_USER -> {o}, 0, 1) . '.</b></nobr><br>' . $_USER -> {role_label};

		if (@{$_SKIN -> {subset} -> {items}} > 1) {				
		
			my $href = create_url (type => '', id => '');
		
			$subset_div = <<EOH;
				<div id="Menu">
					<table border="0" cellpadding="0" cellspacing="0">
EOH
		
			for (my $i = 0; $i < @{$_SKIN -> {subset} -> {items}}; $i++) {
			
				my $item = $_SKIN -> {subset} -> {items} -> [$i];

				if ($item -> {name} eq $_SKIN -> {subset} -> {name}) {
				
					$subset_cell = <<EOH;
						<td width="5" align="center"><img src="$_REQUEST{__static_url}/vline.gif?$_REQUEST{__static_salt}" width="2px" height="28px"></td>
						<td><img src="images/0.gif" border="0" hspace="0" width=5 height=1></td>
						<td><div id="admin" onClick="subsets_are_visible = 1 - subsets_are_visible; document.getElementById ('_body_iframe').contentWindow.subsets_are_visible = subsets_are_visible"><a href="#">$$item{label}</a></div></td>
EOH
				
				}
#				else {
				
					my $class = $i == @{$_SKIN -> {subset} -> {items}} - 1 ? 'mm0' : 'mm';

					$subset_div .= <<EOH;
						<tr @{[$item -> {name} eq $_SKIN -> {subset} -> {name} ? 'style="display: none"' : '']} id="_subset_tr_$$item{name}"><td class="$class"><a id="_subset_a_$$item{name}" onClick="subset_on_change('$$item{name}', '$href&__subset=$$item{name}')" href="#">$$item{label}</a></td></tr>
EOH
#				}
			
			}
			
			$subset_div .= <<EOH;
				<tr><td><img src="$_REQUEST{__static_url}/menu_bottom.gif?$_REQUEST{__static_salt}" border="0"></td></tr>
			</table>
		</div>
EOH
		
		}

		my $calendar = draw_calendar ();
		$header_height = 48;
		$header_prefix = 'in';

		$header = <<EOU;

			$subset_cell

			<td>&nbsp;</td>

			<td width="1" align="center"><img src="$_REQUEST{__static_url}/vline.gif?$_REQUEST{__static_salt}" width="2" height="28" hspace=10></td>
			<td align="left" class="txt1" nowrap>$calendar</td>

			<td width="1" align="center"><img src="$_REQUEST{__static_url}/vline.gif?$_REQUEST{__static_salt}" width="2" height="28" hspace=10></td>
			<td align="left" class="txt1">$$options{user_label}</td>

			<td width="1" align="center"><img src="$_REQUEST{__static_url}/vline.gif?$_REQUEST{__static_salt}" width="2px" height="28" hspace=10></td>
			<td width="50" align="right" nowrap><nobr><a class="button" href="$logout_url">&nbsp;$i18n->{Exit}&nbsp;<img src="$_REQUEST{__static_url}/i_exit.gif?$_REQUEST{__static_salt}" width="14px" height="10px" border="0"></a></nobr></td>
EOU
	} elsif ($$conf{logon_hint}) {
		$header_height = 90;

		$header = <<EOH;
			<td><table border=0 cellspacing=0 cellpadding=0>
				<tr>
					<td><img src="$_REQUEST{__static_url}/hint_l.gif?$_REQUEST{__static_salt}" width="6" height="61" border=0></td>
					<td background="$_REQUEST{__static_url}/hint_bg.gif?$_REQUEST{__static_salt}" style='padding-left: 10px; padding-right: 10px;'><img src="$_REQUEST{__static_url}/exclam.gif?$_REQUEST{__static_salt}" width="30" height="34" border=0></td>
					<td background="$_REQUEST{__static_url}/hint_bg.gif?$_REQUEST{__static_salt}" style='padding: 2px;' class="txt1"><img src="$_REQUEST{__static_url}/hint_title.gif?$_REQUEST{__static_salt}" width="144" height="16" border=0><br>$$conf{logon_hint}</td>
					<td><img src="$_REQUEST{__static_url}/hint_r.gif?$_REQUEST{__static_salt}" width="6" height="61" border=0></td>
				</tr>
			</table></td>

EOH
	} else {
		$header_height = 90;
	}
	return <<EOH;
		$subset_div
		<table id="logo_table" cellSpacing=0 cellPadding=0 width="100%" border=0 bgcolor="#e5e5e5" background="/i/bg_logo_$header_prefix.gif" style="background-repeat: repeat-x">
			<tr>
			<td width="20"><img src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=20 height=$header_height border=0></td>
			<td width=1><table border=0 valign="middle" border=0><tr>
				<td valign="top" width=1><img src="/i/logo_$header_prefix.gif" border="0"></td>
				<td width=1><img src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=10 height=1 border=0></td>
				<td width=1 valign="bottom" style='padding-bottom: 5px;'><img src="$_REQUEST{__static_url}/gsep.gif?$_REQUEST{__static_salt}" width="4" height="21"></td>
				<td align="left" valign="middle" class='header_0' width=1><nobr>&nbsp;$$conf{page_title}</nobr></td>
			</tr></table></td>

			$header
			<td width="20px" align="right">&nbsp;</td></tr>
		 </table>
EOH


}

################################################################################

sub draw_window_title {

	my ($_SKIN, $options) = @_;
	
	return <<EOH
		<table cellspacing=0 cellpadding=0 width="100%"><tr><td bgcolor="#edf1f5" class="header_3"><img src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=1 height=29 align=absmiddle>&nbsp;&nbsp;&nbsp;$$options{label}</td></tr><tr><td bgcolor="#e4e9ee"><img src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=1 height=1></td></tr></table>
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
					<td class=bgr6><img height=1 src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=1 border=0></td>
				</tr>
			</table>
EOH
	}
	
	my $html = '';
	my $items = $options -> {menu};
		
	foreach my $item (@$items) {
		if ($item -> {is_active}) {
			$html .= <<EOH;
				<td width=5><img src="$_REQUEST{__static_url}/tab_l_1.gif?$_REQUEST{__static_salt}" width=5 height=22 border=0></td>
				<td bgcolor="#ffffff"><a id="$item" href="$$item{href}" class="tab-1"><nobr>&nbsp;$$item{label}&nbsp;</nobr></a></td>
				<td width=5><img src="$_REQUEST{__static_url}/tab_r_1.gif?$_REQUEST{__static_salt}" width=5 height=22 border=0></td>
				<td width=4><img src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=4 height=22 border=0></td>
EOH
		} else {
			$html .= <<EOH;
				<td width=5><img src="$_REQUEST{__static_url}/tab_l_0.gif?$_REQUEST{__static_salt}" width=5 height=22 border=0></td>
				<td background="$_REQUEST{__static_url}/tab_bg_0.gif?$_REQUEST{__static_salt}"><a id="$item" href="$$item{href}" class="tab-0"><nobr>&nbsp;$$item{label}&nbsp;</nobr></a></td>
				<td width=5><img src="$_REQUEST{__static_url}/tab_r_0.gif?$_REQUEST{__static_salt}" width=5 height=22 border=0></td>
				<td width=4><img src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=4 height=22 border=0></td>
EOH
		}

	}
			
	return <<EOH;
		<table border=0 cellspacing=0 cellpadding=0 width=100%>
			<tr>
				<td background="$_REQUEST{__static_url}/tab_bg.gif?$_REQUEST{__static_salt}" width=10><img height="33" src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=10 border=0></td>
				<td background="$_REQUEST{__static_url}/tab_bg.gif?$_REQUEST{__static_salt}" valign="bottom" align="right"><table border=0 cellspacing=0 cellpadding=0>
					<tr>$html</tr></table>
				</td>
			</tr>
			<tr>
				<td bgcolor="#ffffff" colspan=2><img height="8" src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=1 border=0></td>
			</tr>
		</table>
EOH

}

################################################################################

sub _draw_input_datetime {

	my ($_SKIN, $options) = @_;
		
#	$r -> header_in ('User-Agent') =~ /MSIE 5\.0/ or return draw_form_field_string (@_);
		
	$options -> {id} ||= '' . $options;
	
	$options -> {onClose}    ||= 'null';
	$options -> {onKeyDown}  ||= 'null';
	$options -> {onKeyPress} ||= 'if (window.event.keyCode != 27) is_dirty=true';

	$options -> {no_read_only} or $options -> {attributes} -> {readonly} = 1;
	
	my $attributes = dump_attributes ($options -> {attributes});
		
	my $shows_time = $options -> {no_time} ? 'false' : 'true';
		
	my $html = <<EOH;
		<nobr>
		<input 
			type="text" 
			name="$$options{name}" 
			$size 
			$attributes 
			autocomplete="off" 
			onFocus="scrollable_table_is_blocked = true; q_is_focused = true; this.select()" 
			onBlur="scrollable_table_is_blocked = false; q_is_focused = false" 
			onKeyPress="$$options{onKeyPress}" 
			onKeyDown="$$options{onKeyDown}"
		>
		<button id="calendar_trigger_$$options{id}" class="form-active-ellipsis">...</button>
EOH
	
	unless ($options -> {no_clear_button} || $options -> {no_read_only}) {
		$html .= qq{&nbsp;<button class="txt7" onClick="document.getElementById ('$options->{attributes}->{id}').value=''">X</button>};
	}
		
	$html .= <<EOH;
		</nobr>		
		<script type="text/javascript">
EOH

	if ($i18n -> {_calendar_lang} eq 'en') {
		$html .= <<EOJS;
			Calendar._DN = new Array ("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday");
			Calendar._SDN = new Array ("Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun");
			Calendar._MN = new Array ("January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December");
			Calendar._SMN = new Array ("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec");
			Calendar._TT = {};
			Calendar._TT["INFO"] = "About the calendar";
			Calendar._TT["PREV_YEAR"] = "Prev. year (hold for menu)";
			Calendar._TT["PREV_MONTH"] = "Prev. month (hold for menu)";
			Calendar._TT["GO_TODAY"] = "Go Today";
			Calendar._TT["NEXT_MONTH"] = "Next month (hold for menu)";
			Calendar._TT["NEXT_YEAR"] = "Next year (hold for menu)";
			Calendar._TT["SEL_DATE"] = "Select date";
			Calendar._TT["DRAG_TO_MOVE"] = "Drag to move";
			Calendar._TT["PART_TODAY"] = " (today)";
			Calendar._TT["MON_FIRST"] = "Display Monday first";
			Calendar._TT["SUN_FIRST"] = "Display Sunday first";
			Calendar._TT["CLOSE"] = "Close";
			Calendar._TT["TODAY"] = "Today";
			Calendar._TT["TIME_PART"] = "(Shift-)Click or drag to change value";
			Calendar._TT["DEF_DATE_FORMAT"] = "%Y-%m-%d";
			Calendar._TT["TT_DATE_FORMAT"] = "%a, %b %e";
			Calendar._TT["WK"] = "wk";
EOJS
	}	
	elsif ($i18n -> {_calendar_lang} eq 'fr') {
		$html .= <<EOJS;
			Calendar._DN = new Array ("Dimanche", "Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche");
			Calendar._MN = new Array ("Janvier", "Fйvrier", "Mars", "Avril", "Mai", "Juin", "Juillet", "Aoыt", "Septembre", "Octobre", "Novembre", "Dйcembre");
			Calendar._TT = {};
			Calendar._TT["TOGGLE"] = "Changer le premier jour de la semaine";
			Calendar._TT["PREV_YEAR"] = "Annйe prйc. (maintenir pour menu)";
			Calendar._TT["PREV_MONTH"] = "Mois prйc. (maintenir pour menu)";
			Calendar._TT["GO_TODAY"] = "Atteindre date du jour";
			Calendar._TT["NEXT_MONTH"] = "Mois suiv. (maintenir pour menu)";
			Calendar._TT["NEXT_YEAR"] = "Annйe suiv. (maintenir pour menu)";
			Calendar._TT["SEL_DATE"] = "Choisir une date";
			Calendar._TT["DRAG_TO_MOVE"] = "Dйplacer";
			Calendar._TT["PART_TODAY"] = " (Aujourd'hui)";
			Calendar._TT["MON_FIRST"] = "Commencer par lundi";
			Calendar._TT["SUN_FIRST"] = "Commencer par dimanche";
			Calendar._TT["CLOSE"] = "Fermer";
			Calendar._TT["TODAY"] = "Aujourd'hui";
			Calendar._TT["DEF_DATE_FORMAT"] = "y-mm-dd";
			Calendar._TT["TT_DATE_FORMAT"] = "D, M d";
			Calendar._TT["WK"] = "wk";
EOJS
	}	
	else {
		$html .= <<EOJS;
			Calendar._DN = new Array ("Воскресенье", "Понедельник", "Вторник", "Среда", "Четверг", "Пятница", "Суббота", "Воскресенье");
			Calendar._MN = new Array ("Январь", "Февраль", "Март", "Апрель", "Май", "Июнь", "Июль", "Август", "Сентябрь", "Октябрь", "Ноябрь", "Декабрь");
			Calendar._TT = {};
			Calendar._TT["TOGGLE"] = "Сменить день начала недели (ПН/ВС)";
			Calendar._TT["PREV_YEAR"] = "Пред. год (удерживать для меню)";
			Calendar._TT["PREV_MONTH"] = "Пред. месяц (удерживать для меню)";
			Calendar._TT["GO_TODAY"] = "На сегодня";
			Calendar._TT["NEXT_MONTH"] = "След. месяц (удерживать для меню)";
			Calendar._TT["NEXT_YEAR"] = "След. год (удерживать для меню)";
			Calendar._TT["SEL_DATE"] = "Выбрать дату";
			Calendar._TT["DRAG_TO_MOVE"] = "Перетащить";
			Calendar._TT["PART_TODAY"] = " (сегодня)";
			Calendar._TT["MON_FIRST"] = "Показать понедельник первым";
			Calendar._TT["SUN_FIRST"] = "Показать воскресенье первым";
			Calendar._TT["CLOSE"] = "Закрыть";
			Calendar._TT["TODAY"] = "Сегодня";
			Calendar._TT["DEF_DATE_FORMAT"] = "y-mm-dd";
			Calendar._TT["TT_DATE_FORMAT"] = "D, M d";
			Calendar._TT["WK"] = "нед"; 
EOJS
	}	

	$html .= <<EOH;
			Calendar.setup(
				{
					inputField : "input$$options{name}",
					ifFormat   : "$$options{format}",
					showsTime  : $shows_time,
					button     : "calendar_trigger_$$options{id}",
					onClose    : $$options{onClose}
				}
			);
		</script>

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
	
	
	$html .= $options -> {path};

	$html .= _draw_bottom (@_);
	
	$html .=  <<EOH;
		<table cellspacing=0 width="100%" style="border-style:solid; border-top-width: 1px; border-left-width: 1px; border-bottom-width: 0px; border-right-width: 0px; border-color: #d6d3ce;">
			<form 
				name="$$options{name}"
				target="$$options{target}"
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
		$html .= qq{<tr id="$tr_id">};
		foreach (@$row) { $html .= $_ -> {html} };
		$html .= qq{</tr>};
	}

	$html .=  '</form></table>';
	
	$html .= $options -> {bottom_toolbar};
	
	return $html;	

}


################################################################################

sub draw_path {

	my ($_SKIN, $options, $list) = @_;
	
	my $style = $options -> {nowrap} ? qq{style="background:url('/i/_skins/TurboMilk/bgr_grey.gif?$_REQUEST{__static_salt}');background-repeat:repeat-x;"} : '';
		
	my $path = <<EOH;
		<table cellspacing=0 cellpadding=0 width="100%" border=0>
			<tr>
				<td>
					<table cellspacing=0 cellpadding=0 width="100%" border=0>
						<tr>
							<td class="toolbar" $style>
								<img height=29 src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=1 border=0>
							</td>
							<td class="toolbar" $style $$options{nowrap}>&nbsp;
EOH

	if ($conf -> {core_show_icons} || $_REQUEST {__core_show_icons}) {
		$path .= qq{<img src="$_REQUEST{__static_url}/i_folder.gif?$_REQUEST{__static_salt}" border=0 hspace=3 vspace=1 align=absmiddle>&nbsp;};
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
						<tr>
							<td bgcolor="#e4e9ee" colspan=2><img height=1 src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=1 border=0></td>
						</tr>
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
				
	my $colspan     = $field -> {colspan}     ? 'colspan=' . $field -> {colspan}     : '';
	my $label_width = $field -> {label_width} ? 'width='   . $field -> {label_width} : '';	
	my $cell_width  = $field -> {cell_width}  ? 'width='   . $field -> {cell_width}  : '';
	
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
	return '<input type="text"' . dump_attributes ($options -> {attributes}) . ' onKeyPress="if (window.event.keyCode != 27) is_dirty=true" onKeyDown="tabOnEnter()" onFocus="scrollable_table_is_blocked = true; q_is_focused = true" onBlur="scrollable_table_is_blocked = false; q_is_focused = false">';
}

################################################################################

sub draw_form_field_datetime {

	my ($_SKIN, $options, $data) = @_;
		
	$options -> {attributes} -> {class} ||= 'form-active-inputs';	
	$options -> {name} = '_' . $options -> {name};
	$options -> {onKeyDown} ="tabOnEnter()";

	return $_SKIN -> _draw_input_datetime ($options);
	
}

################################################################################

sub draw_form_field_file {

	my ($_SKIN, $options, $data) = @_;	
		
	return <<EOH;
		<input 
			type="file"
			name="_$$options{name}"
			size=$$options{size}
			onFocus="scrollable_table_is_blocked = true; q_is_focused = true"
			onBlur="scrollable_table_is_blocked = false; q_is_focused = false"
			onChange="is_dirty=true; $$options{onChange}"
			tabindex=-1
		>
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
		<textarea 
			$attributes 
			onFocus="scrollable_table_is_blocked = true; q_is_focused = true" 
			onBlur="scrollable_table_is_blocked = false; q_is_focused = false" 
			rows=$$options{rows}
			cols=$$options{cols}
			name="_$$options{name}" 
			onchange="is_dirty=true;"
		>$$options{value}</textarea>
EOH

}

################################################################################

sub draw_form_field_password {
	my ($_SKIN, $options, $data) = @_;
	my $attributes = dump_attributes ($options -> {attributes});
	return qq {<input type="password" name="_$$options{name}" size="$$options{size}" onKeyPress="if (window.event.keyCode != 27) is_dirty=true" $attributes onKeyDown="tabOnEnter()" onFocus="scrollable_table_is_blocked = true; q_is_focused = true" onBlur="scrollable_table_is_blocked = false; q_is_focused = false">};
}

################################################################################

sub draw_form_field_static {
		
	my ($_SKIN, $options, $data) = @_;

	my $html = '';

	if ($options -> {href}) {
		my $state = $data -> {fake} == -1 ? 'deleted' : $_REQUEST {__read_only} ? 'passive' : 'active';
		$options -> {a_class} ||= "form-$state-inputs";
		$html = qq{<a href="$$options{href}" target="$$options{target}" class="$$options{a_class}">};
	}
	
	if (ref $options -> {value} eq ARRAY) {
	
		for (my $i = 0; $i < @{$options -> {value}}; $i++) {
			$html .= '<br>' if $i;
			$html .= $options -> {value} -> [$i] -> {label};
		}
		
	}
	else {
		$html .= ($options -> {value} || '&nbsp;');
	}
	
	
	if ($options -> {href}) {
		$html .= '</a>';
	}
	
	$html .= qq {<input type=hidden name="$$options{hidden_name}" value="$$options{hidden_value}">} if ($options -> {add_hidden});
	
	return $html;
	
}

################################################################################

sub draw_form_field_checkbox {

	my ($_SKIN, $options, $data) = @_;
	
	my $attributes = dump_attributes ($options -> {attributes});
	
	return qq {<input class=cbx type="checkbox" name="_$$options{name}" $attributes $checked value=1 onChange="is_dirty=true" onKeyDown="tabOnEnter()">};
	
}

################################################################################

sub draw_form_field_radio {

	my ($_SKIN, $options, $data) = @_;
				
	my $html = '<table border=0 cellspacing=2 cellpadding=0 width=100%>';
	
	foreach my $value (@{$options -> {values}}) {
	
		delete $value -> {attributes} -> {name};
		delete $value -> {attributes} -> {value};
		delete $value -> {attributes} -> {id};
	
		my $attributes = dump_attributes ($value -> {attributes});

		$html .= qq {\n<tr><td class="form-inner" valign=top width=1%><nobr><input class=cbx $attributes id="$value" onFocus="scrollable_table_is_blocked = true; q_is_focused = true" onBlur="scrollable_table_is_blocked = false; q_is_focused = false" type="radio" name="_$$options{name}" value="$$value{id}" onClick="is_dirty=true" onKeyDown="tabOnEnter()">&nbsp;$$value{label}</nobr>};
							
		$value -> {html} or next;
		
		$html .= qq{\n\t\t<td class="form-inner"><div style="display:expression(getElementById('$value').checked ? 'block' : 'none')">$$value{html}</div>};
				
	}
	
	$html .= '</table>';
		
	return $html;
	
}

################################################################################

sub draw_form_field_select {

	my ($_SKIN, $options, $data) = @_;
	
	my $attributes = dump_attributes ($options -> {attributes});
	
	my $html = <<EOH;
		<select 
			name="_$$options{name}"
			id="_$$options{name}_select"
			$attributes
			onKeyDown="tabOnEnter()"
			onChange="is_dirty=true; $$options{onChange}" 
			onKeyPress="typeAhead()" 
			style="visibility:expression(last_vert_menu [0] || subsets_are_visible ? 'hidden' : '')"
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
	}

	$html .= '</select>';

	if (defined $options -> {other}) {
		$html .= <<EOH;
			<div id="_$$options{name}_div" style="{position:absolute; display:none; width:expression(getElementById('_$$options{name}_select').offsetParent.offsetWidth - 10)}">
				<iframe name="_$$options{name}_iframe" id="_$$options{name}_iframe" width=100% height=${$$options{other}}{height} src="/i/0.html" application="yes">
				</iframe>
			</div>
EOH
	}

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
			my $subhtml = '';
			my $subattr = '';
			
			my $display = $checked || $options -> {expand_all} ? '' : 'style={display:none}';

			if ($value -> {html}) {
				$subhtml .= $value -> {inline} ? qq{&nbsp;<span id="$id" $display>} : qq{&nbsp;</td><td class="form-inner" id="$id" $display>};
				$subhtml .= $value -> {html};
				$subhtml .= $value -> {inline} ? qq{</span>} : '';
				$subattr = qq{onClick="setVisible('$id', checked)"} unless $options -> {expand_all};
			}
			elsif ($value -> {items} && @{$value -> {items}} > 0) {

				foreach my $subvalue (@{$value -> {items}}) {
									
					my $subchecked = 0 + (grep {$_ eq $subvalue -> {id}} @$v) ? 'checked' : '';
					
					$tabindex++;
					
					$subhtml .= qq {&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<input class=cbx type="checkbox" name="_$$options{name}_$$subvalue{id}" value="1" $subchecked onChange="is_dirty=true" tabindex=$tabindex>&nbsp;$$subvalue{label} <br>};
				
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

			$html .= qq {<td class="form-inner"><input $subattr class=cbx type="checkbox" name="_$$options{name}_$$value{id}" value="1" $checked onChange="is_dirty=true" tabindex=$tabindex>&nbsp;$$value{label} $subhtml</td>};
			$html .= '</tr><tr>' unless $n % $options -> {cols};
			
		}
		
		$html =~ s{\<tr\>$}{};		
		$html .= '</table>';
	
	}
	else {
	
		foreach my $value (@{$options -> {values}}) {
			my $checked = $v eq $value -> {id} ? 'checked' : '';
			$tabindex++;
			$html .= qq {<input class=cbx type="checkbox" name="_$$options{name}" value="$$value{id}" $checked onChange="is_dirty=true" tabindex=$tabindex>&nbsp;$$value{label} <br>};
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
		<input type="hidden" name="_$$options{name}" value="$$options{id_image}">
		<img src="$$options{src}" id="$$options{name}_preview" width = "$$options{width}" height = "$$options{height}">&nbsp;
		<input type="button" value="$$i18n{Select}" onClick="nope('$$options{new_image_url}', 'selectImage' , '');">
EOH

}

################################################################################

sub draw_form_field_iframe {
	
	my ($_SKIN, $options, $data) = @_;

	return <<EOH;
		<iframe name="$$options{name}" src="$$options{href}" width="$$options{width}" height="$$options{height}" application="yes"></iframe>
EOH

}

################################################################################

sub draw_form_field_color {
	
	my ($_SKIN, $options, $data) = @_;
	
	my $html = <<EOH;
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
				getElementById('td_color_$$options{name}').style.background = color;
				getElementById('input_color_$$options{name}').value = color.substr (1);
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
	
	my $html = <<EOH;
		<table bgcolor="b9c5d7" cellspacing=0 cellpadding=0 width="100%" border=0>
			<form action=$_REQUEST{__uri} name=$form_name target="$$options{target}">
EOH

	foreach (@{$options -> {keep_params}}) {
		$html .= qq{<input type="hidden" name="$_" value="$_REQUEST{$_}">}	
	}

	$html .= <<EOH;
					<input type=hidden name=sid value=$_REQUEST{sid}>
					<input type=hidden name=__last_query_string value="$_REQUEST{__last_query_string}">
					<input type=hidden name=__last_scrollable_table_row value="$_REQUEST{__last_scrollable_table_row}">
					<input type=hidden name=__last_last_query_string value="$_REQUEST{__last_last_query_string}">

				<tr>
					<td bgcolor="#6f7681" colspan=20><img height=1 src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=1 border=0></td>
				</tr>
				<tr>
					<td bgcolor="#949eac" colspan=20><img height=1 src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=1 border=0></td>
				</tr>
				<tr>
					<td bgcolor="#adb8c9" colspan=20><img height=1 src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=1 border=0></td>
				</tr>
				<tr>
					<td class="bgr0" width=30><img height=30 src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=20 border=0></td>
EOH

	foreach (@{$options -> {buttons}}) {	$html .= $_ -> {html};	}

	$html .= <<EOH;
					<td class="bgr0" width=100%><img height=1 src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=1 border=0></td>
				</tr>
				<tr>
					<td bgcolor="#c5d2df" colspan=20><img height=1 src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=1 border=0></td>
				</tr>
				<tr>
					<td bgcolor="#8c9ab1" colspan=20><img height=1 src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=1 border=0></td>
				</tr>
			</form>
		</table>
EOH

	return $html;

}

################################################################################

sub draw_toolbar_break {

	my ($_SKIN, $options) = @_;

	my $html = <<EOH;
					<td class="bgr0" width=100%><img height=1 src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=1 border=0></td>
				</tr>
				<tr>
					<td bgcolor="#c5d2df" colspan=20><img height=1 src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=1 border=0></td>
				</tr>
				<tr>
					<td bgcolor="#8c9ab1" colspan=20><img height=1 src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=1 border=0></td>
				</tr>
EOH
	
	if ($options -> {break_table}) {		
		$html .= '</table><table bgcolor="b9c5d7" cellspacing=0 cellpadding=0 width="100%" border=0>';		
	}

	$html .= <<EOH;
				<tr>
					<td bgcolor="#6f7681" colspan=20><img height=1 src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=1 border=0></td>
				</tr>
				<tr>
					<td bgcolor="#949eac" colspan=20><img height=1 src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=1 border=0></td>
				</tr>
				<tr>
					<td bgcolor="#adb8c9" colspan=20><img height=1 src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=1 border=0></td>
				</tr>
				<tr>
					<td class="bgr0" width=30><img height=30 src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=20 border=0></td>
EOH

	return $html;

}

################################################################################

sub _icon_path {

	-r $r -> document_root . "/i/_skins/TurboMilk/i_$_[0].gif" ?
	"$_REQUEST{__static_url}/i_$_[0].gif?$_REQUEST{__static_salt}" :
	"/i/buttons/$_[0].gif"			

}

################################################################################

sub draw_toolbar_button {

	my ($_SKIN, $options) = @_;
	my $html = <<EOH;
		<td>
		<table cellspacing=0 cellpadding=0 border=0 valign="middle">
		<tr>
			<td class="bgr0" width=6><img src="$_REQUEST{__static_url}/btn2_l.gif?$_REQUEST{__static_salt}" width="6" height="21" border="0"></td>
			<td class="bgr0" style="background-repeat:repeat-x" background="$_REQUEST{__static_url}/btn2_bg.gif?$_REQUEST{__static_salt}" valign="middle" align="center" nowrap><nobr>&nbsp;<a TABINDEX=-1 class=button href="$$options{href}" $onclick id="$$options{id}" target="$$options{target}">
EOH

	if ($options -> {icon}) {
		my $img_path = _icon_path ($options -> {icon});
		$html .= qq {<img src="$img_path" alt="$label" border=0 hspace=0 align=absmiddle>&nbsp;};
	}
	
	$html .= <<EOH;
			</a>
			</nobr></td>
			<td class="bgr0" style="background-repeat:repeat-x" background="$_REQUEST{__static_url}/btn2_bg.gif?$_REQUEST{__static_salt}" valign="middle" align="center" nowrap><nobr>&nbsp;<a TABINDEX=-1 class=button href="$$options{href}" $onclick id="$$options{id}" target="$$options{target}">
				$options->{label}
				</a>
			</nobr></td>
			<td width=6><img src="$_REQUEST{__static_url}/btn2_r.gif?$_REQUEST{__static_salt}" width="6" height="21" border="0"></td>
		</tr>
		</table>
		</td>

EOH

	$html .= "<td class='toolbar'>&nbsp;&nbsp;&nbsp;</td>";

	return $html;
	
}

################################################################################

sub draw_toolbar_input_select {

	my ($_SKIN, $options) = @_;

	my $html = '<td class="toolbar" nowrap>';
		
	if ($options -> {label} && $options -> {show_label}) {
		$html .= $options -> {label};
		$html .= ': ';
	}
	
	$html .= <<EOH;
		<select name="$$options{name}" onChange="$$options{onChange}" onkeypress="typeAhead()" style="visibility:expression(last_vert_menu [0] || subsets_are_visible ? 'hidden' : '')">
EOH

	if (defined $options -> {empty}) {
		$html .= q {<option value=0>};
		$html .= $options -> {empty};
		$html .= q {</option>};
	}

	foreach my $value (@{$options -> {values}}) {		
		$html .= qq {<option value="$$value{id}" $$value{selected}>$$value{label}</option>};
	}

	$html .= '</select></td><td class="toolbar">&nbsp;&nbsp;&nbsp;</td>';

	return $html;
	
}

################################################################################

sub draw_toolbar_input_checkbox {

	my ($_SKIN, $options) = @_;
	
	my $html = '<td class="toolbar" nowrap>';
		
	if ($options -> {label}) {
		$html .= $options -> {label};
		$html .= ': ';
	}

	$html .= qq {<input class=cbx type=checkbox value=1 $$options{checked} name="$$options{name}" onClick="submit()">};

	$html .= "<td class='toolbar'>&nbsp;&nbsp;&nbsp;</td>";
	
	return $html;

}

################################################################################

sub draw_toolbar_input_submit {

	my ($_SKIN, $options) = @_;

	my $html = '<td class="toolbar" nowrap>';
		
	if ($options -> {label}) {
		$html .= $options -> {label};
		$html .= ': ';
	}

	$html .= qq {<input type=submit name="$$options{name}" value="$$options{label}">};

	$html .= "<td class='toolbar'>&nbsp;&nbsp;&nbsp;</td>";
	
	return $html;

}

################################################################################

sub draw_toolbar_input_text {

	my ($_SKIN, $options) = @_;
	
	my $html = '<td nowrap class="toolbar" valign="middle">';
		
	if ($options -> {label}) {
		$html .= $options -> {label};
		$html .= ': ';
	}

	$html .= <<EOH;
		<input 
			onKeyPress="if (window.event.keyCode == 13) {form.submit()}" 
			type=text 
			size=$$options{size} 
			name=$$options{name} 
			value="$$options{value}" 
			onFocus="scrollable_table_is_blocked = true; q_is_focused = true" 
			onBlur="scrollable_table_is_blocked = false; q_is_focused = false"
			style="visibility:expression(last_vert_menu [0] || subsets_are_visible ? 'hidden' : '')"
			class='form-active-inputs'
			id="$options->{id}"
		>
EOH

	foreach my $key (@{$options -> {keep_params}}) {
		next if $key eq $options -> {name} or $key =~ /^_/ or $key eq 'start' or $key eq 'sid';
		$html .= qq {<input type=hidden name=$key value="$_REQUEST{$key}">};
	}

	$html .= "</td><td class='toolbar'>&nbsp;&nbsp;&nbsp;</td>";

	return $html;

}

################################################################################

sub draw_toolbar_input_datetime {

	my ($_SKIN, $options) = @_;

	$options -> {onClose}    = "function (cal) { cal.hide (); $$options{onClose}; cal.params.inputField.form.submit () }";	
	$options -> {onKeyPress} = "if (window.event.keyCode == 13) {this.form.submit()}";

	my $html = '<td class="toolbar" nowrap>';
		
	if ($options -> {label}) {
		$html .= $options -> {label};
		$html .= ': ';
	}

	$html .= $_SKIN -> _draw_input_datetime ($options);

	$html .= "<td class='toolbar'>&nbsp;&nbsp;&nbsp;</td>";

	return $html;

}

################################################################################

sub draw_toolbar_pager {

	my ($_SKIN, $options) = @_;
		
	my $html = '<td><table cellspacing=2 cellpadding=0><tr>';
	
	if ($options -> {total}) {

		if ($options -> {rewind_url}) {
			$html .= qq {<td nowrap valign="middle"><a TABINDEX=-1 href="$$options{rewind_url}" class=lnk0 onFocus="blur()"><img src="$_REQUEST{__static_url}/pager_f.gif?$_REQUEST{__static_salt}" width="16" height="17" border="0"></a></td>};
		}

		if ($options -> {back_url}) {
			$html .= qq {<td nowrap valign="middle"><a TABINDEX=-1 href="$$options{back_url}" class=lnk0 id="_pager_prev" onFocus="blur()"><img src="$_REQUEST{__static_url}/pager_p.gif?$_REQUEST{__static_salt}" width="16" height="17" border="0"></a></td>};
		}
		
		$html .= '<td nowrap class="toolbar" valign="middle">&nbsp;' . ($options -> {start} + 1);
		$html .= ' - ';
		$html .= ($options -> {start} + $options -> {cnt});
		$html .= qq |$$i18n{toolbar_pager_of}<a TABINDEX=-1 class=lnk0 href="$$options{infty_url}">$$options{infty_label}</a>|;
		$html .= '&nbsp;</td>';
		if ($options -> {next_url}) {
			$html .= qq {<td  nowrap valign="middle"><a TABINDEX=-1 href="$$options{next_url}" class=lnk0 id="_pager_next" onFocus="blur()"><img src="$_REQUEST{__static_url}/pager_n.gif?$_REQUEST{__static_salt}" width="16" height="17" border="0"></a></td>};
		}

	}
	else {	
		$html .= '<td nowrap class="toolbar">' . $i18n -> {toolbar_pager_empty_list} . '</td>';	
	}
	
	$html .= "</tr></table></td><td class='toolbar'>&nbsp;&nbsp;&nbsp;</td>";

	return $html;

}

################################################################################

sub draw_centered_toolbar_button {

	my ($_SKIN, $options) = @_;

	my $img_path = "$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}";

	if ($options -> {icon}) {
		$img_path = _icon_path ($options -> {icon});
	}

	return <<EOH;
		<td nowrap background="$_REQUEST{__static_url}/cnt_tbr_bg.gif?$_REQUEST{__static_salt}">
			<table cellspacing="0" cellpadding="0" border="0">
				<tr>
					<td width=6><img src="$_REQUEST{__static_url}/btn_l.gif?$_REQUEST{__static_salt}" width="6" height="25" border="0"></td>
					<td width=30 background="$_REQUEST{__static_url}/btn_bg.gif?$_REQUEST{__static_salt}" valign="middle" align="center" nowrap><a class="button" href="$$options{href}" id="$$options{id}" target="$$options{target}"><img src="$img_path" alt="$$options{label}" border=0 hspace=0 vspace=1 align=absmiddle>&nbsp;</a></td>
					<td background="$_REQUEST{__static_url}/btn_bg.gif?$_REQUEST{__static_salt}" valign="absmiddle" align="center" nowrap><a class="button" href="$$options{href}" id="$$options{id}" target="$$options{target}">$$options{label}</a>&nbsp;&nbsp;</td>
					<td width=6><img src="$_REQUEST{__static_url}/btn_r.gif?$_REQUEST{__static_salt}" width="6" height="25" border="0"></td>
				</tr>
			</table>
		</td>
		<td background="$_REQUEST{__static_url}/cnt_tbr_bg.gif?$_REQUEST{__static_salt}"><img height=40 hspace=0 src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=10 border=0></td>


EOH


}

################################################################################

sub draw_centered_toolbar {

	my ($_SKIN, $options, $list) = @_;

	our $__last_centered_toolbar_id = 'toolbar_' . int $list;
	
	my $colspan = 3 * (1 + $options -> {cnt}) + 1;

	my $html = <<EOH;
		<table cellspacing=0 cellpadding=0 width="100%" border=0 id="$__last_centered_toolbar_id">
			<tr>
				<td>
					<table cellspacing=0 cellpadding=0 width="100%" border=0>
						<tr>
							<td colspan=$colspan><img height=3 src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=1 border=0></td>
						</tr>
						<tr>
							<td width="45%">
								<table cellspacing=0 cellpadding=0 width="100%" border=0>
									<tr>
										<td background="$_REQUEST{__static_url}/cnt_tbr_bg.gif?$_REQUEST{__static_salt}"><img height=40 hspace=0 src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=1 border=0></td>
									</tr>
								</table>
							</td>
EOH

	foreach (@$list) {
		$html .= $_ -> {html};
	}

	$html .= <<EOH;
									<td width="45%">
										<table cellspacing=0 cellpadding=0 width="100%" border=0>
											<tr>
												<td background="$_REQUEST{__static_url}/cnt_tbr_bg.gif?$_REQUEST{__static_salt}"><img height=40 hspace=0 src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=1 border=0></td>
											</tr>
										</table>
									</td>
								</tr>
							</td>
						</tr>
					</table>
				</td>
			</tr>
		</table>
	
EOH
	
	return $html;

}

################################################################################
# MENUS
################################################################################

################################################################################

sub draw_menu {

	my ($_SKIN, $_options) = @_;
	
	my @types = (@{$_options -> {left_items}}, BREAK, @{$_options -> {right_items}});
	
	my $colspan = 1 + @types;

	my $html = <<EOH;

	<div style="position: relative">

		<table width="100%" class=bgr8 cellspacing=0 cellpadding=0 border=0>
			<tr>
				<td background="$_REQUEST{__static_url}/menu_bg.gif?$_REQUEST{__static_salt}" width=1><img height=26 src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=1 border=0></td>
				<td background="$_REQUEST{__static_url}/menu_bg_s.gif?$_REQUEST{__static_salt}" width=0><img height=26 src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=0 border=0></td>
EOH

	foreach my $type (@types) {

		next if ($type -> {name} eq '_logout');

		if ($type eq BREAK) {
			$html .= qq{<td background="$_REQUEST{__static_url}/menu_bg.gif?$_REQUEST{__static_salt}" width=100%><img height=1 src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=1 border=0></td>};
			next;
		}
		
		$html .= <<EOH;
			<td onmouseover="$$type{onhover}" onmouseout="$$type{onmouseout}" class="main-menu" nowrap>&nbsp;
				<a class="main-menu" id="main_menu_$$type{name}" target="$$type{target}" href="$$type{href}" tabindex=-1>&nbsp;$$type{label}&nbsp;</a>&nbsp;
			</td>
EOH
			
	}

	$html .= <<EOH;
		</table>
EOH

	foreach my $type (@types) {
		$html .= $type -> {vert_menu};
	}

	$html .= <<EOH;
	</div>
EOH

	return $html;
	
}

################################################################################

sub draw_vert_menu {

	my ($_SKIN, $name, $types, $level) = @_;
		
	my $html = <<EOH;
		<div id="vert_menu_$name" style="display:none; position:absolute; z-index:100">
			<table id="vert_menu_table_$name" width=1 bgcolor=#454a7c cellspacing=0 cellpadding=0 border=0 border=1>
EOH


	foreach my $type (@$types) {
	
		if ($type eq BREAK) {

			$html .= <<EOH;
				<tr height=2>

					<td bgcolor=#5d6496 width=1><img height=2 src=$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt} width=1 border=0></td>
					<td bgcolor=#5d6496 width=1><img height=2 src=$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt} width=1 border=0></td>

					<td>
						<table width=90% border=0 cellspacing=0 cellpadding=0 align=center minheight=2>
							<tr height=1><td bgcolor="#888888"><img height=1 src=$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt} width=1 border=0></td></tr>
							<tr height=1><td bgcolor="#ffffff"><img height=1 src=$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt} width=1 border=0></td></tr>
						</table>
					</td>
				</tr>
EOH
		}
		else {
			my $td = $type -> {items} ? <<EOH : qq{<td nowrap onclick="$$type{onclick}" onmouseover="$$type{onhover}" onmouseout="$$type{onmouseout}" class="vert-menu">&nbsp;&nbsp;$$type{label}&nbsp;&nbsp;</td>};
				<td nowrap onclick="$$type{onclick}" class="vert-menu" onmouseover="$$type{onhover}" onmouseout="$$type{onmouseout}">
						<table width="100%" cellspacing=0 cellpadding=0 border=0><tr>
							<td align="left" nowrap style="font-family: Tahoma, 'MS Sans Serif'; font-weight: normal; font-size: 8pt; color: #ffffff;">&nbsp;&nbsp;$$type{label}&nbsp;&nbsp;</td>
							<td align="right" style="font-family: Marlett; font-weight: normal; font-size: 8pt; color: #ffffff;">8</td>
						</tr></table>
				</td>
EOH
			$html .= <<EOH;
					<tr>
						<td width=1 bgcolor=#5d6496><img height=1 src=/0.gif width=1 border=0></td>
						<td width=1 bgcolor=#5d6496><img height=1 src=/0.gif width=1 border=0></td>
					$td
				</tr>
EOH
		
		}
	
	}

	$html .= <<EOH;
			</table>
EOH

	foreach my $type (@$types) {
		$html .= $type -> {vert_menu};
	}

	$html .= <<EOH;
		</div>
EOH
	return $html;

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
	$html .= dump_attributes ($data -> {attributes}) if $data -> {attributes};
	$html .= '>';
	
	unless ($data -> {off}) {
	
		$data -> {label} =~ s{^\s+}{};
		$data -> {label} =~ s{\s+$}{};

		$html .= qq {<img src='/i/_skins/TurboMilk/status_$data->{status}->{icon}.gif' border=0 alt='$data->{status}->{label}' align=absmiddle hspace=5>} if $data -> {status};

		$html .= '<nobr>' unless $data -> {no_nobr};

		$html .= '&nbsp; ';		

		$html .= '<b>'      if $data -> {bold}   || $options -> {bold};
		$html .= '<i>'      if $data -> {italic} || $options -> {italic};
		$html .= '<strike>' if $data -> {strike} || $options -> {strike};

		$html .= qq {<a id="$$data{a_id}" class=$$data{a_class} target="$$data{target}" href="$$data{href}" onFocus="blur()">} if $data -> {href};

		$html .= $data -> {label};
		
		$html .= '</a>' if $data -> {href};

		$html .= '&nbsp;';		
		
		$html .= '</nobr>' unless $data -> {no_nobr};
		
		
	} else {
		$html .= '&nbsp;';
	}
	
	$html .= '</td>';

	return $html;

}

################################################################################

sub draw_radio_cell {

	my ($_SKIN, $data, $options) = @_;

	my $attributes = dump_attributes ($data -> {attributes});

	return qq {<td $$options{data} $attributes><input class=cbx type=radio name=$$data{name} $$data{checked} value='$$data{value}'></td>};

}

################################################################################

sub draw_checkbox_cell {

	my ($_SKIN, $data, $options) = @_;

	my $attributes = dump_attributes ($data -> {attributes});

	return qq {<td $$options{data} $attributes><input class=cbx type=checkbox name=$$data{name} $$data{checked} value='$$data{value}'></td>};

}

################################################################################

sub draw_select_cell {

	my ($_SKIN, $data, $options) = @_;

	my $attributes = dump_attributes ($data -> {attributes});

	my $multiple = $data -> {rows} > 1 ? "multiple size=$$data{rows}" : '';
	my $html = qq {<td $attributes><nobr><select name="$$data{name}" onChange="is_dirty=true; $$options{onChange}" onkeypress="typeAhead()" $multiple>};

	$html .= qq {<option value="0">$$data{empty}</option>\n} if defined $data -> {empty};

	foreach my $value (@{$data -> {values}}) {
		$html .= qq {<option value="$$value{id}" $$value{selected}>$$value{label}</option>\n};
	}
	
	$html .= qq {</select></nobr></td>};
	
	return $html;

}

################################################################################

sub draw_input_cell {

	my ($_SKIN, $data, $options) = @_;

	my $attributes = dump_attributes ($data -> {attributes});

	return qq {<td $$data{title} $attributes><nobr><input onFocus="q_is_focused = true; left_right_blocked = true;" onBlur="q_is_focused = false; left_right_blocked = false;" type="text" name="$$data{name}" value="$$data{label}" maxlength="$$data{max_len}" size="$$data{size}"></nobr></td>};

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

		$options -> {label} = qq|&nbsp;<img src="$img_path" alt="$$options{label}" border=0 hspace=0 vspace=0 align=absmiddle>&nbsp;|;
		$options -> {label} .= "&nbsp;$label" if $options -> {force_label} || $conf -> {core_hide_row_buttons} > -1;
		
	}
	else {
		$options -> {label} = "\&nbsp;[$$options{label}]\&nbsp;";
	}
	
	my $vert_line = {label => $options -> {label}, href => $options -> {href}};
	$vert_line -> {label} =~ s{[\[\]]}{}g;
	push @{$_SKIN -> {__current_row} -> {__types}}, $vert_line;
		
	if ($conf -> {core_hide_row_buttons} == 2) {
		return '';
	}
	elsif ($conf -> {core_hide_row_buttons} == 1) {
		return $_SKIN -> draw_text_cell ({label => '&nbsp;'});
	}
	else {
		return qq {<td $$options{title} class="row-button" valign=top nowrap width="1%"><a TABINDEX=-1 class="row-button" href="$$options{href}" target="$$options{target}">$$options{label}</a></td>};
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
	
	return "<th $attributes $$cell{title}>\&nbsp;$$cell{label}\&nbsp;</th>";

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
				<form name=$$options{name} action=$_REQUEST{__uri} method=post enctype=multipart/form-data target=invisible>
					<input type=hidden name=type value=$$options{type}>
					<input type=hidden name=action value=$$options{action}>
					<input type=hidden name=sid value=$_REQUEST{sid}>
					<input type=hidden name=__last_query_string value="$_REQUEST{__last_last_query_string}">
					<input type=hidden name=__last_scrollable_table_row value="$_REQUEST{__last_scrollable_table_row}">
EOH

	foreach my $key (keys %_REQUEST) {
		next if $key =~ /^_/ or $key =~/^(type|action|sid|__last_query_string)$/;
		$html .= qq {<input type=hidden name=$key value="$_REQUEST{$key}">\n};
	}

	$html .= qq {<td class=bgr8><div class="table-container" style="height: expression(actual_table_height(this,$$options{min_height},$$options{height},'$__last_centered_toolbar_id'));"><table cellspacing=0 cellpadding=0 width="100%" id="scrollable_table" lpt=$$options{lpt}>\n};

	$html .= $options -> {header} if $options -> {header};

	$html .= qq {<tbody>\n};

	if ($options -> {dotdot}) {
		$html .= $options -> {dotdot};
	}

	my $menus = '';

	foreach our $i (@$list) {
		
		foreach my $tr (@{$i -> {__trs}}) {
			
			
			$html .= "<tr id='$$i{__tr_id}'";
			
			if (@{$i -> {__types}} && $conf -> {core_hide_row_buttons} > -1 && !$_REQUEST {lpt}) {
				$menus .= $i -> {__menu};
				$html  .= qq{ oncontextmenu="open_popup_menu('$i'); blockEvent ();"};
			}

			$html .= '>';
			$html .= $tr;
			$html .= '</tr>';
			
		}
		
	}

	$html .= <<EOH;
			</tbody></table></div>$$options{toolbar}</td></form></tr></table>
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
				<form name=form action=$_REQUEST{__uri} method=post enctype=multipart/form-data target=invisible>
					<tr><td class=bgr8>$body</td></tr>
				</form>
		</table>
EOH

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

		return <<EOH;
		<body onLoad="main()">
			<script>
				function main () {
				
					var element = window.parent.document.forms ['$_REQUEST{__only_form}'].elements ['_$_REQUEST{__only_field}'];
					var html = "$page->{body}";
					
					if (element) {
						element.outerHTML = html;
						element.tabIndex = "$_REQUEST{__only_tabindex}";
					}
					else {
						element = window.parent.document.getElementById ('input_$_REQUEST{__only_field}');
						element.outerHTML = html;
					}
					
				}
			</script>
		</body>
EOH
	}
		
	$_REQUEST {__scrollable_table_row} ||= 0;
	
	my $meta_refresh = $_REQUEST {__meta_refresh} ? qq{<META HTTP-EQUIV=Refresh CONTENT="$_REQUEST{__meta_refresh}; URL=@{[create_url()]}&__no_focus=1">} : '';	
	
	my $request_package = ref $apr;
	my $mod_perl = $ENV {MOD_PERL};
	$mod_perl ||= 'NO mod_perl AT ALL';
	
	my $timeout = 1000 * (60 * $conf -> {session_timeout} - 1);
	
	$_REQUEST {__select_rows} += 0;
							
	my $parameters = ${$_PACKAGE . 'apr'} -> parms;
  
	my $body = '';
	my $onKeyDown = '';	
	my $body_scroll = 'yes';
	
	if (!$_USER -> {id}) {
		
		$body = $page -> {body};
		$body_scroll = 'no';
		$$page{auth_toolbar} = '';
		
	}
	elsif (($parameters -> {__subset} || $parameters -> {type}) && !$_REQUEST {__top}) {
	
		$$page{auth_toolbar} = '';
		
		$body = $page -> {menu} . $page -> {body};
		
		my %h = %$parameters;
		delete $h {salt};
		delete $h {_salt};
		
		my $href = create_url (%h);

		$_REQUEST {__on_load} .= <<EOJS;
		
			if (window.top == window) { window.location = '$href&__top=1'}
			
EOJS
		
		$onKeyDown = <<EOJS;
		
			if (window.event.keyCode == 88 && window.event.altKey) {
				window.parent.document.location.href = '$_REQUEST{__uri}?type=_logout&sid=$_REQUEST{sid}&salt=@{[rand]}';
				blockEvent ();
			}
			
			if (window.event.keyCode == 116 && !window.event.altKey && !window.event.ctrlKey) {
			
				if (is_dirty) {
				
					if (!confirm ('Внимание! Вы изменили содержимое некоторых полей ввода. Перезагрузка страницы приведёт к утере этой информации. Продолжить?')) return blockEvent ();
				
				}
			
				window.location = '$href';
				return blockEvent ();
			}
			
			handle_basic_navigation_keys ();
			
EOJS
		
		foreach (@{$page -> {scan2names}}) {

			$onKeyDown .= &{"handle_hotkey_$$_{type}"} ($_);
			$onKeyDown .= ';';

		}

		$onKeyDown .= <<EOJS;
		
			if (window.event.keyCode == 115 && !window.event.altKey && !window.event.ctrlKey) {
				return blockEvent ();
			}
			
EOJS

	}
	else {
	
		my $href = create_url (__subset => $_SUBSET -> {name});
		$body_scroll = 'no';
		$_REQUEST {__no_focus} = 1;
		
		$body = <<EOIFRAME;
			<iframe name='_body_iframe' id='_body_iframe' src="$href" width=100% height=100% border=0 frameborder=0 marginheight=0 marginwidth=0>
			</iframe>
EOIFRAME

	}
	
	if ($$page{auth_toolbar}) {
		$$page{auth_toolbar} = "<tr height=48><td height=48>$$page{auth_toolbar}</td></tr>";
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
					var scrollable_table = null;
					var scrollable_table_row = 0;
					var scrollable_table_row_id = 0;
					var scrollable_table_row = 0;
					var scrollable_table_row_length = 0;
					var scrollable_table_row_cell_old_style = '';
					var is_dirty = false;					
					var scrollable_table_is_blocked = false;
					var q_is_focused = false;					
					var left_right_blocked = false;					
					var scrollable_rows = new Array();		
					var td2sr = new Array ();
					var td2sc = new Array ();
					var last_vert_menu = new Array ();
					var ms_word = null;
					var subsets_are_visible = 0;
					var clockID = 0;
					var clockSeparators = new Array ('$_REQUEST{__clock_separator}', ' ');
					var clockSeparatorID = 0;
					
					function td_on_click () {
						var uid = window.event.srcElement.uniqueID;
						var new_scrollable_table_row = td2sr [uid];
						var new_scrollable_table_row_cell = td2sc [uid];
						if (new_scrollable_table_row == null || new_scrollable_table_row_cell == null) return;
						scrollable_rows [scrollable_table_row].cells [scrollable_table_row_cell].className = scrollable_table_row_cell_old_style;
						scrollable_table_row = new_scrollable_table_row;
						scrollable_table_row_cell = new_scrollable_table_row_cell;
						scrollable_table_row_cell_old_style = scrollable_rows [scrollable_table_row].cells [scrollable_table_row_cell].className;
						scrollable_rows [scrollable_table_row].cells [scrollable_table_row_cell].className += ' row-cell-hilite';
						focus_on_first_input (scrollable_rows [scrollable_table_row].cells [scrollable_table_row_cell]);
						return false;
					}
					
					
					function body_on_load () {

						@{[ $_REQUEST{__no_focus} ? '' : 'window.focus ();' ]}

						@{[ $_REQUEST{sid} ? <<EOK : '' ]}
							keepaliveID = setTimeout ("open('$_REQUEST{__uri}?keepalive=$_REQUEST{sid}', 'invisible'); clearTimeout (keepaliveID)", $timeout);
EOK

						$_REQUEST{__doc_on_load}

						if (!document.body.getElementsByTagName) return;

						var tables = document.body.getElementsByTagName ('table');

						if (tables != null) {										
							for (var i = 0; i < tables.length; i++) {

								if (tables [i].id != 'scrollable_table') continue;

								var rows = tables [i].tBodies (0).rows;

								for (var j = 0; j < rows.length; j++) {
									scrollable_rows = scrollable_rows.concat (rows [j]);
								}
							}					
						}

						for (var i = 0; i < scrollable_rows.length; i++) {

							var cells = scrollable_rows [i].cells;
							for (var j = 0; j < cells.length; j++) {
								var scrollable_cell = cells [j];
								td2sr [scrollable_cell.uniqueID] = i;
								td2sc [scrollable_cell.uniqueID] = j;
								scrollable_cell.onclick = td_on_click;
								scrollable_cell.oncontextmenu = td_on_click;
							}
						}

						scrollable_table = document.getElementById ('scrollable_table');

						if (scrollable_table) {				

							scrollable_table = scrollable_table.tBodies (0);

							scrollable_table_row = $_REQUEST{__scrollable_table_row};
							scrollable_table_row_cell = 0;

							if (scrollable_rows.length > 0) {
								var cell = cell_on ();
								if (scrollable_table_row > 0) scrollCellToVisibleTop (cell);
							}
							else {
								scrollable_table = null;
							}

						}

						var focused_inputs = document.getElementsByName ('$_REQUEST{__focused_input}');

						if (focused_inputs != null && focused_inputs.length > 0) {
							var focused_input = focused_inputs [0];
							focused_input.focus ();
							if (focused_input.type == 'radio') {
								focused_input.select ();
							}
						}
						else {	

							var forms = document.forms;
							if (forms != null) {

								var done = 0;

								for (var i = 0; i < forms.length; i++) {

									var elements = forms [i].elements;

									if (elements != null) {

										for (var j = 0; j < elements.length; j++) {

											var element = elements [j];

											if (element.tagName == 'INPUT' && element.name == 'q') {
												break;
											}

											if (
												   (element.tagName == 'INPUT'  && (element.type == 'text' || element.type == 'checkbox' || element.type == 'radio'))
												||  element.tagName == 'TEXTAREA') 
											{
												element.focus ();
												done = 1;
												break;
											}										

										}									

									}

									if (done) {
										break;
									}

								}

							}

						}

						@{[ $_REQUEST {__blur_all} ? <<EOF : '']}

						if (inputs != null) {										
							for (var i = 0; i < inputs.length; i++) {
								inputs [i].blur ();
							}					
						}

EOF

						$_REQUEST{__on_load}
					
					}
					
          function subset_on_change (subset_name, href) {
          
            var subset_tr_id = '_subset_tr_' + subset_name;
            var subset_a_id = '_subset_a_' + subset_name;

            var subset_tr = document.getElementById(subset_tr_id);

            var subset_table = subset_tr.parentElement;
            
            for (var i = 0; i < subset_table.rows.length; i++) {
              subset_table.rows(i).style.display = '';
            }

            subset_tr.style.display = 'none';

            var subset_label_div = document.getElementById('admin');

            var label = document.getElementById(subset_a_id).innerHTML; 

            var subset_label = document.createTextNode(label);
            
            var subset_label_a = document.createElement("A");

            subset_label_a.appendChild(subset_label);

            subset_label_a.href = '#';

            subset_label_div.replaceChild(subset_label_a, subset_label_div.firstChild);

            var fname = document.getElementById('_body_iframe');
            fname.src = href;
            
            subsets_are_visible = 1 - subsets_are_visible;

            document.getElementById ("_body_iframe").contentWindow.subsets_are_visible = subsets_are_visible;
          
          }

					
				
					$_REQUEST{__script}
				
				</script>
				
				@{[ $_REQUEST{__help_url} ? <<EOHELP : '' ]}
					<script for="body" event="onhelp">
						nope ('$_REQUEST{__help_url}', '_blank', 'toolbar=no,resizable=yes');
						event.returnValue = false;
					</script>						
EOHELP

			</head>
			<body 
				bgcolor=white 
				leftMargin=0 
				topMargin=0
				bottomMargin=0
				rightMargin=0
				marginwidth=0 
				marginheight=0 
				scroll=$body_scroll
				name="body" 
				id="body"
				scroll="auto"
				onload= "body_on_load (); try {StartClock ()} catch (e) {}"
				onbeforeunload="document.body.style.cursor = 'wait'"
				onunload=" try {KillClock ()} catch (e) {}"
				onkeydown="$onKeyDown"						
			>
				
				<table id="body_table" cellspacing=0 cellpadding=0 border=0 width=100% height=100%>
					$$page{auth_toolbar}
					<tr><td valign=top height=100%>
						$body
					</td></tr>
				</table>

@{[ map {<<EOI} @{$_REQUEST{__invisibles}} ]}
					<iframe name='$_' src="/i/0.html" width=0 height=0 application="yes" style="display:none">
					</iframe>
EOI

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
			return blockEvent ();
		}
EOJS

}

################################################################################

sub handle_hotkey_focus_id {

	my ($r) = @_;

	my $ctrl = $r -> {ctrl} ? '' : '!';
	my $alt  = $r -> {alt}  ? '' : '!';

	<<EOJS
		if (window.event.keyCode == $$r{code} && $alt window.event.altKey && $ctrl window.event.ctrlKey) {
			document.getElementById('$r->{data}').focus ();
			return blockEvent ();
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
					nope ('$$r{href}&__from_table=1&salt=' + Math.random () + '&' + scrollable_rows [scrollable_table_row].id, '_self');
				}
				return blockEvent ();
			}
EOJS

	}
	else {
		
		return <<EOJS
			if (window.event.keyCode == $$r{code} && $alt window.event.altKey && $ctrl window.event.ctrlKey) {
				if ($condition) {
					var a = document.getElementById ('$$r{data}');
					activate_link (a.href, a.target);
				}
				return blockEvent ();
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
	my $label = $_[1] ? 'Ошибка' : 'ОК';
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

################################################################################

sub draw_logon_form {

	return <<EOH;

<table border="0" cellpadding="0" cellspacing="0" align=center height=100% width=100%>

	<tr>

		<td valign=top height=90>
			<table id="logo_table" cellSpacing=0 cellPadding=0 width="100%" border=0 bgcolor="#e5e5e5" background="/i/bg_logo_out.gif" style="background-repeat: repeat-x" height=90>
				<tr>
				<td width="20"><img src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=20 height=90 border=0></td>
				<td width=1><table border=0 valign="middle" border=0><tr>
					<td valign="top" width=1><img src="/i/logo_out.gif" border="0"></td>
					<td width=1><img src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=10 height=1 border=0></td>
					<td width=1 valign="bottom" style='padding-bottom: 5px;'><img src="$_REQUEST{__static_url}/gsep.gif?$_REQUEST{__static_salt}" width="4" height="21"></td>
					<td align="left" valign="middle" class='header_0' width=1><nobr>&nbsp;$$conf{page_title}</nobr></td>
				</tr></table></td>				
				
				<td width="20px" align="right">&nbsp;</td></tr>
			</table>

		</td>

	</tr>
	
	<tr>
	
		<td align=center valign=middle>

			<table border="0" cellpadding="4" cellspacing="1" width="470" height="225" bgcolor="#EAEAF0" class="logon">
				<tr><td class="login-head">Авторизация</td></tr>
				<tr>
					<td bgcolor="#F9F9FF" align="center" style="border-bottom:solid 1px #9AA0A3; height:150px;">
						
					
						<table border="0" cellpadding="8" cellspacing="0">
						<form action=/ method=post autocomplete="off" name=form>
							<input type=hidden name=type value=logon>
							<input type=hidden name=action value=execute>
							<input type=hidden name=redirect_params value="$_REQUEST{redirect_params}">
<!--							
							<tr>
								<td colspan="2" align="center"><a id="logon_url" style="text-decoration:none" href="javascript: document.forms['form'].elements['action'].value='execute_ip'; document.forms['form'].submit()"><div class="green-title"><div style="float:left;margin-top:6px;">Войти как Овсянко Дмитрий Евгеньевич</div><div style="float:right;"><img src="/i/logon_turbo_milk/images/green_ear_right.gif" border="0"></div></div></td>
							</tr>
-->							
							<tr class="logon">
								<td><b>Логин:</b></td>
								<td><input type="text" name="login" style="width:200px;" onfocus="q_is_focused = true" onblur="q_is_focused = false" onKeyPress="if (window.event.keyCode == 13) form.password.focus ()"></td>
							</tr>
							<tr class="logon">
								<td><b>Пароль:</b></td>
								<td><input type="password" name="password" style="width:200px;" onfocus="q_is_focused = true" onblur="q_is_focused = false" onKeyPress="if (window.event.keyCode == 13) form.submit ()"></td>
							</tr>
							
							
						</form>
						</table>
					</td>
				</tr>
				<tr>
					<td class="submit-area">						
						<div class="grey-submit">
							<div style="float:left;margin-top:5px;"><a href="#"><img src="$_REQUEST{__static_url}/i_logon.gif?$_REQUEST{__static_salt}" border="0" align="left" hspace="5"></a><a href="javascript:document.forms['form'].submit()">Войти в систему</a></div>
							<div style="float:right;"><img src="$_REQUEST{__static_url}/grey_ear_right.gif?$_REQUEST{__static_salt}" border="0"></div>
						</div>
					</td>
				</tr>
			</table>
			
			
		</td>
		

		
	</tr>
	<tr>
		<td valign=top height=90>
			<img src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=20 height=90 border=0>
		</td>
	</tr>
	
</table>

EOH

}




1;
