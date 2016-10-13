package Eludia::Presentation::Skins::XL;

use Data::Dumper;

BEGIN {
	require Eludia::Presentation::Skins::Generic;
	delete $INC {"Eludia/Presentation/Skins/Generic.pm"};
}

################################################################################

sub options {

	return {
		no_buffering    => 1,
		no_static       => 1,
		no_trunc_string => 1,
	};

}

################################################################################

sub register_hotkey {

	my ($_SKIN, $hashref) = @_;
	$hashref -> {label} =~ s{\&}{}gsm;
	return undef;

}

################################################################################

sub draw_hr {
	my ($_SKIN, $options) = @_;

	return '' if ($_REQUEST {__no_draw_hr});

	$r -> print ('<p>&nbsp;</p>');
	return '';
}

################################################################################

sub draw_auth_toolbar {
	my ($_SKIN, $options) = @_;
	return '';
}

################################################################################

sub draw_window_title {

	my ($_SKIN, $options) = @_;

	return '' if ($_REQUEST {__no_draw_window_title});

	$r -> print (<<EOH);
		<p style="font-family:Arial;font-size:12pt"><b><i>$$options{label}</i></b></p>
EOH

	return '';

}

################################################################################
# FORMS & INPUTS
################################################################################

sub start_form {

	my ($_SKIN, $options) = @_;
	$r -> print ($options -> {hr});
	$r -> print ($options -> {path});
	$r -> print (qq{<table border=1>});

}

################################################################################

sub start_form_row {
	$r -> print (qq{<tr>});
}

################################################################################

sub draw_form_row {
	my ($_SKIN, $row) = @_;
	foreach (@$row) {$r -> print ($_ -> {html})}
	$r -> print (qq{</tr>});
}

################################################################################

sub draw_form {

	my ($_SKIN, $options) = @_;
	$r -> print ('</table>');
	$r -> print ($options -> {bottom_toolbar});

	return '';

}

################################################################################

sub draw_path {

	my ($_SKIN, $options, $list) = @_;
	return '';

}

################################################################################

sub draw_form_field {

	my ($_SKIN, $field, $data) = @_;

	if ($field -> {type} eq 'banner') {
		my $colspan     = 'colspan=' . ($field -> {colspan} + 1);
		return qq{<td $colspan nowrap align=center>$$field{html}</td>};
	}
	elsif ($field -> {type} eq 'hidden') {
		return '';
	}

	my $colspan     = $field -> {colspan}     ? 'colspan=' . $field -> {colspan}     : '';

	my $style = $field -> {picture} ? 'style="mso-number-format:' . $_SKIN -> _picture ($field -> {picture}) . '"' : '';

	my $colspan_label = $field -> {colspan_label} ? 'colspan=' . $field -> {colspan_label} : '';

	return (<<EOH);
		<td nowrap align=right $colspan_label><b>$$field{label}</b></td>
		<td $colspan $style>\n$$field{html}</td>
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
	return '';
}

################################################################################

sub draw_form_field_string {
	my ($_SKIN, $options, $data) = @_;
	return '';
}

################################################################################

sub draw_form_field_datetime {
	my ($_SKIN, $options, $data) = @_;
	return '';
}

################################################################################

sub draw_form_field_file {
	my ($_SKIN, $options, $data) = @_;
	return '';
}

################################################################################

sub draw_form_field_hidden {
	my ($_SKIN, $options, $data) = @_;
	return '';
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
	return $options -> {value};

}

################################################################################

sub draw_form_field_password {
	my ($_SKIN, $options, $data) = @_;
	return '';
}

################################################################################

sub draw_form_field_static {

	my ($_SKIN, $options, $data) = @_;

	my $html = '';

	if (ref $options -> {value} eq ARRAY) {

		for (my $i = 0; $i < @{$options -> {value}}; $i++) {
			$html .= ('<br>') if $i;
			$html .= ($options -> {value} -> [$i] -> {label});
		}

	}
	else {
		$html .= ($options -> {value});
	}

	return $html;

}

################################################################################

sub draw_form_field_checkbox {
	my ($_SKIN, $options, $data) = @_;
	return '';
}

################################################################################

sub draw_form_field_radio {
	my ($_SKIN, $options, $data) = @_;
	return '';
}

################################################################################

sub draw_form_field_select {
	my ($_SKIN, $options, $data) = @_;
	return '';
}

################################################################################

sub draw_form_field_checkboxes {
	my ($_SKIN, $options, $data) = @_;
	return '';
}

################################################################################

sub draw_form_field_image {
	my ($_SKIN, $options, $data) = @_;
	return '';
}

################################################################################

sub draw_form_field_iframe {
	my ($_SKIN, $options, $data) = @_;
	return '';
}

################################################################################

sub draw_form_field_color {
	my ($_SKIN, $options, $data) = @_;
	return '';
}

################################################################################

sub draw_form_field_htmleditor {
	my ($_SKIN, $options, $data) = @_;
	return '';
}

################################################################################
# TOOLBARS
################################################################################

################################################################################

sub draw_toolbar {
	my ($_SKIN, $options) = @_;
	return '';
}

################################################################################

sub draw_toolbar_break {
	my ($_SKIN, $options) = @_;
	return '';
}

################################################################################

sub draw_toolbar_button {
	my ($_SKIN, $options) = @_;
	return '';
}

################################################################################

sub draw_toolbar_button_vert_menu {
	my ($_SKIN, $options) = @_;
	return '';
}
################################################################################

sub draw_toolbar_input_select {
	my ($_SKIN, $options) = @_;
	return '';
}

################################################################################

sub draw_toolbar_input_checkbox {
	my ($_SKIN, $options) = @_;
	return '';
}

################################################################################

sub draw_toolbar_input_submit {
	my ($_SKIN, $options) = @_;
	return '';
}

################################################################################

sub draw_toolbar_input_text {
	my ($_SKIN, $options) = @_;
	return '';
}

################################################################################

sub draw_toolbar_input_datetime {
	my ($_SKIN, $options) = @_;
	return '';
}

################################################################################

sub draw_toolbar_pager {
	my ($_SKIN, $options) = @_;
	return '';
}

################################################################################

sub draw_centered_toolbar_button {
	my ($_SKIN, $options) = @_;
	return '';
}

################################################################################

sub draw_centered_toolbar {
	my ($_SKIN, $options, $list) = @_;
	return '';
}

################################################################################
# MENUS
################################################################################

################################################################################

sub draw_menu {
	my ($_SKIN, $_options) = @_;
	return '';
}

################################################################################

sub draw_vert_menu {
	my ($_SKIN, $name, $types) = @_;
	return '';
}


################################################################################
# TABLES
################################################################################

################################################################################

sub js_set_select_option {
	my ($_SKIN, $name, $item, $fallback_href) = @_;
	return '';
}

################################################################################

sub _picture {

	my ($_SKIN, $picture) = @_;

	unless ($_SKIN -> {pictures} -> {$picture}) {

		my $point = $conf -> {number_format} -> {-decimal_point};
		my $sep   = $conf -> {number_format} -> {-thousands_sep};

		my ($integer, $fraction) = split /$point/, $picture;

		$integer =~ s{(.*)\#}{${1}0}; #
		$integer =~ s{\#}{\\\#}g;
		$integer =~ s{$sep}{\\\,}g;

		$fraction =~ y{#}{0}; #

		$_SKIN -> {pictures} -> {$picture} = join '\.', grep {/0/} ($integer, $fraction);

	}

	return $_SKIN -> {pictures} -> {$picture};

}

################################################################################

sub draw_text_cell {

	my ($_SKIN, $data, $options) = @_;

	delete $data -> {attributes} -> {class};

	$data -> {attributes} -> {style} = 'padding:5px;';

	if ($data -> {picture}) {
		my $picture = $_SKIN -> _picture ($data -> {picture});
		$data -> {attributes} -> {style} .= "mso-number-format:$picture;";
		$data -> {attributes} -> {'x:num'} = $data -> {attributes} -> {title} if ($data -> {attributes} -> {title} =~ /^-?\d+.?\d*$/);
	}
	elsif ($data -> {label} =~ /^\d\d\.\d\d\.\d\d(\d\d)?$/) {
		$data -> {attributes} -> {style} .= "mso-number-format:'Short date';";
	}
	elsif ($data -> {label} =~ /^\d\d\.\d\d\.\d\d\d\d \d\d:\d\d:\d\d$/) {
		$data -> {attributes} -> {style} .= "mso-number-format:'dd\\/mm\\/yyyy h\\:mm';";
	}
	elsif (!$data -> {no_nobr}) {
		$data -> {attributes} -> {style} .= "mso-number-format:\\\@;";
	}
	delete $data -> {attributes} -> {title};

	if ($data -> {bgcolor} ||= $data -> {attributes} -> {bgcolor}) {
		$data -> {attributes} -> {style} .= "background:$data->{bgcolor};";
	}

	if ($data -> {fgcolor} ||= $data -> {attributes} -> {fgcolor}) {
		$data -> {attributes} -> {style} .= "color:$data->{fgcolor};";
	}

	delete $data -> {attributes} -> {bgcolor} if $data -> {picture} || !$data -> {attributes} -> {bgcolor};

	if ($data -> {level}) {
		$data -> {attributes} -> {style} .= "padding-left:" . ($data -> {level} * 12) . "px;";
	}

	my $attributes = dump_attributes ($data -> {attributes});

	my $txt = '';

	unless ($data -> {off}) {

		$txt = $data -> {label};

		$txt =~ s{^\s+}{};
		$txt =~ s{\s+$}{};

		if ($data -> {no_nobr}) {
			$txt =~ s{\n}{<br/>}gsm;
		} else {
			$txt = '<nobr>' . $txt . '</nobr>';
		}

		if ($data -> {bold} || $options -> {bold} || $options -> {is_total}) {
			$txt = '<b>' . $txt . '</b>';
		}

		if ($data -> {italic} || $options -> {italic}) {
			$txt = '<i>' . $txt . '</i>';
		}

		if ($data -> {strike} || $options -> {strike}) {
			$txt = '<strike>' . $txt . '</strike>';
		}

	}

	$r -> print (qq {\n\t<td $attributes>$txt</td>});
	return '';

}

################################################################################

sub draw_radio_cell {
	my ($_SKIN, $data, $options) = @_;
	$r -> print ('<td>&nbsp;</td>');
	return '';
}

################################################################################

sub draw_checkbox_cell {
	my ($_SKIN, $data, $options) = @_;
	$r -> print ('<td>&nbsp;</td>');
	return '';
}

################################################################################

sub draw_select_cell {
	my ($_SKIN, $data, $options) = @_;
	$r -> print ('<td>&nbsp;</td>');
	return '';
}

################################################################################

sub draw_input_cell {
	my ($_SKIN, $data, $options) = @_;
	return draw_text_cell (@_);
}

################################################################################

sub draw_dump_button {
	my ($_SKIN, $data, $options) = @_;
	return '';
}

################################################################################

sub draw_row_button {
	my ($_SKIN, $options) = @_;
	return '' if $conf -> {core_hide_row_buttons} == 2;
	$r -> print ('<td nowrap width="1%">&nbsp;</td>');
	return '';
}

####################################################################

sub draw_table_header {

	my ($_SKIN, $data_rows, $html_rows) = @_;

	my $html = '<thead>';
	foreach (@$html_rows) {$html .= $_};
	$html .= '</thead>';

	return $html;

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

	$cell -> {no_nbsp} or $cell -> {label} = "&nbsp;$cell->{label}&nbsp;";

	dump_tag (th => $cell -> {attributes}, $cell -> {label});

}

####################################################################

sub start_table {

	my ($_SKIN, $options) = @_;

	$r -> print ($options -> {title});
	$r -> print (qq {<table border=1>\n});
	$r -> print ($options -> {header}) if $options -> {header};
	$r -> print (qq {<tbody>\n});

	return '';

}

####################################################################

sub start_table_row {
	my ($_SKIN) = @_;
	$r -> print ('<tr>');
	return '';
}

####################################################################

sub draw_table_row {
	my ($_SKIN, $row) = @_;
	$r -> print ('</tr>');
	return '';
}

####################################################################

sub draw_table {

	my ($_SKIN, $tr_callback, $list, $options) = @_;

	$r -> print ('</tbody></table>');

	return '';

}

################################################################################

sub draw_one_cell_table {

	my ($_SKIN, $options, $body) = @_;
	return '';

}

################################################################################

sub draw_error_page {
	my ($_SKIN, $page) = @_;
	return $message;
}

################################################################################

sub dialog_close {

	my ($_SKIN, $options, $body) = @_;
	return '';

}

################################################################################

sub dialog_open {

	my ($_SKIN, $options, $body) = @_;
	return '';

}

################################################################################

sub xls_filename {

	my $filename = 'eludia_' . $_REQUEST {type};

	if ($conf -> {report_date_in_filename}) {
		my $generation_date = sprintf ("%04d-%02d-%02d_%02d-%02d", Date::Calc::Today_and_Now);
		$filename .= "_($generation_date)";
	}

	return "$filename.xls";
}

################################################################################

sub start_page {

	$_REQUEST {__no_default_after_xls} or $_REQUEST {__after_xls} .= qq {
		<p>$_USER->{label}</p>
		<p>@{[ sprintf ('%02d.%02d.%04d %02d:%02d:%02d', (Date::Calc::Today_and_Now) [2,1,0,3,4,5]) ]}</p>
	};

	$r -> content_type ('application/octet-stream');
	$r -> header_out ('P3P' => 'CP="IDC DSP COR ADM DEVi TAIi PSA PSD IVAi IVDi CONi HIS OUR IND CNT"');
	$r -> header_out ('Content-Disposition' => "attachment;filename=@{[xls_filename ()]}");
	$r -> send_http_header ();

	$_REQUEST {__response_sent} = 1;

	$_REQUEST {_xml}   = "<xml>$_REQUEST{_xml}</xml>" if $_REQUEST {_xml};
	$_REQUEST {_style} = "<style><!--$_REQUEST{_style}</style>" if $_REQUEST {_style};

	$r -> print (<<EOH);
		<html xmlns:x="urn:schemas-microsoft-com:office/excel" xmlns:o="urn:schemas-microsoft-com:office:office">
			<head>
				<title>$$i18n{_page_title}</title>
				<meta http-equiv=Content-Type content="text/html; charset=$$i18n{_charset}">
				$_REQUEST{_style}
				$_REQUEST{_xml}
			</head>
			<body bgcolor=white leftMargin=0 topMargin=0 marginwidth="0" marginheight="0">
				$_REQUEST{__before_xls}
EOH

}

################################################################################

sub draw_page {

	my ($_SKIN, $page) = @_;
	$r -> print (<<EOH);
$_REQUEST{__after_xls}
</body></html>
EOH

}

1;
