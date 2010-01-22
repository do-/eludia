package Eludia::Presentation::Skins::IsUp;

use Data::Dumper;
use Storable ('freeze');

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
	return {home_esc_forward => 1};
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
#	my $logo_url = $conf -> {logo_url};
	my $logo_url = create_url (type => '', id => '', __subset => $_SUBSET -> {name});

	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime (time);
	
	$year += 1900;
	
	$_REQUEST {__clock_separator} ||= ':';
	
	my ($header, $header_height);
	
	my $header_prefix = 'out';
	
	if ($_USER -> {id}) {
	
		my $calendar = draw_calendar ();

		$header_height = 48;
		$header_prefix = 'in';

	} else {
		$header_height = 90;
	}

	return <<EOH;
		<table id="logo_table" cellSpacing=0 cellPadding=0 width="100%" border=0 bgcolor="#e5e5e5" background="$_REQUEST{__static_site}/i/bg_logo_$header_prefix.gif" style="background-repeat: repeat-x">

			<tr>

				<td rowspan=2 width="15"><img src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=15 height=$header_height border=0></td>

				<td rowspan=2 valign="middle" align="center" width=1><a href="$logo_url" target="_body_iframe"><img src="$_REQUEST{__static_site}/i/logo_$header_prefix.gif" border="0"></a></td>

				<td rowspan=2 width="20"><img src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=20 height=$header_height border=0></td>

				<td align="left" valign="middle" class='header_0' width=*><nobr id="nobr_page_title">$$conf{page_title}</nobr></td>

				<td align="center" width="30" class="txt1"><span id="clock_hours"></span><span id="clock_separator" style="width:5px"></span><span id="clock_minutes"></td>

				<td rowspan=2 width="20" align="right">&nbsp;</td>

				<td rowspan=2 valign="middle" align="center" width=38><a height=30 href="$logo_url"><img width=38 src="$_REQUEST{__static_url}/diary.gif?$_REQUEST{__static_salt}" border="0"></a></td>
			
				<td rowspan=2 width="20" align="right">&nbsp;</td>

				<td rowspan=2 width="50" align="right" nowrap><nobr><a class="button" href="$logout_url">&nbsp;$i18n->{Exit}&nbsp;<img src="$_REQUEST{__static_url}/i_exit.gif?$_REQUEST{__static_salt}" width="14px" height="10px" border="0"></a></nobr></td>

				<td rowspan=2 width="20" align="right">&nbsp;</td>

			</tr>
			<tr>
				<td valign=top align="left" class="txt1">$$options{user_label}</td>
				<td valign=top width=1 nowrap align="left" class="txt1"><nobr>$mday $i18n->{months}->[$mon] $year</nobr></td>
			</tr>
			
		 </table>
EOH


}

################################################################################

sub draw_window_title {

	my ($_SKIN, $options) = @_;

	return ''
		if $_REQUEST {select};
	
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
	
	$html .= $options -> {bottom_toolbar};

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

	$html .= $options -> {footer};
	
	$html .= $options -> {bottom_toolbar} unless $options -> {no_bottom_bottom_toolbar};
	
	return $html;	

}


################################################################################

sub draw_path {

	my ($_SKIN, $options, $list) = @_;

	my $style = $options -> {nowrap} ? qq{style="background:url('$_REQUEST{__static_url}/bgr_grey.gif?$_REQUEST{__static_salt}');background-repeat:repeat-x;"} : '';
	
	my $page_title = $_JSON -> encode ([$list -> [-1] -> {label} || 'Новая запись']);	
	
	$_REQUEST {__only_form} or $_REQUEST {__on_load} .= <<EOH;
	
		var page_title = $page_title;
		
		var nobr_page_title = parent.document.getElementById ('nobr_page_title');
		
		if (nobr_page_title) nobr_page_title.innerText = page_title [0];

EOH
	
		
	my $path = <<EOH;
		<table cellspacing=0 cellpadding=0 width="100%" border=0>
			<tr>
				<td>
					<table cellspacing=0 cellpadding=0 width="100%" border=0>
						<tr>
							<td _class=toolbar width=9><img height=29 src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=9 border=0></td>
							<td _class=toolbar width=1><nobr><a href="$options->{esc}#" target="$options->{path_target}"><img src="$_REQUEST{__static_url}/i_left.gif?$_REQUEST{__static_salt}" border=0 hspace=3 vspace=0 align=absmiddle></a><a href="$options->{forward}#"  target="$options->{path_target}"><img src="$_REQUEST{__static_url}/i_right.gif?$_REQUEST{__static_salt}" border=0 hspace=3 vspace=0 align=absmiddle></a></nobr></td>
							<td _class=toolbar width=3><img height=29 src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=15 border=0></td>
							<td _class=toolbar $$options{nowrap}>
EOH

	for (my $i = 0; $i < @$list; $i ++) {
	
		if ($i > 0) {
			$path .= '&nbsp;/&nbsp;';
			if ($options -> {multiline}) {
				$path .= '<br>';
				for (my $j = 0; $j < $i + 2; $j++) { $path .= '&nbsp;&nbsp;' }
			}
		}
		
		my $item = $list -> [$i];		
		
		$path .= qq{<a class=path ${\($$item{href} ? "href='$$item{href}' target='$options->{path_target}'" : '')} TABINDEX=-1>$$item{label}</a>};
	
	}
	
	$path .= <<EOH;
&nbsp;</td>
						</tr>
						<tr>
							<td bgcolor="#e4e9ee" colspan=5><img height=1 src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=1 border=0></td>
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

sub draw_form_field_article {

	my ($_SKIN, $field, $data) = @_;

	$field -> {value} =~ s{\n}{<br>}gsm;
	
	return qq{<table width=95% align=center cellpadding=10><tr minheight=200><td>$field->{value}</td></tr></table>};
	
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
	
	$options -> {attributes} -> {onKeyPress} .= ';if (window.event.keyCode != 27) is_dirty=true;';
	$options -> {attributes} -> {onKeyDown}  .= ';tabOnEnter();';
	$options -> {attributes} -> {onFocus}    .= ';scrollable_table_is_blocked = true; q_is_focused = true;';
	$options -> {attributes} -> {onBlur}     .= ';scrollable_table_is_blocked = false; q_is_focused = false;';

	return '<input type="text"' . dump_attributes ($options -> {attributes}) . ' >';

}

################################################################################

sub draw_form_field_datetime {

	my ($_SKIN, $options, $data) = @_;
		
	$options -> {name} = '_' . $options -> {name};
	$options -> {onKeyDown} ="tabOnEnter()";

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
		delete $value -> {attributes} -> {onclick};
	
		my $attributes = dump_attributes ($value -> {attributes});
		
		$html .= qq {\n<tr><td class="form-inner" valign=top width=1%><nobr><input class=cbx $attributes id="$value" onFocus="scrollable_table_is_blocked = true; q_is_focused = true" onBlur="scrollable_table_is_blocked = false; q_is_focused = false" type="radio" name="_$$options{name}" value="$$value{id}" onClick="is_dirty=true;$$value{onclick}" onKeyDown="tabOnEnter()">&nbsp;$$value{label}</nobr>};
							
		$value -> {html} or next;
		
		$html .= qq{\n\t\t<td class="form-inner"><div style="display:expression(getElementById('$value').checked ? 'block' : 'none')">$$value{html}</div>};
				
	}
	
	$html .= '</table>';
		
	return $html;
	
}

################################################################################

sub draw_form_field_select {

	my ($_SKIN, $options, $data) = @_;
	
	$options -> {attributes} ||= {};
	$options -> {attributes} -> {style} ||= 'visibility:expression(select_visibility())' if $r -> headers_in -> {'User-Agent'} !~ /MSIE 7/;
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

					var result = window.showModalDialog ('$_REQUEST{__static_url}/dialog.html?@{[rand ()]}', {href: '$options->{other}->{href}&select=$options->{name}'}, 'status:no;resizable:yes;help:no;dialogWidth:' + dialog_width + 'px;dialogHeight:' + dialog_height + 'px');
					
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

						var result = window.showModalDialog ('$_REQUEST{__static_url}/dialog.html?@{[rand ()]}', {href: '$options->{other}->{href}&select=$options->{name}'}, 'status:no;resizable:yes;help:no;dialogWidth:' + dialog_width + 'px;dialogHeight:' + dialog_height + 'px');
						
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
			onKeyDown="tabOnEnter()"
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

	$html .= $options -> {height} ? qq{<div class="checkboxes" style="height:$$options{height}px;" id="input_$$options{name}">} : qq{<div id="input_$$options{name}">};
	
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

	$html .= '</div>';
	
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

	-r $r -> document_root . "/i/_skins/IsUp/i_$_[0].gif" ?
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

	my $name = $$options{name};

	$name = "_$name" if defined $options -> {other};

	my $read_only = $options -> {read_only} ? 'disabled' : ''; 

	if (defined $options -> {other}) {
		$options -> {other} -> {width}  ||= $conf -> {core_modal_dialog_width} || 600;
		$options -> {other} -> {height} ||= $conf -> {core_modal_dialog_height} || 400;

		$options -> {no_confirm} ||= $conf -> {core_no_confirm_other};

		if ($options -> {no_confirm}) {

			$options -> {onChange} .= <<EOJS;

				if (this.options[this.selectedIndex].value == -1) {

					var result = window.showModalDialog ('$_REQUEST{__static_url}/dialog.html?@{[rand ()]}', {href: '$options->{other}->{href}&select=$name'}, 'status:no;resizable:yes;help:no;dialogWidth:$options->{other}->{width}px;dialogHeight:$options->{other}->{height}px');
					
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

						var result = window.showModalDialog ('$_REQUEST{__static_url}/dialog.html?@{[rand ()]}', {href: '$options->{other}->{href}&select=$name'}, 'status:no;resizable:yes;help:no;dialogWidth:$options->{other}->{width}px;dialogHeight:$options->{other}->{height}px');
						
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
	$options -> {attributes} -> {style} ||= 'visibility:expression(select_visibility())' if $r -> headers_in -> {'User-Agent'} !~ /MSIE 7/;
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
	$options -> {attributes} -> {style} ||= 'visibility:expression(select_visibility())' if $r -> headers_in -> {'User-Agent'} !~ /MSIE 7/;
	my $attributes = dump_attributes ($options -> {attributes});

	$html .= <<EOH;
		<input 
			onKeyPress="if (window.event.keyCode == 13) {form.submit()}" 
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
	
	return <<EOH if $options -> {type} eq 'break';
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
					<table cellspacing=0 cellpadding=0 width="100%" border=0>
						<tr>
							<td width="45%">
								<table cellspacing=0 cellpadding=0 width="100%" border=0>
									<tr>
										<td background="$_REQUEST{__static_url}/cnt_tbr_bg.gif?$_REQUEST{__static_salt}"><img height=40 hspace=0 src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=1 border=0></td>
									</tr>
								</table>
							</td>
				
EOH

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

return '';

#	my ($_SKIN, $_options) = @_;

#	my @types = (@{$_options -> {left_items}}, BREAK, @{$_options -> {right_items}});

#	my $colspan = 1 + @types;

#	my $html = <<EOH;

#	<div style="position:relative" id="main_menu">

#		<table width="100%" class=bgr8 cellspacing=0 cellpadding=0 border=0>
#			<tr>
#				<td background="$_REQUEST{__static_url}/menu_bg.gif?$_REQUEST{__static_salt}" width=1><img height=26 src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=1 border=0></td>
#				<td background="$_REQUEST{__static_url}/menu_bg_s.gif?$_REQUEST{__static_salt}" width=0><img height=26 src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=0 border=0></td>
#EOH

#	foreach my $type (@types) {

#		next if ($type -> {name} eq '_logout');

#		$_REQUEST {__menu_links} .= "<a id='main_menu_$$type{name}' target='$$type{target}' href='$$type{href}'>-</a>";

#		$type -> {target} = '_body_iframe' if $type -> {target} eq '_self';

#		if ($type eq BREAK) {
#			$html .= qq{<td background="$_REQUEST{__static_url}/menu_bg.gif?$_REQUEST{__static_salt}" width=100%><img height=1 src="$_REQUEST{__static_url}/0.gif?$_REQUEST{__static_salt}" width=1 border=0></td>};
#			next;
#		}

#		$html .= <<EOH;
#			<td onmouseover="$$type{onhover}; subsets_are_visible = 0;" onmouseout="$$type{onmouseout}" class="main-menu" nowrap>&nbsp;
#				<a class="main-menu" id="main_menu_$$type{name}" target="$$type{target}" href="$$type{href}" tabindex=-1>&nbsp;$$type{label}&nbsp;</a>&nbsp;
#			</td>
#EOH

#	}

#	$html .= <<EOH;
#		</table>
#EOH

#	foreach my $type (@types) {
#		$html .= $type -> {vert_menu};
#	}

#	$html .= <<EOH;
#	</div>
#EOH

#	return $html;
	
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
		question => "$i18n->{confirm_close_vocabulary} \"$item->{label}\"?",
		id       => $item -> {id},
		label    => $item -> {label},
	});

	my $var = "so_" . (0 + $item);

	$_REQUEST {__script} .= " var $var = $a; ";

	return "javaScript:invoke_setSelectOption ($var)";

}

################################################################################

sub draw_text_cell {

	my ($_SKIN, $data, $options) = @_;
	
	my $data_original;

	if ($data -> {no_scroll}) {
		$data_original = Storable::dclone ($data);
	}
	
	if (defined $data -> {level}) {
		$data -> {attributes} -> {style} .= '; padding-left:';
		$data -> {attributes} -> {style} .= ($data -> {level} * 15 + 5);
	}
	
	my $html = "\n\t<td ";
	$html .= dump_attributes ($data -> {attributes}) if $data -> {attributes};
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

		if ($data -> {href}) {
		
			$html .= $data -> {href} eq $options -> {href} ? '<span style="cursor:hand">' : qq {<a id="$$data{a_id}" class=$$data{a_class} target="$$data{target}" href="$$data{href}" onFocus="blur()">};
		
		}


		$html .= $data -> {label};
		
		if ($data -> {href}) {

			$html .= $data -> {href} eq $options -> {href} ? '</span>' : '</a>';
		
		}

#		$html .= '</a>' if $data -> {href} && $data -> {href} ne $options -> {href};

#		$html .= '&nbsp;';		
		
		$html .= '</nobr>' unless $data -> {no_nobr};
		
		
	} else {
		$html .= '&nbsp;';
	}
	
	$html .= '</td>';
	
	if ($data -> {no_scroll} && $options -> {gantt}) {
			
		delete $data_original -> {no_scroll};
		
		my $pad = 11 + $data -> {level} * 15;
		
		$data_original -> {attributes} -> {style} .= <<EOH;
			;position:absolute;
			z-index:150;
			top:expression(this.previousSibling.offsetTop);
			left:expression(this.previousSibling.offsetLeft);
			width:expression(this.previousSibling.offsetWidth - $pad);
			height:expression(this.previousSibling.offsetHeight);
EOH

		$html .= draw_text_cell ($_SKIN, $data_original, $options);
	
	}

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
	my $html = qq {<td $attributes><select 
		name="$$data{name}" 
		onChange="is_dirty=true; $$options{onChange}" 
		onkeypress='typeAhead();' 
		$multiple
	};
	
	if (($options -> {__fixed_cols} > 0) && ($r -> headers_in -> {'User-Agent'} !~ /MSIE 7/)) {
		$html .= qq {style= "visibility:expression(cell_select_visibility(this, $options->{__fixed_cols}))"};
	}

	$html .= '>';

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

	if ($cell -> {href}) {
		$cell -> {label} = "<a class=row-cell-header-a href=\"$$cell{href}\"><b>" . $cell -> {label} . "</b></a>";
	}	

	my $attributes = dump_attributes ($cell -> {attributes});
	
	my $z_index = $cell -> {no_scroll} ? 'style="z-index:110"' : 'style="z-index:100"';

	return "<th $attributes $$cell{title} $z_index>\&nbsp;$$cell{label}\&nbsp;</th>";

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

	$html .= $options -> {no_scroll} ?
		qq {<td class=bgr8><div class="table-container-x">} :
		qq {<td class=bgr8><div class="table-container" style="height: expression(actual_table_height(this,$$options{min_height},$$options{height},'$__last_centered_toolbar_id'));">};

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
				$html  .= qq{ oncontextmenu="open_popup_menu('$i'); blockEvent ();"};
			}

			$html .= '>';
			$html .= qq {<a target="$$i{__target}" href="$$i{__href}">} if $i -> {__href};
			$html .= $tr;
			$html .= qq {</a>} if $i -> {__href};
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

	my $html = <<EOH . $html;
	
		$$options{title}
		$$options{path}
		$$options{top_toolbar}
		
		<table cellspacing=0 cellpadding=0 width="100%">		
			<tr>		
				<form name=$$options{name} action=$_REQUEST{__uri} method=post target=$$options{target} $enctype>
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
				wm.child.outerHTML = a [0];
				wm.window.menu_md5 = '$menu_md5';
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

		    if (window.event.button == 2 && window.event.ctrlKey) {
    			nope ('$url_dump', '_blank', 'toolbar=no,resizable=yes,scrollbars=yes');
		    }
		    
EODUMP
				
		$_REQUEST {__on_keydown} = <<EOJS;
					
			if (code_alt_ctrl (116, 0, 0)) {
			
				if (is_dirty) {
				
					if (!confirm ('Внимание! Вы изменили содержимое некоторых полей ввода. Перезагрузка страницы приведёт к утере этой информации. Продолжить?')) return blockEvent ();
				
				}
			
				window.location.href = '$href';
				
				return blockEvent ();
			
			}
			
			handle_basic_navigation_keys ();
			
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

		$_REQUEST {__on_keydown} .= "if (code_alt_ctrl (115, 0, 0)) return blockEvent ();";

		if ($_REQUEST {sid}) {
			my $timeout = 1000 * (60 * $conf -> {session_timeout} - 1);
			$_REQUEST {__on_load} .= "start_keepalive ($timeout);";
		}

		my $menu_md5 = Digest::MD5::md5_hex (freeze ($page -> {menu_data}));

		$_REQUEST {__on_load} .= "check_menu_md5 ('$menu_md5');";
		$_REQUEST {__on_load} .= "idx_tables ($_REQUEST{__scrollable_table_row});";
		$_REQUEST {__on_load} .= 'window.focus ();'                             if !$_REQUEST {__no_focus};
		$_REQUEST {__on_load} .= "focus_on_input ('$_REQUEST{__focused_input}');" if  $_REQUEST {__focused_input};
		$_REQUEST {__on_load} .= $_REQUEST {__edit} ? " parent.edit_mode = 1;" : " parent.edit_mode = 0;" if ($_REQUEST {__tree});
	
		$_REQUEST {__on_mouseover} .= <<EOS;
			window.parent.subsets_are_visible = 0;
EOS

	}
	else {
	
		my $href = create_url (__subset => $_SUBSET -> {name});
		$body_scroll = 'no';
				
		$_REQUEST {__on_load} = <<EOS;
			window.focus ();
			StartClock ();
			nope ('$href', '_body_iframe');
EOS
		
		$body = <<EOIFRAME;
			<iframe 
				name='_body_iframe' 
				id='_body_iframe' 
				src="$_REQUEST{__static_url}/0.html"
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
		var menu_md5 = '$menu_md5';
		var __read_only = $__read_only;
		var __last_last_query_string = '$_REQUEST{__last_query_string}';
EOH

	if ($$page{auth_toolbar}) {
		$$page{auth_toolbar} = "<tr height=48><td height=48>$$page{auth_toolbar}</td></tr><tr><td>$$page{menu}</td></tr>";
	}
		
	$_REQUEST {__head_links} .= <<EOH;
		<LINK href="$_REQUEST{__static_url}/eludia.css?$_REQUEST{__static_salt}" type=text/css rel=STYLESHEET>
		<style>
			.calendar .nav {  background: transparent url($_REQUEST{__static_url}/menuarrow.gif) no-repeat 100% 100%; }
			td.main-menu {padding-top:1px;padding-bottom:1px;background-image: url($_REQUEST{__static_url}/menu_bg.gif);cursor: pointer;}
			td.vert-menu {background-color: #454a7c;font-family: Tahoma, 'MS Sans Serif';font-weight: normal; font-size: 8pt; color: #ffffff; text-decoration: none;padding-top:4px;padding-bottom:4px;background-image: url($_REQUEST{__static_url}/menu_bg.gif);cursor: pointer;}
			#admin {width:205px;height:25px;padding:5px 5px 5px 9px;background:url('$_REQUEST{__static_url}/menu_button.gif') no-repeat 0 0;}
			td.login-head {background:url('$_REQUEST{__static_url}/login_title_pix.gif') repeat-x 1 1 #B9C5D7;font-size:10pt;font-weight:bold;padding:7px;}
			td.submit-area {text-align:center;height:36px;background:url('$_REQUEST{__static_url}/submit_area_bgr.gif') repeat-x 0 0;}
			div.green-title {color:#ffffff;font-weight:bold;background:url('$_REQUEST{__static_url}/green_ear_left.gif') no-repeat 0 0; width:300px;padding-left:10%;}
			div.grey-submit {background:url('$_REQUEST{__static_url}/grey_ear_left.gif') no-repeat 0 0; width:165;min-width:150px;padding-left:20px;}
		</style>
EOH

	foreach (@{$_REQUEST {__include_css}}) {
		$_REQUEST {__head_links} .= <<EOH;
			<LINK href="/i/$_.css" type=text/css rel=STYLESHEET>
EOH
	}

	$_REQUEST {__head_links} .= <<EOH;
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
		blockEvent ();
EOHELP

	foreach (keys %_REQUEST) {
	
		/^__on_(\w+)$/ or next;
		
		my $what = $1 eq 'load' ? 'window' : 'body';
	
		$_REQUEST {__head_links} .= <<EOH;
			<script for="$what" event="on$1">
				$_REQUEST{$&};
			</script>
EOH

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
		</html>
		
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
				var tr    = td.parentElement;
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
		if (code_alt_ctrl ($$r{code}, $r->{alt}, $r->{ctrl})) {
			document.form.$$r{data}.focus ();
			return blockEvent ();
		}
EOJS

}

################################################################################

sub handle_hotkey_focus_id {

	my ($r) = @_;

	$r -> {ctrl} += 0;
	$r -> {alt}  += 0;

	<<EOJS
		if (code_alt_ctrl ($$r{code}, $r->{alt}, $r->{ctrl})) {
			document.getElementById ('$r->{data}').focus ();
			return blockEvent ();
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
			
	my $code = !$r -> {href} ? "activate_link_by_id ('$$r{data}')" : "nope ('$$r{href}&__from_table=1&salt=' + Math.random () + '&' + scrollable_rows [scrollable_table_row].id, '_self');";

	$condition eq '1' or $code = "if ($condition) {$code}";
	

	return <<EOJS
		if (code_alt_ctrl ($$r{code}, $r->{alt}, $r->{ctrl})) $code;
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







	$_REQUEST {__on_load} .= 'document.forms[0].elements["login"].focus (); ';
	
	
	

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
					<td align="left" valign="middle" class='header_0' width=1><nobr>$$conf{page_title}</nobr></td>
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
				var w = window.parent;
				if (w.name != '_body_iframe') w = w.parent;				
				var f = w.document.getElementById ('__tree_iframe');
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
		win.document.body.innerHTML = "<table class=dtree width=100% height=100% celspacing=0 cellpadding=0 border=0><tr><td id='dtree_td' valign=top>" + win.d + "</td></tr></table><div id='dtree_menus'>$menus</div>";
@{[ $options->{selected_node} ? <<EOO : '' ]}		
		if (win.d.selectedNode == null || win.d.selectedFound) {
			win.d.openTo ($options->{selected_node}, true);
		}
EOO
EOH

	my $frameset = <<EOH;
		<frameset cols="$options->{width},*">
			<frame src="$ENV{SCRIPT_URI}/i/_skins/IsUp/0.html" name="_tree_iframe" id="__tree_iframe" application="yes">
			</frame>
			<frame src="${\($selected_node_url ? $selected_node_url : '$ENV{SCRIPT_URI}/i/_skins/IsUp/0.html')}" name="_content_iframe" id="__content_iframe" application="yes" scroll=no>
			</frame>
		</frameset>
EOH

	if ($options -> {top}) {
			
		$frameset = <<EOH;
			<frameset rows="$options->{top}->{height},*">
				<frame src="$options->{top}->{href}" name="_top_iframe" id="__top_iframe" application="yes" noresize scrolling=no>
				</frame>
				$frameset
			</frameset>
EOH
	
	}	

	return $frameset;

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
		target  => $options -> {target},
		icon    => $options -> {icon},
		iconOpen    => $options -> {iconOpen},
		is_checkbox => $options -> {is_checkbox},
	};
	
	foreach my $k (keys %$node) {
	
		delete $node -> {$k} if $node -> {$k} eq '';
	
	}
	
	if ($options -> {title} && $options -> {title} ne $options -> {label}) {
		$node -> {title} = $options -> {title};
	}

	if ($i -> {cnt_children} > 0) {
		$node -> {_hc}  = 1;	
		$node -> {_hac} = 0 + $i -> {cnt_actual_children};	
		$node -> {_io}  = $i -> {id} == $_REQUEST {__parent} ? 1 : 0;
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
	
	my $url = $_REQUEST {__static_url} . '/dialog.html?' . rand ();
	my $o = join ';', map {"$_:$options->{$_}"} keys %$options;
	
	return "javaScript:var result=window.showModalDialog('$url', dialog_open_$options->{id}, '$o');document.body.style.cursor='default';void(0);";

}

1;
