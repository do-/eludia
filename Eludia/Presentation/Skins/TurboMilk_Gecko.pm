package Eludia::Presentation::Skins::TurboMilk_Gecko;

use Data::Dumper;
use Storable ('freeze');

no warnings;

BEGIN {

	require Eludia::Presentation::Skins::Generic;
	delete $INC {"Eludia/Presentation/Skins/Generic.pm"};

	our $replacement = {
		error    => 'JS_Gecko',
		redirect => 'JS_Gecko',
	};

}

################################################################################

sub options {

	return {
		core_unblock_navigation => $preconf -> {core_unblock_navigation},
	};
	
}

################################################################################

sub register_hotkey {

	my ($_SKIN, $hashref) = @_;

	$hashref -> {label} =~ s{\&(.)}{<u>$1</u>} or return undef;
	
	return undef if $_REQUEST {__edit};

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
а		$mday $i18n->{months}->[$mon] $year&nbsp;&nbsp;&nbsp;<span id="clock_hours"></span><span id="clock_separator" style="width:5px"></span><span id="clock_minutes"></span>
EOH
	
}

################################################################################

sub draw_gantt_bars {

	my ($_SKIN, $options) = @_;
	
	my $top = 5;
	my $html = '';
	
	$options -> {plan} -> {color} ||= 'blue';
	$options -> {fact} -> {color} ||= 'red';
	
	foreach my $key ('plan', 'fact') {
	
		my $bar = $options -> {$key};
	
		my @pf = split /-/, $bar -> {from};
		my $dpf = $pf [2] / 30;

		my @pt = split /-/, $bar -> {to};
		my $dpt = $pf [2] / 30;

		$html .= <<EOH;
			<td style="
				border:solid black 1px;
				height:7px;
				z-index:0;
				position:absolute;
				top:  expression(this.previousSibling.offsetTop + $top);
				left: expression(getElementById('gantt_$pf[0]_$pf[1]').offsetLeft + $dpf * getElementById('gantt_$pf[0]_$pf[1]').offsetWidth);
				width:expression(getElementById('gantt_$pt[0]_$pt[1]').offsetLeft + $dpt * getElementById('gantt_$pt[0]_$pt[1]').offsetWidth - getElementById('gantt_$pf[0]_$pf[1]').offsetLeft - $dpf * getElementById('gantt_$pf[0]_$pf[1]').offsetWidth);
				background-color:$bar->{color}
			" title="$bar->{title}"><img src='/0.gif' width=1 height=1></td>
EOH

		$top = 6;

	}
	
	return $html;

}

################################################################################

sub draw_auth_toolbar {

	my ($_SKIN, $options) = @_;

	my $logout_url = $conf -> {exit_url} || create_url (type => '_logout', id => '');
	my $logo_url = $conf -> {logo_url};

	my ($header, $header_height, $subset_div, $subset_div, $subset_cell);
	
	my $header_prefix = 'out';
	
	if ($_USER -> {id}) {
	
		$$options {user_label} =~ s/$$i18n{User}: ${\($$_USER{label} || $$i18n{not_logged_in})}//;
		$$options {user_label} = '<nobr><b>' . $_USER -> {f} . ' ' . substr ($_USER -> {i}, 0, 1) . '. ' . substr ($_USER -> {o}, 0, 1) . '.</b></nobr><br>' . $options -> {user_label}
			if ($_USER -> {f} || $_USER -> {i}) ;
		

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
						<td><img src="$_REQUEST{__static_url}/0.gif" border="0" hspace="0" width=5 height=1></td>
						<td><div id="admin" onClick="switch_subsets_are_visible (1 - subsets_are_visible); document.getElementById ('_body_iframe').contentWindow.subsets_are_visible = subsets_are_visible;"><a href="#">$$item{label}</a></div></td>
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
		<table id="logo_table" cellSpacing=0 cellPadding=0 width="100%" border=0 bgcolor="#e5e5e5" background="$_REQUEST{__static_site}/i/bg_logo_$header_prefix.gif" style="background-repeat: repeat-x">
			<tr>
			<td width="20"><img src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=20 height=$header_height border=0></td>
			<td width=1><table border=0 valign="middle" border=0><tr>
				<td valign="top" width=1><a href="$logo_url"><img src="$_REQUEST{__static_site}/i/logo_$header_prefix.gif" border="0"></a></td>
				<td width=1><img src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=10 height=1 border=0></td>
				<td width=1 valign="bottom" style='padding-bottom: 5px;'><img src="$_REQUEST{__static_url}/gsep.gif?$_REQUEST{__static_salt}" width="4" height="21"></td>
				<td align="left" valign="middle" class='header_0' width=1><nobr>&nbsp;$$conf{page_title}</nobr></td>
			</tr></table></td>

			$header
			<td width="20px" align="right">&nbsp;</td></tr>
		 </table>
		$subset_div
		$$options{top_banner}
EOH


}

################################################################################

sub draw_window_title {

	my ($_SKIN, $options) = @_;
	
	if ($_REQUEST {select}) {
	
		$_REQUEST {__script} .= <<EOJ;
			top.document.title = '$$options{label}';
EOJ
		return '';
		
	} else {
	 
		return <<EOH
			<table cellspacing=0 cellpadding=0 width="100%"><tr><td bgcolor="#edf1f5" class="header_3"><img src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=1 height=29 align=absmiddle>&nbsp;&nbsp;&nbsp;$$options{label}</td></tr><tr><td bgcolor="#e4e9ee"><img src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=1 height=1></td></tr></table>
EOH

	}

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
	$options -> {onKeyPress} ||= 'if (event.keyCode != 27) is_dirty=true';
	
	my $attributes = dump_attributes ($options -> {attributes});
	
	if ($_REQUEST {__only_field}) {

		return '';

	}
		
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
		<img id="calendar_trigger_$$options{id}" src="$_REQUEST{__static_url}/i_calendar.gif" align=absmiddle>
EOH
			
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
		return '';	
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
			<input type=hidden name="__suggest" value="">
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
	
	$options -> {style} ||= $options -> {nowrap} ? qq{style="background:url('$_REQUEST{__static_url}/bgr_grey.gif?$_REQUEST{__static_salt}');background-repeat:repeat-x;"} : '';
		
	my $path = <<EOH;
		<table cellspacing=0 cellpadding=0 width="100%" border=0>
			<tr>
				<td>
					<table cellspacing=0 cellpadding=0 width="100%" border=0>
						<tr>
							<td class="toolbar" $$options{style}>
								<img height=29 src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=1 border=0>
							</td>
							<td class="toolbar" $$options{style} $$options{nowrap}>&nbsp;
EOH

	my $icon = $options -> {status} ? "status_$options->{status}->{icon}.gif" : 'i_folder.gif';

	$path .= qq{<img src="$_REQUEST{__static_url}/${icon}?$_REQUEST{__static_salt}" border=0 hspace=3 vspace=1 align=absmiddle>&nbsp;};

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
	
	if ($field -> {type} eq 'banner') {
		my $colspan     = 'colspan=' . ($field -> {colspan} + 1);
		return qq{<td class='form-$$field{state}-label' $colspan nowrap align=center>$$field{html}</td>};
	}
	elsif ($field -> {type} eq 'article') {
		my $colspan     = 'colspan=' . ($field -> {colspan} + 1);
		return qq{<td $colspan class='form-article'>$$field{html}</td>};
	}
	elsif ($field -> {type} eq 'hidden') {
		return $field -> {html};
	}
				
	my $colspan       = $field -> {colspan}       ? 'colspan=' . $field -> {colspan}       : '';
	my $colspan_label = $field -> {colspan_label} ? 'colspan=' . $field -> {colspan_label} : '';
	my $label_width   = $field -> {label_width}   ? 'width='   . $field -> {label_width}   : '';	
	my $cell_width    = $field -> {cell_width}    ? 'width='   . $field -> {cell_width}    : '';
	
	my $label_cell;
	$label_cell = qq {<td class='form-$$field{state}-label' nowrap $colspan_label align=right $label_width>\n$$field{label}</td>}
		unless ($field -> {label_off});
		
	return <<EOH;
		$label_cell		
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
	
	$options -> {attributes} -> {onKeyPress} .= ';if (event.keyCode != 27) is_dirty=true;';
	$options -> {attributes} -> {onKeyDown}  .= ';tabOnEnter(event);';
	$options -> {attributes} -> {onFocus}    .= ';scrollable_table_is_blocked = true; q_is_focused = true;';
	$options -> {attributes} -> {onBlur}     .= ';scrollable_table_is_blocked = false; q_is_focused = false;';

	return '<input type="text"' . dump_attributes ($options -> {attributes}) . ' >';

}

################################################################################

sub draw_form_field_suggest {

	my ($_SKIN, $options, $data) = @_;
	
	$_REQUEST {__script} .= qq{; 	
	
		function off_suggest_$options->{name} () {
			var s = document.getElementById ('_$options->{name}__suggest'); 
			s.style.display = 'none';
		}; 
		
	};
	
	$options -> {attributes} -> {onKeyPress} .= ';if (event.keyCode != 27) is_dirty=true;';
	$options -> {attributes} -> {onKeyDown}  .= ';tabOnEnter(event);';
	$options -> {attributes} -> {onFocus}    .= ';scrollable_table_is_blocked = true; q_is_focused = true;';
	$options -> {attributes} -> {onBlur}     .= qq{;scrollable_table_is_blocked = false; q_is_focused = false; getElementById('_$options->{name}__label').value = this.value; _suggest_timer_$options->{name} = setTimeout (off_suggest_$options->{name}, 100);};

	$options -> {attributes} -> {onKeyDown}  .= <<EOH;
	
		var s = getElementById('_$options->{name}__suggest');

		if (event.keyCode == 40 && s.style.display == 'block') {
			s.focus ();
		}
   
EOH
	
	
	$options -> {attributes} -> {onKeyUp} .= <<EOH;
		if (suggest_clicked) {
			suggest_clicked = 0;
		}
		else {
			var f = this.form;
			f.elements ['_$options->{name}__label'].value = '';
			f.elements ['_$options->{name}__id'].value = '';
			var s = f.elements ['__suggest'];
			document.getElementById ('_$options->{name}__suggest').style.display = 'none';
			if (this.value.length > 0) {
				s.value = '$options->{name}';
				document.getElementById ('_$options->{name}__label').value = this.value;
				f.submit ();
				s.value = '';
			}
		}
EOH

	my $attributes = dump_attributes ($options -> {attributes});
	
	my $id = '_' . $options->{name};

	return <<EOH;
		<script>
			var _suggest_timer_$options->{name} = null;
		</script>
		<select 
			id="_$options->{name}__suggest" 
			name="_$options->{name}__suggest" 
			size="$options->{lines}"
			style="
				display : none;
				position: absolute;
				border  : solid black 1px;
				z-index : 100;
			"
			onFocus="
				if (_suggest_timer_$options->{name}) {
					clearTimeout (_suggest_timer_$options->{name});
					_suggest_timer_$options->{name} = null;
				}
			"
			onDblClick="set_suggest_result (event, this, '$id'); $$options{after}"
			onKeyPress="if (event.keyCode == 13) {set_suggest_result (event, this, '$id'); $$options{after}; suggest_clicked = 1}"
		>
		</select>
		<input type="text" id="$id" $attributes autocomplete="off"><input type="hidden" id="${id}__label" name="_$options->{name}__label" value="$options->{attributes}->{value}"><input type="hidden" id="${id}__id" name="_$options->{name}__id" value="$options->{value__id}">
EOH

}

################################################################################

sub draw_form_field_datetime {

	my ($_SKIN, $options, $data) = @_;
		
	$options -> {name} = '_' . $options -> {name};
	$options -> {onKeyDown} ="tabOnEnter(event)";

	return $_SKIN -> _draw_input_datetime ($options);
	
}

################################################################################

sub draw_form_field_file {

	my ($_SKIN, $options, $data) = @_;	
		
	my $attributes = dump_attributes ($options -> {attributes});

	return <<EOH;
		<input 
			type="file"
			name="_$$options{name}"
			size=$$options{size}
			$attributes
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
	
	$html .= '<nobr>'
		if ($options -> {nobr});
		 
	foreach my $item (@{$options -> {items}}) {
		next if $item -> {off};
		$html .= $item -> {label} if $item -> {label};
		$html .= $item -> {html};
		$html .= '&nbsp;';
	}

	$html .= '</nobr>'
		if ($options -> {nobr});

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
	return qq {<input type="password" name="_$$options{name}" size="$$options{size}" onKeyPress="if (event.keyCode != 27) is_dirty=true" $attributes onKeyDown="tabOnEnter(event)" onFocus="scrollable_table_is_blocked = true; q_is_focused = true" onBlur="scrollable_table_is_blocked = false; q_is_focused = false">};
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
	
		$options -> {separator} ||= '<br>';

		for (my $i = 0; $i < @{$options -> {value}}; $i++) {

			if ($i) {
				$html =~ s{\s*$}{};
				$html =~ s{\s*$}{$options->{separator}};
			}

			$html .= $options -> {value} -> [$i] -> {label};

		}
		
	}
	else {
		$html .= $options -> {value};
		$html .= '&nbsp;' if $options -> {value} eq '';
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
	
	return qq {<input class=cbx type="checkbox" name="_$$options{name}" $attributes $checked value=1 onChange="is_dirty=true" onKeyDown="tabOnEnter(event)">};
	
}

################################################################################

sub draw_form_field_radio {

	my ($_SKIN, $options, $data) = @_;
				
	my $html = '<table border=0 cellspacing=2 cellpadding=0 width=100%>';
	
	my $n = 0;
	
	foreach my $value (@{$options -> {values}}) {
	
		delete $value -> {attributes} -> {name};
		delete $value -> {attributes} -> {value};
		delete $value -> {attributes} -> {id};
		delete $value -> {attributes} -> {onclick};
	
		my $attributes = dump_attributes ($value -> {attributes});
		
		(!$n and $options -> {no_br}) or $html .= qq {\n<tr><td class="form-inner" valign=top width=1%>};
		$html .= qq {\n<nobr><input class=cbx $attributes id="$value" onFocus="scrollable_table_is_blocked = true; q_is_focused = true" onBlur="scrollable_table_is_blocked = false; q_is_focused = false" type="radio" name="_$$options{name}" value="$$value{id}" onClick="is_dirty=true;$$value{onclick}" onKeyDown="tabOnEnter(event)">&nbsp;$$value{label}</nobr>};
							
		$value -> {html} or next;
		
		$html .= qq{\n\t\t<td class="form-inner"><div style="display:expression(getElementById('$value').checked ? 'block' : 'none')">$$value{html}</div>};
		
		$n ++;
				
	}
	
	$html .= '</table>';
		
	return $html;
	
}

################################################################################

sub draw_form_field_select {

	my ($_SKIN, $options, $data) = @_;
	
	$options -> {attributes} ||= {};
	my $attributes = dump_attributes ($options -> {attributes});
	
	if (defined $options -> {other}) {

		$options -> {other} -> {width}  ||= $conf -> {core_modal_dialog_width} || 'screen.availWidth - (screen.availWidth <= 800 ? 50 : 100)';
		$options -> {other} -> {height} ||= $conf -> {core_modal_dialog_height} || 'screen.availHeight - (screen.availHeight <= 600 ? 50 : 100)';

		$options -> {no_confirm} ||= $conf -> {core_no_confirm_other};

		if ($options -> {no_confirm}) {

			$options -> {onChange} .= <<EOJS;

				if (this.options[this.selectedIndex].value == -1) {

					var dialog_width = $options->{other}->{width};
					var dialog_height = $options->{other}->{height};

					var result = window.showModalDialog ('$ENV{SCRIPT_URI}/i/_skins/TurboMilk/dialog.html?@{[rand ()]}', {href: '$options->{other}->{href}&select=$options->{name}'}, 'status:no;resizable:yes;help:no;dialogWidth:' + dialog_width + 'px;dialogHeight:' + dialog_height + 'px');
					
					focus ();

					if (result.result == 'ok') {
						setSelectOption (this, result.id, result.label);
					} else {
						this.selectedIndex = 0;
					}
					
				}
EOJS
		} else {

			$options -> {onChange} .= <<EOJS;
	
				if (this.options[this.selectedIndex].value == -1) {

					if (window.confirm ('$$i18n{confirm_open_vocabulary}')) {

						var dialog_width = $options->{other}->{width};
						var dialog_height = $options->{other}->{height};

						var result = window.showModalDialog ('$ENV{SCRIPT_URI}/i/_skins/TurboMilk/dialog.html?@{[rand ()]}', {href: '$options->{other}->{href}&select=$options->{name}'}, 'status:no;resizable:yes;help:no;dialogWidth:' + dialog_width + 'px;dialogHeight:' + dialog_height + 'px');
						
						focus ();

						if (result.result == 'ok') {
							setSelectOption (this, result.id, result.label);
						} else {
							this.selectedIndex = 0;
						}
					
					} else {

						this.selectedIndex = 0;

					}
				}
EOJS
		}
	}

	my $html = <<EOH;
		<select 
			name="_$$options{name}"
			id="_$$options{name}_select"
			$attributes
			onKeyDown="tabOnEnter(event)"
			onChange="is_dirty=true; $$options{onChange}" 
			onKeyPress="typeAhead()" 
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

#	if (defined $options -> {other}) {
#		$html .= <<EOH;
#			<div id="_$$options{name}_div" style="{position:absolute; display:none; width:expression(getElementById('_$$options{name}_select').offsetParent.offsetWidth - 10)}">
#				<iframe name="_$$options{name}_iframe" id="_$$options{name}_iframe" width=100% height=${$$options{other}}{height} src="$_REQUEST{__static_url}/0.html" application="yes">
#				</iframe>
#			</div>
#EOH
#	}

	return $html;
	
}

################################################################################

sub draw_form_field_string_voc {

	my ($_SKIN, $options, $data) = @_;
	
	$options -> {attributes} ||= {};

	$options -> {attributes} -> {onKeyPress} .= qq[;if (event.keyCode != 27) {is_dirty=true;document.getElementById('${options}_id').value = 0; }];
	$options -> {attributes} -> {onKeyDown}  .= qq[;if (event.keyCode == 8 || event.keyCode == 46) {is_dirty=true;document.getElementById('${options}_id').value = 0;}; tabOnEnter(event);];
	$options -> {attributes} -> {onFocus}    .= ';scrollable_table_is_blocked = true; q_is_focused = true;';
	$options -> {attributes} -> {onBlur}     .= ';scrollable_table_is_blocked = false; q_is_focused = false;';
	$options -> {attributes} -> {onChange}   .= 'is_dirty=true;' . ( $options->{onChange} ? $options->{onChange} . ' try { event.cancelBubble = false } catch (e) {} try { event.returnValue = true } catch (e) {}': '');

	my $attributes = dump_attributes ($options -> {attributes});

	if (defined $options -> {other}) {

		$options -> {other} -> {width}  ||= $conf -> {core_modal_dialog_width} || 'screen.availWidth - (screen.availWidth <= 800 ? 50 : 100)';
		$options -> {other} -> {height} ||= $conf -> {core_modal_dialog_height} || 'screen.availHeight - (screen.availHeight <= 600 ? 50 : 100)';

		$options -> {other} -> {onChange} .= <<EOJS;

			var dialog_width = $options->{other}->{width};
			var dialog_height = $options->{other}->{height};

			var q = encode1251(document.getElementById('${options}_label').value);

			var result = window.showModalDialog ('$ENV{SCRIPT_URI}/i/_skins/TurboMilk/dialog.html?@{[rand ()]}', {href: '$options->{other}->{href}&$options->{other}->{param}=' + q + '&select=$options->{name}&$options->{other}->{cgi_tail}'}, 'status:no;resizable:yes;help:no;dialogWidth:' + dialog_width + 'px;dialogHeight:' + dialog_height + 'px');
			
			focus ();
			
			if (result.result == 'ok') {
				document.getElementById('${options}_label').value=result.label;
				document.getElementById('${options}_id').value=result.id;
$options->{onChange}
			} else {
				this.selectedIndex = 0;
			}
EOJS
	}


	my $html = qq[<span style="white-space: nowrap" id="_$options->{name}_span"><input type="text" $attributes id="${options}_label" >]
		. ($options -> {other} ? qq [ <input type="button" value="..." onclick="$options->{other}->{onChange}">] : '')
		. qq[<input type="hidden" name="_$options->{name}" value="$options->{id}" id="${options}_id"></span>];
		

	return $html;
	
}

################################################################################

sub draw_form_field_tree {

	my ($_SKIN, $options, $data) = @_;
	
	my @nodes = ();
	
	our %idx = ();
	our %lch = ();
	
	foreach my $value (@{$options -> {values}}) {
	
		my $node = $value -> {__node};
		push @nodes, $node;
		
		$idx {$node -> {id}} = $node;
		$lch {$node -> {pid}} = $node if $node -> {pid};
	}
	
	while (my ($k, $v) = each %lch) {
		$idx {$k} -> {_hc} = 1;
		$v -> {_ls} = 1;
	}
	
	my $name = $options -> {name} || 'd';
	$options->{height} ||= 200;
	
	my $nodes = $_JSON -> encode (\@nodes);

	return <<EOH;
<table 
	width=100% 
	height="$options->{height}" 
	celspacing=0 
	cellpadding=0 
	class='dtree'
>	
	<tr>
		<td valign=top height="$options->{height}">
		<script type="text/javascript">
			var $name = new dTree ('$name');
			var c = $name.config;
			c.iconPath = '$_REQUEST{__static_url}/tree_';
			c.useStatusText = false;
			c.useSelection = false;
			$name.icon.node = 'folderopen.gif';
			$name.aNodes = $nodes;
			document.write($name);
			for (var n = 0; n < $name.checkedNodes.length; n++) {
				$name.openTo ($name.checkedNodes [n], true, true);
			}
			
		</script>
</td></tr></table>
EOH
	

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
					
					$subhtml .= $subvalue -> {no_checkbox} ? qq{&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;$$subvalue{label} <br>} : qq {&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<input class=cbx type="checkbox" name="_$$options{name}_$$subvalue{id}" value="1" $subchecked onChange="is_dirty=true" tabindex=$tabindex>&nbsp;$$subvalue{label} <br>};
				
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
	
	if ($_REQUEST {select}) {

		my $button = {		
			icon    => 'cancel',
			id      => 'cancel',
			label   => $i18n -> {close},
			href    => "javaScript:window.close();",
		};
		
		$button -> {html} = $_SKIN -> draw_toolbar_button ($button);

		unshift @{$options -> {buttons}}, $button;

	}

	my $html = <<EOH;
		<table bgcolor="b9c5d7" cellspacing=0 cellpadding=0 width="100%" border=0>
			<form action=$_REQUEST{__uri} name=$options->{form_name} target="$$options{target}">
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
	"$_REQUEST{__static_site}/i/buttons/$_[0].gif"			

}

################################################################################

sub draw_toolbar_button {

	my ($_SKIN, $options) = @_;
	my $html = <<EOH;
		<td>
		<table cellspacing=0 cellpadding=0 border=0 valign="middle">
		<tr>
			<td class="bgr0" width=6><img src="$_REQUEST{__static_url}/btn2_l.gif?$_REQUEST{__static_salt}" width="6" height="21" border="0"></td>
			<td class="bgr0" style="background-repeat:repeat-x" background="$_REQUEST{__static_url}/btn2_bg.gif?$_REQUEST{__static_salt}" valign="middle" align="center" nowrap><nobr>&nbsp;<a TABINDEX=-1 class=button href="$$options{href}" $$options{onclick} id="$$options{id}" target="$$options{target}">
EOH

	if ($options -> {icon}) {
		my $img_path = _icon_path ($options -> {icon});
		$html .= qq {<img src="$img_path" alt="$label" border=0 hspace=0 align=absmiddle>&nbsp;};
	}
	
	$html .= <<EOH;
			</a>
			</nobr></td>
			<td class="bgr0" style="background-repeat:repeat-x" background="$_REQUEST{__static_url}/btn2_bg.gif?$_REQUEST{__static_salt}" valign="middle" align="center" nowrap><nobr>&nbsp;<a TABINDEX=-1 class=button href="$$options{href}" $$options{onclick} id="$$options{id}" target="$$options{target}">
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

	$options -> {name} = '_' . $options -> {name}
		if defined $options -> {other};

	my $name = $$options{name};

	my $read_only = $options -> {read_only} ? 'disabled' : ''; 

	if (defined $options -> {other}) {
		$options -> {other} -> {width}  ||= $conf -> {core_modal_dialog_width} || 600;
		$options -> {other} -> {height} ||= $conf -> {core_modal_dialog_height} || 400;

		$options -> {no_confirm} ||= $conf -> {core_no_confirm_other};

		if ($options -> {no_confirm}) {

			$options -> {onChange} .= <<EOJS;

				if (this.options[this.selectedIndex].value == -1) {

					var result = window.showModalDialog ('$ENV{SCRIPT_URI}/i/_skins/TurboMilk/dialog.html?@{[rand ()]}', {href: '$options->{other}->{href}&select=$name'}, 'status:no;resizable:yes;help:no;dialogWidth:$options->{other}->{width}px;dialogHeight:$options->{other}->{height}px');
					
					focus ();
					
					if (result.result == 'ok') {
						setSelectOption (this, result.id, result.label);
						submit ();
					} else {
						this.selectedIndex = 0;
					}
					
				} else {
  				submit ();
        }
EOJS
		} else {

			$options -> {onChange} .= <<EOJS;
	
				if (this.options[this.selectedIndex].value == -1) {

					if (window.confirm ('$$i18n{confirm_open_vocabulary}')) {

						var result = window.showModalDialog ('$ENV{SCRIPT_URI}/i/_skins/TurboMilk/dialog.html?@{[rand ()]}', {href: '$options->{other}->{href}&select=$name'}, 'status:no;resizable:yes;help:no;dialogWidth:$options->{other}->{width}px;dialogHeight:$options->{other}->{height}px');
						
						focus ();
						
						if (result.result == 'ok') {
							setSelectOption (this, result.id, result.label);
  						submit ();
						} else {
							this.selectedIndex = 0;
						}
					
					} else {

						this.selectedIndex = 0;

					}
				} else {
  				submit ();
        }
EOJS
		}
	}

	$options -> {attributes} ||= {};
	my $attributes = dump_attributes ($options -> {attributes});
	
	$html .= <<EOH;
		<select name="$name" id="${name}_select" $read_only onChange="$$options{onChange}" onkeypress="typeAhead()" $attributes>
EOH

	foreach my $value (@{$options -> {values}}) {
	
		my $attributes = dump_attributes ($value -> {attributes});
			
		$html .= qq {<option value="$$value{id}" $$value{selected} $attributes>$$value{label}</option>};
	
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

	$html .= qq {<input class=cbx type=checkbox value=1 $$options{checked} name="$$options{name}" onClick="$$options{onClick}">};

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


	$options -> {attributes} ||= {};
	
	$options -> {onKeyPress} ||= "if (event.keyCode == 13) {form.submit()}";

	my $attributes = dump_attributes ($options -> {attributes});

	$html .= <<EOH;
		<input 
			onKeyPress="$$options{onKeyPress}" 
			type=text 
			size=$$options{size} 
			name=$$options{name} 
			value="$$options{value}" 
			onFocus="scrollable_table_is_blocked = true; q_is_focused = true" 
			onBlur="scrollable_table_is_blocked = false; q_is_focused = false"
			$attributes
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
	$options -> {onKeyPress} = "if (event.keyCode == 13) {this.form.submit()}";

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
	
	my $nbsp = $options -> {label} ? '&nbsp;' : '';

	return <<EOH;
		<td nowrap background="$_REQUEST{__static_url}/cnt_tbr_bg.gif?$_REQUEST{__static_salt}">
			<table cellspacing="0" cellpadding="0" border="0">
				<tr>
					<td width=6><img src="$_REQUEST{__static_url}/btn_l.gif?$_REQUEST{__static_salt}" width="6" height="25" border="0"></td>
					<td width=30 background="$_REQUEST{__static_url}/btn_bg.gif?$_REQUEST{__static_salt}" valign="middle" align="center" nowrap><a class="button" $$options{onclick} href="$$options{href}" id="$$options{id}" target="$$options{target}"><img src="$img_path" alt="$$options{label}" border=0 hspace=0 vspace=1 align=absmiddle>${nbsp}</a></td>
					<td background="$_REQUEST{__static_url}/btn_bg.gif?$_REQUEST{__static_salt}" valign="absmiddle" align="center" nowrap><a class="button" $$options{onclick} href="$$options{href}" id="$$options{id}" target="$$options{target}">$$options{label}</a>${nbsp}${nbsp}</td>
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

sub draw_dump_button {

	return {
		label  => 'Dump',
		name   => '_dump',
		href   => "javascript:_dumper_href();",
		side   => 'right_items',
		no_off => 1,

	};
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

	<div style="position:relative" id="main_menu">

		<table width="100%" class=bgr8 cellspacing=0 cellpadding=0 border=0>
			<tr>
				<td background="$_REQUEST{__static_url}/menu_bg.gif?$_REQUEST{__static_salt}" width=1><img height=26 src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=1 border=0></td>
				<td background="$_REQUEST{__static_url}/menu_bg_s.gif?$_REQUEST{__static_salt}" width=0><img height=26 src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=0 border=0></td>
EOH

	my $core_unblock_navigation = $preconf -> {core_unblock_navigation} || 0;

	foreach my $type (@types) {

		next if ($type -> {name} eq '_logout');
		
		$_REQUEST {__menu_links} .= "<a id='main_menu_$$type{name}' target='$$type{target}' href='$$type{href}' onclick='return !check_edit_mode (this);'>-</a>";
		
		$type -> {target} = '_body_iframe' if $type -> {target} eq '_self';

		if ($type eq BREAK) {
			$html .= qq{<td background="$_REQUEST{__static_url}/menu_bg.gif?$_REQUEST{__static_salt}" width=100%><img height=1 src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=1 border=0></td>};
			next;
		}
		
		$html .= <<EOH;
			<td onmouseover="if (!edit_mode || $core_unblock_navigation) {$$type{onhover}; subsets_are_visible = 0; document.getElementById ('_body_iframe').contentWindow.subsets_are_visible = 0}" onmouseout="$$type{onmouseout}" class="main-menu" nowrap>&nbsp;
				<a class="main-menu" id="main_menu_$$type{name}" target="$$type{target}" href="$$type{href}" tabindex=-1 @{[ $type -> {name} eq '_dump' ? '' : 'onclick="return !check_edit_mode (this);"' ]}>&nbsp;$$type{label}&nbsp;</a>&nbsp;
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

	my ($_SKIN, $name, $types, $level, $is_main) = @_;
		
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
		
			$type -> {onclick} =~ s{'_self'\)$}{'_body_iframe'\)} unless ($_REQUEST {__tree});
		
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
						<td width=1 bgcolor=#5d6496><img height=1 src=$_REQUEST{__static_url}/0.gif width=1 border=0></td>
						<td width=1 bgcolor=#5d6496><img height=1 src=$_REQUEST{__static_url}/0.gif width=1 border=0></td>
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

	my $a = $_JSON -> encode ({
		$conf -> {core_no_confirm_other} ? () : (question => "$i18n->{confirm_close_vocabulary} \"$item->{label}\"?"),
		id       => $item -> {id},
		label    => $item -> {label},
	});

	my $var = "so_" . (0 + $item -> {id}) . int (rand() * time ());
	$var =~ s/[.]//g;

	$_REQUEST {__script} .= " var $var = $a; "
		unless ($_REQUEST {__script} =~ / var $var =/);

	return "javaScript:invoke_setSelectOption ($var)";

}

################################################################################

sub draw_text_cell {

	my ($_SKIN, $data, $options) = @_;
	
	my $html = "\n\t<td ";
	$html .= dump_attributes ($data -> {attributes}) if $data -> {attributes};
	$html .= ' style="padding-left:' . ($data -> {level} * 15 + 3) . '"' if (defined $data -> {level});
	$html .= '>';
	
	$data -> {off} = 1 unless $data -> {label} =~ /\S/;
	
	unless ($data -> {off}) {
	
		$data -> {label} =~ s{^\s+}{}gsm;
		$data -> {label} =~ s{\s+$}{}gsm;
		$data -> {label} =~ s{\n}{<br>}gsm if $data -> {no_nobr};

		$html .= qq {<img src='$_REQUEST{__static_url}/status_$data->{status}->{icon}.gif' border=0 alt='$data->{status}->{label}' align=absmiddle hspace=5>} if $data -> {status};

		$html .= '<nobr>' unless $data -> {no_nobr};

#		$html .= '&nbsp; ';		

		$html .= '<b>'      if $data -> {bold}   || $options -> {bold};
		$html .= '<i>'      if $data -> {italic} || $options -> {italic};
		$html .= '<strike>' if $data -> {strike} || $options -> {strike};
		
		$html .= qq {<a id="$$data{a_id}" class=$$data{a_class} $$data{onclick} target="$$data{target}" href="$$data{href}" onFocus="blur()">} if $data -> {href};

		$html .= $data -> {label};
		
		if ($data -> {href}) {

			$html .= $data -> {href} eq $options -> {href} ? '</span>' : '</a>';
		
		}

		$html .= '</a>' if $data -> {href};
		
		$html .= '</nobr>' unless $data -> {no_nobr};
		
		$html .= qq {<input type=hidden name="$$data{hidden_name}" value="$$data{hidden_value}">} if ($data -> {add_hidden});
		
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
	
	my $label = $data -> {label} ? '&nbsp;' . $data -> {label} : '';

	return qq {<td $$options{data} $attributes><input class=cbx type=checkbox name=$$data{name} $$data{checked} value='$$data{value}'>$label</td>};

}

################################################################################

sub draw_select_cell {

	my ($_SKIN, $data, $options) = @_;

	my $attributes = dump_attributes ($data -> {attributes});

	my $multiple = $data -> {rows} > 1 ? "multiple size=$$data{rows}" : '';
	my $html = qq {<td $attributes><select 
		name="$$data{name}" 
		onChange="is_dirty=true; $$options{onChange}" 
		onkeypress='typeAhead();' 
		$multiple
	};
	$html .= '>';

	$html .= qq {<option value="0">$$data{empty}</option>\n} if defined $data -> {empty};

	foreach my $value (@{$data -> {values}}) {
		$html .= qq {<option value="$$value{id}" $$value{selected}>$$value{label}</option>\n};
	}
	
	$html .= qq {</select></td>};
	
	return $html;

}


################################################################################

sub draw_string_voc_cell {

	my ($_SKIN, $data, $options) = @_;

	my $attributes = dump_attributes ($data -> {attributes});

	if (defined $data -> {other}) {
		
		$data -> {other} -> {width}  ||= $conf -> {core_modal_dialog_width} || 'screen.availWidth - (screen.availWidth <= 800 ? 50 : 100)';
		$data -> {other} -> {height} ||= $conf -> {core_modal_dialog_height} || 'screen.availHeight - (screen.availHeight <= 600 ? 50 : 100)';
	
		$data -> {other} -> {onChange} .= <<EOJS;			
			var dialog_width = $data->{other}->{width};
			var dialog_height = $data->{other}->{height};
			
			var q = encode1251(document.getElementById('$$data{name}_label').value);
			
			var result = window.showModalDialog ('$ENV{SCRIPT_URI}/i/_skins/TurboMilk/dialog.html?@{[rand ()]}', {href: '$data->{other}->{href}&$data->{other}->{param}=' + q + '&select=$data->{name}'}, 'status:no;resizable:yes;help:no;dialogWidth:' + dialog_width + 'px;dialogHeight:' + dialog_height + 'px');
			
			focus ();
			
			if (result.result == 'ok') {						
				document.getElementById('$$data{name}_label').value = result.label;
				document.getElementById('$$data{name}_id').value = result.id;
			}
EOJS
	}
		
	my $html = qq {<td $attributes><nobr><span style="white-space: nowrap"><input onFocus="q_is_focused = true; left_right_blocked = true;" onBlur="q_is_focused = false; left_right_blocked = false;" type="text" value="$$data{label}" id="$$data{name}_label" maxlength="$$data{max_len}" size="$$data{size}"> }
		. ($data -> {other} ? qq [<input type="button" value="$data->{other}->{button}" onclick="$data->{other}->{onChange}">] : '')
		. qq[<input type="hidden" name="_$$data{name}" value="$$data{id}" id="$$data{name}_id"></span>]
		. qq[</nobr></td>];	
	
	return $html;
 
}

################################################################################

sub draw_input_cell {

	my ($_SKIN, $data, $options) = @_;

	my $attributes = dump_attributes ($data -> {attributes});
	
	$data -> {label} =~ s{\"}{\&quot;}gsm;

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

	$cell -> {label} .= "\&nbsp;\&nbsp;<a class=row-cell-header-a href=\"$$cell{href_asc}\"><b>\&uarr;</b></a>"  if $cell -> {href_asc};
	$cell -> {label} .= "\&nbsp;\&nbsp;<a class=row-cell-header-a href=\"$$cell{href_desc}\"><b>\&darr;</b></a>" if $cell -> {href_desc};

	if ($cell -> {order} && !$conf -> {core_no_order_arrows}) {
		$cell -> {label} = "<nobr><img src='$_REQUEST{__static_url}/order.gif' border=0 hspace=1 vspace=0 align=absmiddle>" . $cell -> {label} . "</nobr>";
	}	
	else {
		$cell -> {label} = '&nbsp;' . $cell -> {label};
	}

	if ($cell -> {href}) {
		$cell -> {label} = "<a class=row-cell-header-a href=\"$$cell{href}\"><b>" . $cell -> {label} . "</b></a>";
	}	

	my $attributes = dump_attributes ($cell -> {attributes});
	
	my $z_index = $cell -> {no_scroll} ? 'style="z-index:110"' : 'style="z-index:100"';

	return "<th $attributes $$cell{title} $z_index>$$cell{label}\&nbsp;</th>";

}

####################################################################

sub draw_table {

	my ($_SKIN, $tr_callback, $list, $options) = @_;

	$options -> {height}     ||= 10000;
	$options -> {min_height} ||= 200;
	
	$$options{toolbar} =~ s{^\s+}{}sm;
	$$options{toolbar} =~ s{\s+$}{}sm;

	my $html = '';
	
	foreach my $key (keys %_REQUEST) {
		next if $key =~ /^_/ or $key =~/^(type|action|sid|__last_query_string)$/;
		$html .= qq {<input type=hidden name=$key value="$_REQUEST{$key}">\n};
	}

	$html .= qq {<td class=bgr8>};
	
	$html .= $options -> {container} ?
		$options -> {container} :
			$options -> {no_scroll} ?
			qq {<div class="table-container-x">} :
			qq {<div class="table-container" style="height: expression(actual_table_height(this,$$options{min_height},$$options{height},'$__last_centered_toolbar_id'));">};

	$html .= qq {<table cellspacing=1 cellpadding=0 width="100%" id="scrollable_table" lpt=$$options{lpt}>\n};

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
				$html  .= qq{ oncontextmenu="open_popup_menu('$i'); blockEvent (event);"};
			}

			$html .= '>';
			$html .= qq {<a target="$$i{__target}" href="$$i{__href}">} if $i -> {__href} && ($_REQUEST {__read_only} || !$_REQUEST {id});
			$html .= $tr;
			$html .= qq {</a>} if $i -> {__href} && ($_REQUEST {__read_only} || !$_REQUEST {id});
			$html .= '</tr>';
			
		}
		
	}

	$html .= <<EOH;
			</tbody></table></div>$$options{toolbar}</td></form></tr></table>
		$menus
		
EOH

	$__last_centered_toolbar_id = '';
	
	my $enctype = $html =~ /\btype\=[\'\"]?file\b/ ? 
		'enctype="multipart/form-data"' : '';

	return <<EOH . $html;
	
		$$options{title}
		$$options{path}
		$$options{top_toolbar}

		<table cellspacing=0 cellpadding=0 width="100%">
			<tr>
				<form name=$$options{name} action=$_REQUEST{__uri} method=post target=invisible $enctype>
					<input type=hidden name=type value=$$options{type}>
					<input type=hidden name=action value=$$options{action}>
					<input type=hidden name=sid value=$_REQUEST{sid}>
					<input type=hidden name=__tree value=$_REQUEST{__tree}>
					<input type=hidden name=__last_query_string value="$_REQUEST{__last_last_query_string}">
					<input type=hidden name=__last_scrollable_table_row value="$_REQUEST{__last_scrollable_table_row}">
EOH

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

	if ($_REQUEST {__only_menu}) {

		my $a = $_JSON -> encode ([$page -> {menu}]);
		my $menu_md5 = Digest::MD5::md5_hex (freeze ($page -> {menu_data}));

		return <<EOH;
<html>
	<head>
		<script src="$_REQUEST{__static_url}/navigation.js?$_REQUEST{__static_salt}">
		</script>
		<script for=window event=onload>
			var wm = ancestor_window_with_child ('main_menu');
			if (wm) {
				var a = $a;
				wm.window.ChangeMenuPlease (a[0], '$menu_md5');
			}

		</script>
	<head>
	<body>
	</body>
</html>
EOH
	}

	
	$_REQUEST {__scrollable_table_row} ||= 0;
		
	$_REQUEST {__head_links} .= <<EOH if $_REQUEST {__meta_refresh};
		<META HTTP-EQUIV=Refresh CONTENT="$_REQUEST{__meta_refresh}; URL=@{[create_url()]}&__no_focus=1">
EOH

	my $request_package = ref $apr;
	my $mod_perl = $ENV {MOD_PERL};
	$mod_perl ||= 'NO mod_perl AT ALL';
								
	my $parameters = ref ${$_PACKAGE . 'apr'} eq 'Apache2::Request' ? ${$_PACKAGE . 'apr'} -> param : ${$_PACKAGE . 'apr'} -> parms;

	my $body = '';
#	my $onKeyDown = '';	
	my $body_scroll = 'yes';
	
	if (!$_USER -> {id}) {
		
		$body = $page -> {body};
		$body_scroll = 'no';
		$$page{auth_toolbar} = '';
		$_REQUEST {__head_links} .= <<EOH;
			<script src="$_REQUEST{__static_url}/navigation.js?$_REQUEST{__static_salt}">
			</script>
			<script src="$_REQUEST{__static_url}/navigation_setup.js?$_REQUEST{__static_salt}">
			</script>
EOH
		
	}
	elsif (($parameters -> {__subset} || $parameters -> {type}) && !$_REQUEST {__top}) {
	
		$$page{auth_toolbar} = '';
		
#		$body = $page -> {menu} . $page -> {body};
		$body = $page -> {body} . "<div style='display:none'>$_REQUEST{__menu_links}</div>";
		
		my %h = %$parameters;
		delete $h {salt};
		delete $h {_salt};
		
		my $url_dump = create_url (__dump => 1);

		my $href = create_url (%h);

		$_REQUEST {__on_load} .= "check_top_window ();";

		$preconf -> {core_show_dump} and $_REQUEST {__on_mousedown} .= <<EODUMP;

		    if (event.button == 2 && event.ctrlKey) {
    			nope ('$url_dump', '_blank', 'toolbar=no,resizable=yes,scrollbars=yes');
		    }
		    
EODUMP

		$_REQUEST {__on_keydown} = <<EOJS;
		
//			if (code_alt_ctrl (event, 88, 1, 0)) {
//				nope ('$_REQUEST{__uri}?type=_logout&sid=$_REQUEST{sid}&salt=@{[rand]}', '_top', '');
//				blockEvent (event);
//			}
			
			if (code_alt_ctrl (event, 116, 0, 0)) {
			
				if (is_dirty) {
				
					if (!confirm ('Внимание! Вы изменили содержимое некоторых полей ввода. Перезагрузка страницы приведёт к утере этой информации. Продолжить?')) return blockEvent (event);
				
				}
			
				window.location.href = encode1251 ('$href');
				
				return blockEvent (event);
			
			}
			
			handle_basic_navigation_keys (event);
			
EOJS

		foreach my $r (@{$page -> {scan2names}}) {
			next if $r -> {off};
			$r -> {alt}  += 0;
			$r -> {ctrl} += 0;
			$r -> {data} .= '';
			my $i = 2 * $r -> {alt} + $r -> {ctrl};
			$_REQUEST {__on_load} .= "\nkb_hooks [$i] [$r->{code}] = [handle_hotkey_$r->{type}, ";
			foreach (qw(ctrl alt off type code)) {delete $r -> {$_}}
			$_REQUEST {__on_load} .=  $_JSON -> encode ($r);
			$_REQUEST {__on_load} .= '];';
		}

		$_REQUEST {__on_keydown} .= "if (code_alt_ctrl (event, 115, 0, 0)) return blockEvent (event);";

		if ($_REQUEST {sid} && !$preconf -> {no_keepalive}) {
			my $timeout = 1000 * (60 * $conf -> {session_timeout} - 1);
			$_REQUEST {__on_load} .= "start_keepalive ($timeout);";
		}

		my $menu_md5 = Digest::MD5::md5_hex (freeze ($page -> {menu_data}));

		$_REQUEST {__on_load} .= "check_menu_md5 ('$menu_md5');";
		$_REQUEST {__on_load} .= "idx_tables ($_REQUEST{__scrollable_table_row});";
		$_REQUEST {__on_load} .= 'window.focus ();'                             if !$_REQUEST {__no_focus};
		$_REQUEST {__on_load} .= "focus_on_input ('$_REQUEST{__focused_input}');" if  $_REQUEST {__focused_input};
		$_REQUEST {__on_load} .= $_REQUEST {__edit} ? " top.edit_mode = 1;" : " top.edit_mode = 0;"
			unless ($_REQUEST {select});
	
		$_REQUEST {__on_mouseover} .= <<EOS;
			window.parent.subsets_are_visible = 0;
			subsets_are_visible = 0;
EOS

	}
	else {
	
		my $href = create_url (__subset => $_SUBSET -> {name});
		$body_scroll = 'no';
				
		$_REQUEST {__on_load} = <<EOS;
			window.focus ();
			StartClock ();
EOS
		
		$body = <<EOIFRAME;
			<iframe 
				name='_body_iframe' 
				id='_body_iframe' 
				src="$href"
				width=100% 
				height=100% 
				border=0 
				frameborder=0 
				marginheight=0 
				marginwidth=0
				application=yes
			>
			</iframe>
EOIFRAME

	
		if (ref $_REQUEST {__every_second} eq ARRAY) {
		
			for (my $i = 0; $i < @{$_REQUEST{__every_second}}; $i++) {$body .= "<iframe name='_every_second_$i' src='$_REQUEST{__static_url}/0.html' style='display:none'></iframe>"}
			
			$_REQUEST {__script} .= ' every_second = ' . $_JSON -> encode ($_REQUEST {__every_second}) . ';';
		
		}
	
	}
	
	my $menu_md5 = Digest::MD5::md5_hex (freeze ($page -> {menu_data}));
	
	my $__read_only = $_REQUEST {id} ? 0 + $_REQUEST {__read_only} : 1;
	
	$_REQUEST {__script} .= <<EOH;

		var edit_mode = null;
		var menu_md5 = '$menu_md5';
		var __read_only = $__read_only;
		var __last_last_query_string = '$_REQUEST{__last_query_string}';

EOH

	if ($preconf -> {core_unblock_navigation}) {
	
		$_REQUEST {__script} .= <<EOH;

			function check_edit_mode (a, fallback_href) {

				if (edit_mode) {

					var arg   = Array ();
					arg.href  = a.href ? a.href : fallback_href;
					arg.title = a.innerText;

					window.showModelessDialog('$ENV{SCRIPT_URI}/i/_skins/TurboMilk/dialog.html?$_REQUEST{__static_salt}', arg, 'resizable:yes;unadorned:yes;status:yes');
					document.body.style.cursor = 'default'; 
					blockEvent (event);
					return true;

				}

				return false;

			}
EOH
			
	
	}
	else {
	
		$_REQUEST {__script} .= <<EOH;

			function check_edit_mode (a, fallback_href) {

				if (edit_mode) {

					alert('$$i18n{save_or_cancel}'); 
					document.body.style.cursor = 'default'; 
					return true;

				}

				return false;

			}
EOH
	
	}

	if ($$page{auth_toolbar}) {
		$$page{auth_toolbar} = "<tr height=48><td height=48>$$page{auth_toolbar}</td></tr><tr><td>$$page{menu}</td></tr>";
	}
		
	$_REQUEST {__head_links} .= <<EOH unless ($_REQUEST {type} eq '_boot');
		<LINK href="$_REQUEST{__static_url}/eludia.css?$_REQUEST{__static_salt}" type=text/css rel=STYLESHEET>
		<style>
			.calendar 
			.nav { background: transparent url($_REQUEST{__static_url}/menuarrow.gif) no-repeat 100% 100%; }
			td.main-menu {padding-top:1px; padding-bottom:1px; background-image: url($_REQUEST{__static_url}/menu_bg.gif); }
			td.vert-menu {background-color: #454a7c;font-family: Tahoma, 'MS Sans Serif';font-weight: normal;font-size: 8pt;color: #ffffff;text-decoration: none;padding-top:4px;padding-bottom:4px;background-image: url($_REQUEST{__static_url}/menu_bg.gif);}
			/*
			#admin {width:205px;height:25px;padding:5px 5px 5px 9px;background:url('$_REQUEST{__static_url}/menu_button.gif') no-repeat 0 0;}
			*/
			td.login-head {/*background:url('$_REQUEST{__static_url}/login_title_pix.gif') repeat-x 1 1 #B9C5D7;*/font-size:10pt;font-weight:bold;padding:7px;}
			td.submit-area {text-align:center;height:36px;background:url('$_REQUEST{__static_url}/submit_area_bgr.gif') repeat-x 0 0;}
			div.green-title {color:#ffffff;font-weight:bold;background:url('$_REQUEST{__static_url}/green_ear_left.gif') no-repeat 0 0; width:300px;padding-left:10%;}
			td.grey-submit a {color:#222323;text-decoration:none;}
			td.grey-submit a:hover {color:#222323;text-decoration:underline;}
		</style>
EOH

	foreach (@{$_REQUEST {__include_css}}) {
		$_REQUEST {__head_links} .= <<EOH;
			<LINK href="$_REQUEST{__static_site}/i/$_.css" type=text/css rel=STYLESHEET>
EOH
	}

	$_REQUEST {__head_links} .= <<EOH unless ($_REQUEST {type} eq 'logon' or $_REQUEST {type} eq '_boot');
		<script src="$_REQUEST{__static_url}/navigation.js?$_REQUEST{__static_salt}">
		</script>
EOH

	foreach (@{$_REQUEST {__include_js}}) {
		$_REQUEST {__head_links} .= <<EOH;
			<script type="text/javascript" src="$_REQUEST{__static_site}/i/${_}.js?$_REQUEST{__static_salt}">
			</script>
EOH
	}
	
	$_REQUEST {__on_help} = <<EOHELP if $_REQUEST {__help_url};
		nope ('$_REQUEST{__help_url}', '_blank', 'toolbar=no,resizable=yes');
		blockEvent (event);
EOHELP

	foreach (keys %_REQUEST) {
	
		/^__on_(\w+)$/ or next;
		
		if ($1 eq 'load') {
			$_REQUEST {__head_links} .= <<EOH;
			<script>
				function init() {
                   				$_REQUEST{$&};
                			}
			</script>
			<script for="window" event="onload">
                        		document.addEventListener("DOMContentLoaded", init, false);
            		</script>
EOH
		} else {
			$_REQUEST {__head_links} .= <<EOH;
			<script>
				function _body_on_$1(event) {
					$_REQUEST{$&};
				}
			</script>
EOH
			$_REQUEST {__body_event} .= " on$1='_body_on_$1(event);' ";
		}

	}
	



#	$body_scroll = 'no' if $_REQUEST {__tree};

	$body =~ /\<frameset/ or $body = <<EOH;
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
				onbeforeunload="document.body.style.cursor = 'wait'"
				$_REQUEST{__body_event}
			>
				
				<table id="body_table" cellspacing=0 cellpadding=0 border=0 width=100% height=100%>
					$$page{auth_toolbar}
					<tr><td valign=top height=100%>
						$body
					</td></tr>
				</table>

@{[ map {<<EOI} @{$_REQUEST{__invisibles}} ]}
					<iframe name='$_' src="$_REQUEST{__static_url}/0.html" width=0 height=0 application="yes" style="display:none">
					</iframe>
EOI

			</body>
EOH

	
	unless ($r -> headers_in -> {'User-Agent'} =~ /MSIE 7/) {
		
		$_REQUEST {__script} .= <<EOS;

			function select_visibility () {
				if (top.last_vert_menu && top.last_vert_menu [0]) return 'hidden';
				if (last_vert_menu [0]) return 'hidden';
				if (subsets_are_visible) return 'hidden';
				return '';
			}

			function cell_select_visibility (select, fixed_cols) {

				var td    = select.offsetParent;
				var tr    = td.parentNode;
				var cells = tr.cells;
				var last_fixed_cell_offset_right = 0;

				for (i = 0; i < fixed_cols; i ++) {
					last_fixed_cell_offset_right += cells [i].offsetWidth;
				}

				var table = td.offsetParent;
				var div   = table.offsetParent;
				var select_left = select.offsetLeft + td.offsetLeft - div.scrollLeft;
				var result = select_left < last_fixed_cell_offset_right ? 'hidden' : '';

				return result;

			}

EOS
	
	}
	

		$_REQUEST {__script} .= <<EOS;
				

EOS



	
	return <<EOH;
		<html>		
			<head>
				<title>$$i18n{_page_title}</title>
								
				<meta name="Generator" content="Eludia ${Eludia::VERSION} / $$SQL_VERSION{string}; parameters are fetched with $request_package; gateway_interface is $ENV{GATEWAY_INTERFACE}; $mod_perl is in use">
				<meta http-equiv=Content-Type content="text/html; charset=$$i18n{_charset}">
								
				$_REQUEST{__head_links}							

				<script>
					var every_second = [];
					var clockSeparators = ['$_REQUEST{__clock_separator}', ' '];
					var keepalive_url = "$_REQUEST{__uri}?keepalive=$_REQUEST{sid}";
					$_REQUEST{__script}
				</script>

				@{[ $_REQUEST{__help_url} ? <<EOHELP : '' ]}
					<script for="body" event="onhelp">
						nope ('$_REQUEST{__help_url}', '_blank', 'toolbar=no,resizable=yes');
						event.returnValue = false;
					</script>						
EOHELP

			</head>
			$body
		</html>
		
EOH

}

################################################################################

sub handle_hotkey_focus {

	my ($r) = @_;
	
	$r -> {ctrl} += 0;
	$r -> {alt}  += 0;

	<<EOJS
		if (code_alt_ctrl (event, $$r{code}, $r->{alt}, $r->{ctrl})) {
			document.form.$$r{data}.focus ();
			return blockEvent (event);
		}
EOJS

}

################################################################################

sub handle_hotkey_focus_id {

	my ($r) = @_;

	$r -> {ctrl} += 0;
	$r -> {alt}  += 0;

	<<EOJS
		if (code_alt_ctrl (event, $$r{code}, $r->{alt}, $r->{ctrl})) {
			document.getElementById ('$r->{data}').focus ();
			return blockEvent (event);
		}
EOJS

}

################################################################################

sub handle_hotkey_href {

	my ($r) = @_;
	
	$r -> {ctrl} += 0;
	$r -> {alt}  += 0;
	
	my $condition = 
		$r -> {off}     ? '0' :
		$r -> {confirm} ? 'window.confirm(' . js_escape ($r -> {confirm}) . ')' : 
		'1';
			
	my $code = !$r -> {href} ? "activate_link_by_id (event, '$$r{data}')" : "nope ('$$r{href}&__from_table=1&salt=' + Math.random () + '&' + scrollable_rows [scrollable_table_row].id, '_self');";

	$condition eq '1' or $code = "if ($condition) {$code}";
	

	return <<EOJS
		if (code_alt_ctrl (event, $$r{code}, $r->{alt}, $r->{ctrl})) $code;
EOJS

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

	my ($_SKIN, $options) = @_;

	if ($options -> {hta}) {
	
		$_REQUEST {__on_load} .= <<EOH;
		
			if (window.name != 'application_frame' && confirm ('$i18n->{hta_confirm}')) {
											
				var _hta = hta ();
			
				SetupHTA (
					_hta.code, 
					_hta.title, 
					_hta.url, 
					_hta.content, 
					_hta.icon, 
					_hta.hotkey
				);
			
			}
		
EOH
		
		
	
	}







	$_REQUEST {__on_load} .= $_COOKIES{user_login} && $_COOKIES{user_login}->value ? 
		'document.forms[0].elements["password"].focus (); '
		:
		'document.forms[0].elements["login"].focus (); ';
	
	if ($preconf -> {core_fix_tz}) {
		my $tz = (Date::Calc::Timezone ()) [3] || 0;
		$_REQUEST {__on_load} .= " var d = new Date(); document.form.tz_offset.value=$tz - d.getTimezoneOffset()/60;";
	} 
	
	return <<EOH;

<table border="0" cellpadding="0" cellspacing="0" align=center height=100% width=100%>

	<tr>

		<td valign=top height=90>
			<table id="logo_table" cellSpacing=0 cellPadding=0 width="100%" border=0 bgcolor="#e5e5e5" background="$_REQUEST{__static_site}/i/bg_logo_out.gif" style="background-repeat: repeat-x" height=90>
				<tr>
				<td width="20"><img src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=20 height=90 border=0></td>
				<td width=1><table border=0 valign="middle" border=0><tr>
					<td valign="top" width=1><img src="$_REQUEST{__static_site}/i/logo_out.gif" border="0"></td>
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
						<form action="$_REQUEST{__uri}" method=post autocomplete="off" name=form target="$options->{target}">
							<input type=hidden name=type value=logon>
							<input type=hidden name=action value=execute>
							<input type=hidden name=redirect_params value="$_REQUEST{redirect_params}">
							<input type=hidden name=tz_offset value="">
<!--							
							<tr>
								<td colspan="2" align="center"><a id="logon_url" style="text-decoration:none" href="javascript: document.forms['form'].elements['action'].value='execute_ip'; document.forms['form'].submit()"><div class="green-title"><div style="float:left;margin-top:6px;">Войти как Овсянко Дмитрий Евгеньевич</div><div style="float:right;"><img src="$_REQUEST{__static_site}/i/logon_turbo_milk/images/green_ear_right.gif" border="0"></div></div></td>
							</tr>
-->							
							<tr class="logon">
								<td><b>Логин:</b></td>
								<td><input type="text" name="login" value="${\( $_COOKIES{user_login} && $_COOKIES{user_login}->value )}" style="width:200px;" onfocus="q_is_focused = true" onblur="q_is_focused = false" onKeyPress="if (event.keyCode == 13) form.password.focus ()"></td>
							</tr>
							<tr class="logon">
								<td><b>Пароль:</b></td>
								<td><input type="password" name="password" style="width:200px;" onfocus="q_is_focused = true" onblur="q_is_focused = false" onKeyPress="if (event.keyCode == 13) form.submit ()"></td>
							</tr>
							
							
						</form>
						</table>
					</td>
				</tr>

				<tr>
					<td align=center>
						<table width=1>
							<tr>
								<td><img src="$_REQUEST{__static_url}/i_logon.gif?$_REQUEST{__static_salt}" border="0" align="left" hspace="5"></td>
								<td nowrap class="grey-submit"><a class="lnk0" href="javascript:document.forms['form'].submit()">Войти в систему</a></td>
							</tr>
						</table>

<!--						
						<div class="grey-submit">
							<div style="float:left;margin-top:5px;"><a href="#"><img src="$_REQUEST{__static_url}/i_logon.gif?$_REQUEST{__static_salt}" border="0" align="left" hspace="5"></a><a href="javascript:document.forms['form'].submit()">Войти в систему</a></div>
							<div style="float:right;"><img src="$_REQUEST{__static_url}/grey_ear_right.gif?$_REQUEST{__static_salt}" border="0"></div>
						</div>
-->						
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

################################################################################

sub draw_tree {

	my ($_SKIN, $node_callback, $list, $options) = @_;
	
	my $menus = '';
	my @nodes = ();
	
	my ($root_id, $root_url, $selected_node_url, $selected_code);
	
	our %idx = ();
	our %lch = ();
		
	foreach my $i (@$list) {

		my $node = $i -> {__node};

		push @nodes, $node;
		
		($root_id, $root_url) = ($node -> {id}, $node -> {url}) unless $root_id;
			
		if ($node -> {id} == $options -> {selected_node}) {
			$selected_node_url = $node -> {url};
			$selected_code = 'win.d.selectedFound = true; win.d.selectedNode = ' . (@nodes - 1);
		}
       		
		$idx {$node -> {id}} = $node;
		$lch {$node -> {pid}} = $node if $node -> {pid};
		$menus .= $i -> {__menu};

	}
	
	unless ($selected_node_url) {
    		$options -> {selected_node} = $root_id;
    		$selected_node_url = $root_url;             	 
  	}
	
	while (my ($k, $v) = each %lch) {
		$idx {$k} -> {_hc} = 1;
		$v -> {_ls} = 1;
	}
	
	my $nodes = $_JSON -> encode (\@nodes);
	
	if ($options -> {active} && $_REQUEST {__parent}) {
	
		my $m = $_JSON -> encode ([$menus]);

		return out_html ({}, <<EOH);
<html>
	<head>
		<script>
			
			function load () {
			
				var new_nodes = $nodes;
				for (i = 0; i < new_nodes.length; i++) {		
					var node = new_nodes [i];		
					if (node.title) continue;			
					node.title = node.label;		
				}
				var m = $m;
				var f = window.parent.parent.document.getElementById ('__tree_iframe');
				var d = f.contentWindow.d;
				var old_nodes = d.aNodes;
				var n = -1;

				for (i = 0; i < old_nodes.length; i ++) {			
					var cn = old_nodes [i];
					if (cn.id != $_REQUEST{__parent}) continue;	
					n = i;
					cn._hac += new_nodes.length;
					cn._io = true;
					break;
				};

				var k = 0;
				var nodes = [];			

				for (i = 0;     i <= n;               i ++) nodes [k++] = old_nodes [i];
				for (i = 0;     i < new_nodes.length; i ++) nodes [k++] = new_nodes [i];
				for (i = n + 1; i < old_nodes.length; i ++) nodes [k++] = old_nodes [i];

				d.aNodes = nodes;

				f.contentWindow.document.getElementById ('dtree_td').innerHTML = d.toString ();
				f.contentWindow.document.getElementById ('dtree_menus').innerHTML += m [0];				
				f.contentWindow.document.body.style.cursor = 'default';
				
			}
			
		</script>
	</head>
	<body onLoad="load ()"></body>
</html>
EOH
	
	}

	$menus =~ s{[\n\r]+}{ }gsm;
	$menus =~ s/\"/\\"/gsm;  #"
	
	$options -> {active} += 0;
	
	my $useCookies = $options -> {active} ? 'false' : 'true';
	
	$_REQUEST {__on_load} .= <<EOH;
		var win = document.getElementById ('__tree_iframe').contentWindow;
		win.d = new win.dTree ('d');
		var c = win.d.config;
		c.iconPath = '$_REQUEST{__static_url}/tree_';
		c.target = '_content_iframe';
		c.useStatusText = true;
		c.useCookies = $useCookies;
		win.d.icon.node = 'folderopen.gif';
		
		var nodes = $nodes;
		
		for (i = 0; i < nodes.length; i++) {		
			var node = nodes [i];		
			if (node.title) continue;			
			node.title = node.label;		
		}
		
		win.d.aNodes = nodes;

		win.d._active = $options->{active};
		win.d._href = '$options->{href}';
		$selected_code
		
		var styleNode = win.document.createElement("STYLE");
        styleNode.type = "text/css";
        win.document.body.appendChild(styleNode);
        win.document.styleSheets[0].addRule('td.vert-menu', "background-color: #454a7c;font-family: Tahoma, 'MS Sans Serif';font-weight: normal;font-size: 8pt;color: #ffffff;text-decoration: none;padding-top:4px;padding-bottom:4px;background-image: url($_REQUEST{__static_url}/menu_bg.gif);");
		
		win.document.body.innerHTML = "<table class=dtree width=100% height=100% celspacing=0 cellpadding=0 border=0><tr><td id='dtree_td' valign=top>" + win.d + "</td></tr></table><div id='dtree_menus'>$menus</div>";
@{[ $options->{selected_node} ? <<EOO : '' ]}		
		if (win.d.selectedNode == null || win.d.selectedFound) {
			win.d.openTo ($options->{selected_node}, true);
		}
EOO
EOH

	return <<EOH;
		<frameset cols="$options->{width},*">
			<frame src="$ENV{SCRIPT_URI}/i/_skins/TurboMilk/0.html" name="_tree_iframe" id="__tree_iframe" application="yes">
			</frame>
			<frame src="${\($selected_node_url ? $selected_node_url : '$_REQUEST{__static_url}/0.html')}" name="_content_iframe" id="__content_iframe" application="yes" scroll=no>
			</frame>
		</frameset>
EOH

}

################################################################################

sub draw_node {

	my ($_SKIN, $options, $i) = @_;
	
	$options -> {label} =~ s{\"}{\&quot;}gsm; #"

	my $node = {
		id   => $options -> {id}, 
		pid  => $options -> {parent}, 
		name => $options -> {label}, 
		url  => $ENV {SCRIPT_URI} . $options -> {href},
		title   => $options -> {title} || $options -> {label},
		target  => $options -> {target},
		icon    => $options -> {icon},
		iconOpen    => $options -> {iconOpen},
		is_checkbox => $options -> {is_checkbox},
	};
	
	if ($options -> {title} && $options -> {title} ne $options -> {label}) {
		$node -> {title} = $options -> {title};
	}

	if ($i -> {cnt_children} > 0) {
		$node -> {_hc}  = 1;	
		$node -> {_hac} = 0 + $i -> {cnt_actual_children};	
		$node -> {_io}  = $i -> {id} == $_REQUEST {__parent} ? 1 : 0;
	}
	else {
		$node -> {_hc} = 0;	
	}
	
	$node -> {context_menu} = $i . '' if $i -> {__menu};

	return $node;

}

################################################################################

sub dialog_close {

	my ($_SKIN, $result) = @_;
	
	my $a = $_JSON -> encode ({
		result => $result,
		alert  => $_REQUEST {__redirect_alert},
	});
	
	$r -> content_type ("text/html; charset=$i18n->{_charset}");
	$r -> send_http_header ();
	$r -> print (<<EOH);
<html>
	<head>
		<script>
			
			function load () {
				var a = $a;
				if (a.alert) alert (a.alert);
				var w = window.parent.parent;		
				w.returnValue = a.result;
				w.close ();
			}
			
		</script>
	</head>
	<body onLoad="load ()"></body>
</html>
EOH

}

################################################################################

sub dialog_open {

	my ($_SKIN, $arg, $options) = @_;
		
	foreach (qw(status resizable help)) {$options -> {$_} ||= 'no'}
	
	$options -> {dialogHeight} ||= '150px';
	$options -> {dialogWidth}  ||= '600px';
	
	my $url = $ENV{SCRIPT_URI} . '/i/_skins/TurboMilk/dialog.html?';
	my $o = join ';', map {"$_:$options->{$_}"} keys %$options;
	
	return "javaScript:var result=window.showModalDialog('$url' + Math.random (), dialog_open_$options->{id}, '$o');document.body.style.cursor='default';void(0);";

}

################################################################################

sub draw_suggest_page {

	my ($_SKIN, $data) = @_;
			
	my $a = $_JSON -> encode ([map {[$_ -> {id}, $_ -> {label}]} @$data]);
	
	$size = 10 if $size > 10;
	
	return <<EOH;
<html>
	<head>
		<script>
			function r () {
			
				var a = $a;
				
				var s = parent.document.getElementById ('_$_REQUEST{__suggest}__suggest');
				
				var t = s.form.elements ['_$_REQUEST{__suggest}'];
				
				s.style.top    = t.offsetTop + t.offsetParent.offsetTop + t.offsetParent.offsetParent.offsetTop + 18; 
				s.style.width  = t.offsetWidth; 
				
				s.options.length = 0;
				for (var i = 0; i < a.length; i++) {
					var o = a [i];
					s.options [i] = new Option (o [1], o [0]);
				}
				
				if (a.length > 0) {
					s.size = a.length > 1 ? a.length : 2;
					s.style.display = 'block';
					parent.suggest_is_visible = 1;
				}
				else {
					s.style.display = 'none';
					parent.suggest_is_visible = 0;
				}
				
			}
		</script>
	</head>
	<body onLoad="r()"></body>
</html>
EOH

}

################################################################################

sub draw_form_field_article {

	my ($_SKIN, $field, $data) = @_;

	$field -> {value} =~ s{\n}{<br>}gsm;
	
	return qq{<table width=95% align=center cellpadding=10><tr minheight=200><td>$field->{value}</td></tr></table>};
	
}

1;
