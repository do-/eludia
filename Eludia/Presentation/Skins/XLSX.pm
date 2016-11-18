package Eludia::Presentation::Skins::XLSX;

use Data::Dumper;
use Excel::Writer::XLSX;
use Encode;
use File::Spec qw(tmpdir);

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

	$_REQUEST {__xl_row} += 2;

	my $worksheet = $_REQUEST {__xl_workbook} -> get_worksheet_by_name ($_REQUEST {__xl_sheet_name});

	my $window_title_format = $_REQUEST {__xl_workbook} -> add_format (
	    bold   => 1,
	    italic => 1,
	    size   => 12,
	    font   => 'Arial',
	);

	my $right_width = $worksheet -> {__col_widths} -> [0];

	$worksheet -> write ($_REQUEST {__xl_row}, 0, $$options{label}, $window_title_format);

	$worksheet -> {__col_widths} -> [0] = $right_width;

	$_REQUEST {__xl_row} += 1;

	return '';
}

################################################################################
# FORMS & INPUTS
################################################################################

sub start_form {
	my ($_SKIN, $options) = @_;
	$_REQUEST {__xl_row} += 1;
}

################################################################################

sub start_form_row {
	$_REQUEST {__xl_row} += 1;
	$_REQUEST {__xl_col} = 0;
}

################################################################################

sub draw_form_row {
	my ($_SKIN, $row) = @_;
}

################################################################################

sub draw_form {
	my ($_SKIN, $options) = @_;
	$_REQUEST {__xl_row} += 2;
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

	my $worksheet = $_REQUEST {__xl_workbook} -> get_worksheet_by_name ($_REQUEST {__xl_sheet_name});

	my $format_record = $_REQUEST {__xl_workbook} -> add_format (
		text_wrap => 1,
     	border    => 1,
     	valign    => 'bottom',
    	align     => 'left',
	);

	if ($field -> {type} eq 'banner') {
		$format_record -> set_align ('center');

		$field -> {html} = processing_string ($field -> {html});

		my $right_width = $worksheet -> {__col_widths} -> [$_REQUEST {__xl_col}];
		$worksheet -> merge_range ($_REQUEST {__xl_row}, $_REQUEST {__xl_col}, $_REQUEST {__xl_row}, $_REQUEST {__xl_col} + $field -> {colspan},  $field -> {html}, $format_record);
		$worksheet -> {__col_widths} -> [$_REQUEST {__xl_col}] = $right_width;

		if ($field -> {html} =~ /\n/) {
			push_info_row ($field -> {html}, $field -> {colspan});
		}

		$_REQUEST {__xl_col} = $_REQUEST {__xl_col} + $field -> {colspan};

		return '';
	}
	elsif ($field -> {type} eq 'hidden') {
		return '';
	}


	if ($field -> {picture}) {
		my $picture = $_SKIN -> _picture ($field -> {picture});
		$format_record -> set_num_format ($picture);
	}
	elsif ($field -> {html} =~ /^\d\d\.\d\d\.\d\d(\d\d)?$/) {
		$format_record -> set_num_format ('m/d/yy');
		$format_record -> set_align ('right');
	}
	elsif ($field -> {html} =~ /^\d\d\.\d\d\.\d\d\d\d \d\d:\d\d:?\d?\d?$/) {
		$format_record -> set_num_format ('m/d/yy h:mm');
		$format_record -> set_align ('right');
	}
	elsif (!$field -> {no_nobr}) {
		$format_record -> set_num_format ('@');
	}

	if ($field -> {html} =~ /^\-?\d+(\,|\.)\d+$/) {
		$format_record -> set_align ('right');
	}

	$field -> {label} = processing_string ($field -> {label});

	$worksheet -> write ($_REQUEST {__xl_row}, $_REQUEST {__xl_col}, $field -> {label}, $header_form_format);

	if ($field -> {label} =~ /\n/) {
		my $new_length = width_string_with_linebreak ($field -> {label});
		if ($new_length > $right_width) {
			$worksheet -> {__col_widths} -> [$_REQUEST {__xl_col}] = $new_length * $_REQUEST {__xl_width_ratio};
		}
	}

	$_REQUEST {__xl_col}++;

	if ($field -> {bold} || $field -> {html} =~ /bold/ || $field -> {html} =~ /<b>/) {
		$format_record -> set_bold ();
	}
	if ($field -> {italic} || $field -> {html} =~ /<i>/) {
		$format_record -> set_italic ();
	}

	# if ($field -> {font_size}) {
	# 	$format_record -> set_size($field -> {font_size});
	# }

	$field -> {html} = processing_string ($field -> {html});

	if (($field -> {colspan}) > 1){
		push_info_row ($field -> {html}, $field -> {colspan});

		my $right_width = $worksheet -> {__col_widths} -> [$_REQUEST {__xl_col}];
		$worksheet -> merge_range ($_REQUEST {__xl_row}, $_REQUEST {__xl_col}, $_REQUEST {__xl_row}, $_REQUEST {__xl_col} + $field -> {colspan} -1,  $field -> {html}, $format_record);
		$worksheet -> {__col_widths} -> [$_REQUEST {__xl_col}] = $right_width;

		$_REQUEST {__xl_col} = $_REQUEST {__xl_col} + $field -> {colspan};
	}
	else{
		$worksheet -> write ($_REQUEST {__xl_row}, $_REQUEST {__xl_col}, $field -> {html}, $format_record);
		$_REQUEST {__xl_col}++;
	}

	return '';
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
		$html .= ' ';
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
	my $worksheet = $_REQUEST {__xl_workbook} -> get_worksheet_by_name ($_REQUEST {__xl_sheet_name});

	unless ($_SKIN -> {pictures} -> {$picture}) {

		my $point = $conf -> {number_format} -> {-decimal_point};
		my $sep   = $conf -> {number_format} -> {-thousands_sep};

		my ($integer, $fraction) = split /$point/, $picture;
		$integer =~ s{$sep}{\,}g;

		if ($fraction){
			$integer =~ s{(.*)\#}{${1}0}; #

			$fraction =~ y{#}{0}; #

			$_SKIN -> {pictures} -> {$picture} = join ('.', $integer, $fraction);
		}
		else{
			$_SKIN -> {pictures} -> {$picture} = $integer;
		}
	}

	my $ind = index $_SKIN -> {pictures} -> {$picture}, ("." || ",");
	if ($ind != -1) {
		my $str = $_SKIN -> {pictures} -> {$picture};
		$worksheet -> {__fraction} -> {flag} = 1;
		$worksheet -> {__fraction} -> {length} = (length $str) - $ind;
	}

	return $_SKIN -> {pictures} -> {$picture};
}

################################################################################

sub draw_text_cell {
	my ($_SKIN, $data, $options) = @_;
	my $worksheet = $_REQUEST {__xl_workbook} -> get_worksheet_by_name ($_REQUEST {__xl_sheet_name});
	my $txt = '';

	my $format = $_REQUEST {__xl_workbook} -> add_format (
		text_wrap => 1,
     	border    => 1,
	);

	foreach (@{$worksheet -> {__united_cells} -> {$_REQUEST {__xl_row}}}) {
		if ($_ == $_REQUEST {__xl_col}){
			$_REQUEST {__xl_col} ++;
		}
	}

	if (defined ($data -> {label}) && !($data -> {off})) {
		if ($data -> {attributes} -> {align}) {
			$format -> set_align ($data -> {attributes} -> {align});
		}

		if ($data -> {attributes} -> {title}) {
			$txt = $data -> {attributes} -> {title};
		}
		else {
			$txt = $data -> {label};
		}

		if (length $txt > 0) {
			if ($data -> {picture}) {
				my $picture = $_SKIN -> _picture ($data -> {picture});
				$format -> set_num_format ($picture);

				if (!($picture =~ /\./)) {
					$txt =~ s/\..*//gi;
				}
			}
			elsif ($data -> {label} =~ /^\d\d\.\d\d\.\d\d(\d\d)?$/) {
				$format -> set_num_format ('m/d/yy');
				$format -> set_align ('right');
			}
			elsif ($data -> {label} =~ /^\d\d\.\d\d\.\d\d\d\d \d\d:\d\d:?\d?\d?$/) {
				$format -> set_num_format ('m/d/yy h:mm');
				$format -> set_align ('right');
			}
			elsif (!$data -> {no_nobr}) {
				$format -> set_num_format ('@');
			}

			if ($data -> {bold} || $options -> {bold} || $options -> {is_total} || $txt =~ /<b>/) {
				$format -> set_bold ();
			}
			if ($data -> {italic} || $options -> {italic}) {
				$format -> set_italic ();
			}
			if ($data -> {strike} || $options -> {strike}) {
				$format -> set_font_strikeout ();
			}
		}
	}

	if ($data -> {bgcolor} ||= $data -> {attributes} -> {bgcolor}) {
		$format -> set_bg_color ($data -> {bgcolor});
	}
	if ($data -> {fgcolor} ||= $data -> {attributes} -> {fgcolor}) {
		$format -> set_color ($data -> {fgcolor});
	}
	if ($data -> {level}) {
		$format -> set_indent ($data -> {level});
	}

	$txt = processing_string ($txt);

	my $rowspan = $data -> {rowspan} ? $data -> {rowspan} : 1;
	my $colspan = $data -> {colspan} ? $data -> {colspan} : 1;

	if ($rowspan != 1 || $colspan != 1){

		if ($rowspan != 1) {
			for (my $i = 0; $i < $rowspan; $i++) {
				my $key = $_REQUEST {__xl_row} + $i;
				unless ($worksheet -> {__united_cells} -> {$key}) {
					$worksheet -> {__united_cells} -> {$key} = [];
				}
				push ($worksheet -> {__united_cells} -> {$key}, $_REQUEST {__xl_col});
			}
		}
		else {
			push_info_row ($txt, $colspan, $data -> {level});
		}

		if (length $txt > $_REQUEST {__xl_max_width_col} / $_REQUEST {__xl_width_ratio} || $colspan != 1) {
			my $right_width = $worksheet -> {__col_widths} -> [$_REQUEST {__xl_col}];
			$worksheet -> merge_range ($_REQUEST {__xl_row}, $_REQUEST {__xl_col}, $_REQUEST {__xl_row} + $rowspan -1, $_REQUEST {__xl_col} + $colspan - 1,  $txt, $format);
			$worksheet -> {__col_widths} -> [$_REQUEST {__xl_col}] = $right_width;
		}
		else {
			$worksheet -> merge_range ($_REQUEST {__xl_row}, $_REQUEST {__xl_col}, $_REQUEST {__xl_row} + $rowspan -1, $_REQUEST {__xl_col} + $colspan - 1,  $txt, $format);
		}
	}
	else{
		$worksheet -> write ($_REQUEST {__xl_row}, $_REQUEST {__xl_col}, $txt, $format);
	}

	$_REQUEST {__xl_col} = $_REQUEST {__xl_col} + $colspan;

	return '';
}

################################################################################

sub draw_radio_cell {
	my ($_SKIN, $data, $options) = @_;
	return '';
}

################################################################################

sub draw_checkbox_cell {
	my ($_SKIN, $data, $options) = @_;
	my $worksheet = $_REQUEST {__xl_workbook} -> get_worksheet_by_name ($_REQUEST {__xl_sheet_name});
	$worksheet -> write ($_REQUEST {__xl_row}, $_REQUEST {__xl_col}, " ", $simple_cell_format);
	$_REQUEST {__xl_col} += 1;
	return '';
}

################################################################################

sub draw_select_cell {
	my ($_SKIN, $data, $options) = @_;
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
	return '';
}

####################################################################

sub draw_table_header {
	my ($_SKIN, $data_rows, $html_rows) = @_;
	return $html;
}

####################################################################

sub draw_table_header_row {
	my ($_SKIN, $data_cells, $html_cells) = @_;
	return $html;
}
################################################################################

sub draw_table_header_cell {
	my ($_SKIN, $cell) = @_;

	my $worksheet = $_REQUEST {__xl_workbook} -> get_worksheet_by_name ($_REQUEST {__xl_sheet_name});

	my $right_width = $worksheet -> {__col_widths} -> [$_REQUEST {__xl_col}];

	$cell -> {label} = processing_string($cell -> {label});

	return '' if $cell -> {hidden} || $cell -> {off} || (!$cell -> {label} && $conf -> {core_hide_row_buttons} == 2);

	my $rowspan = $cell -> {attributes} -> {rowspan};
	my $colspan = $cell -> {attributes} -> {colspan};

	my $col = $_REQUEST {__xl_col};
	my $row = $_REQUEST {__xl_row};

	if (!$worksheet -> {__map_str} -> {$row}) {
		$worksheet -> {__map_str} -> {$row} = [];
	}

	if (!$cell -> {parent_header}) {
		for (my $i = 0; $i < $colspan; $i++) {
			push $worksheet -> {__map_str} -> {$row}, 1;
		}
	}
	else {
		my $i = $col;
		while ($worksheet -> {__map_str} -> {$row} [$i] != 0) {

			$i++;
		}
		$col = $i;
		for (my $j = 0; $j < $colspan; $j++) {
			$worksheet -> {__map_str} -> {$row} [$col + $j] = 1;
		}
	}

	if ($rowspan != 1 || $colspan != 1){
		$worksheet -> merge_range ($row, $col, $row + $rowspan - 1, $col + $colspan - 1, $cell -> {label}, $header_table_format);
		if ($colspan > 1)  {
			$worksheet -> {__col_widths} -> [$_REQUEST {__xl_col}] = $right_width;
		}
	}
	else {
		$worksheet -> write ($row, $col, $cell -> {label}, $header_table_format);
	}

	if ($cell -> {label} =~ /\n/) {
		my $new_length = width_string_with_linebreak ($cell -> {label});
		if ($new_length > $right_width) {
			$worksheet -> {__col_widths} -> [$_REQUEST {__xl_col}] = $new_length * $_REQUEST {__xl_width_ratio};
		}
	}

	my $i = 1;
	while ($i <= $rowspan) {
		if (!$worksheet -> {__map_str} -> {$row + $i}) {
			$worksheet -> {__map_str} -> {$row + $i} = [];
		}
		for (my $j = 0; $j < $colspan; $j++) {
			my $k = $i == $rowspan ? 0 : 1;
			push $worksheet -> {__map_str} -> {$row + $i}, $k;
		}
		$i++;
	}

	$_REQUEST {__xl_col} = $_REQUEST {__xl_col} + $colspan;

	return '';
}

####################################################################

sub start_table {
	my ($_SKIN, $options) = @_;
	my $worksheet = $_REQUEST {__xl_workbook} -> get_worksheet_by_name ($_REQUEST {__xl_sheet_name});
	return '';
}

####################################################################

sub start_table_row {
	my ($_SKIN) = @_;
	$_REQUEST {__xl_row} += 1;
	$_REQUEST {__xl_col} = 0;
	return '';
}

####################################################################

sub draw_table_row {
	my ($_SKIN, $row) = @_;
	return '';
}

####################################################################

sub draw_table {
	my ($_SKIN, $tr_callback, $list, $options) = @_;
	$_REQUEST {__xl_row} += 2;
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

sub xlsx_filename {
	my $filename = 'eludia_' . $_REQUEST {type};

	if ($conf -> {report_date_in_filename}) {
		my $generation_date = sprintf ("%04d-%02d-%02d_%02d-%02d", Date::Calc::Today_and_Now);
		$filename .= "_($generation_date)";
	}

	return "$filename.xlsx";
}

####################################################################

sub start_page {
	$_REQUEST {__xl_file_name} = File::Spec -> tmpdir() . "/eludia_$_REQUEST{type}_$_REQUEST{sid}_$_REQUEST{__salt}.xlsx";

	open (OUT, '>' . $_REQUEST {__xl_file_name}) or die "Can't open $_REQUEST{__file_name}: $!\n";
	binmode OUT;
	flock (OUT, LOCK_EX);

	my $workbook = Excel::Writer::XLSX -> new (\*OUT);

	$_REQUEST {__xl_sheet_name} = substr ('eludia_' . $_REQUEST {type}, 0, 31);
	my $worksheet = $workbook -> add_worksheet ($_REQUEST {__xl_sheet_name});

	$_REQUEST {__xl_workbook}  = $workbook;
	$_REQUEST {__xl_row} = 0;
	$_REQUEST {__xl_col} = 0;

	$_REQUEST {__xl_max_width_col} = 36; # максимально допустимая ширина столбца в символах
	$_REQUEST {__xl_width_ratio} = 1.2; # коэффициент для определения ширины столбца

	%{$worksheet -> {__fraction}} =(
		flag   => 0,
		length => 0,
	);

	$worksheet -> add_write_handler (qr[[А-Яа-я№]], \&decode_rus);
	$worksheet -> add_write_handler (qr[\w], \&store_string_widths);
	$worksheet -> add_write_handler (qr[^0[^.,]], \&write_as_string);

	$header_table_format = $workbook -> add_format (
		text_wrap => 1,
     	border    => 1,
     	bold      => 1,
     	valign    => 'vcenter',
    	align     => 'center',
	);

	$header_form_format = $workbook -> add_format (
		text_wrap => 1,
     	border    => 1,
     	bold      => 1,
     	valign    => 'bottom',
    	align     => 'right',
	);

	$simple_cell_format = $workbook -> add_format (
		border    => 1,
	);
}

################################################################################

sub draw_page {
	my $worksheet = $_REQUEST {__xl_workbook} -> get_worksheet_by_name ($_REQUEST {__xl_sheet_name});

	my $right_width = $worksheet -> {__col_widths} -> [0];

	$worksheet -> write ($_REQUEST {__xl_row}, 0, $_USER -> {label});

	$_REQUEST {__xl_row} += 2;
	$worksheet -> write ($_REQUEST {__xl_row}, 0, @{[ sprintf ('%02d.%02d.%04d %02d:%02d', (Date::Calc::Today_and_Now) [2,1,0,3,4]) ]});
	$worksheet -> {__col_widths} -> [0] = $right_width;

	$_REQUEST {__response_sent} = 1;

	autofit_columns ($_REQUEST {__xl_max_width_col});

	if ($worksheet -> {__row_height}) {
		autoheight_rows ();
	}

	$_REQUEST {__xl_workbook} -> close ();

	flock (OUT, LOCK_UN);
	close OUT;

	&{"${_PACKAGE}download_file"} ({
		path      => $_REQUEST {__xl_file_name},
		file_name => @{[xlsx_filename ()]},
		delete    => 1,
	});
}

################################################################################
# FOR AUTOFIT
################################################################################

sub push_info_row {
	my $worksheet = $_REQUEST {__xl_workbook} -> get_worksheet_by_name ($_REQUEST {__xl_sheet_name});

	my %info_row = (
		"text"	    => $_[0],
		"col"       => $_REQUEST {__xl_col},
		"row"       => $_REQUEST {__xl_row},
		"colspan"   => $_[1] || 1,
		"indent"    => $_[2],
	);

	push (@{$worksheet -> {__row_height}}, \%info_row);
}

################################################################################

sub autoheight_rows{
	my $worksheet = $_REQUEST {__xl_workbook} -> get_worksheet_by_name ($_REQUEST {__xl_sheet_name});

	foreach my $row (@{$worksheet -> {__row_height}}) {
		my $text = $row -> {text};
		my $height_row = 0;

		my $sum_width = 0;
		for (my $i = 0; $i <$row -> {colspan}; $i++){
			$sum_width += $worksheet -> {__col_widths} -> [$row -> {col} + $i];
		}

		if ($row -> {indent}) {
			$sum_width = $sum_width - $row -> {indent};
		}

		my $end_substring = index $text, "\n";
		while ($end_substring != -1) {
			my $substring = substr $text, 0, $end_substring + 1, '';
			$height_row	+= int ($end_substring / $sum_width + 1);
			$end_substring = index $text, "\n";
		}

		$height_row	+= int ((length $text) / $sum_width + 1.07);

		$worksheet -> set_row ($row -> {row}, 15 * $height_row);
	}
	return '';
}

################################################################################

sub autofit_columns {
    my $worksheet = $_REQUEST {__xl_workbook} -> get_worksheet_by_name ($_REQUEST {__xl_sheet_name});
    my $max_width = shift;
    my $col = 0;

    my $format = $_REQUEST {__xl_workbook} -> add_format (
    	text_wrap => 1,
    	align     => 'vjustify',
    );

    for my $width (@{$worksheet -> {__col_widths}}) {
        if ($width > $max_width) {
          	$worksheet -> set_column ($col, $col, $max_width, $format);
			$worksheet -> {__col_widths} -> [$col] = $max_width;
        }
        else {
            $worksheet -> set_column ($col, $col, $width);
        }
        $col++;
    }
}

################################################################################

sub store_string_widths {
    my $worksheet = shift;
    my $col       = $_[1];
    my $token     = $_[2];

    # Ignore some tokens that we aren't interested in.
    return if not defined $token;       # Ignore undefs.
    return if $token eq '';             # Ignore blank cells.
    return if ref $token eq 'ARRAY';    # Ignore array refs.
    return if $token =~ /^=/;           # Ignore formula

	# NOT(!) Ignore numbers
#    return if $token =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/;

    # Ignore various internal and external hyperlinks. In a real scenario
    # you may wish to track the length of the optional strings used with
    # urls.
    return if $token =~ m{^[fh]tt?ps?://};
    return if $token =~ m{^mailto:};
    return if $token =~ m{^(?:in|ex)ternal:};

    # We store the string width as data in the Worksheet object. We use
    # a double underscore key name to avoid conflicts with future names.
    #
    my $old_width    = $worksheet -> {__col_widths} -> [$col];
    my $string_width = string_width ($token);

    if (not defined $old_width or $string_width > $old_width) {
        # You may wish to set a minimum column width as follows.
        #return undef if $string_width < 10;
        $worksheet -> {__col_widths} -> [$col] = $string_width;
    }

    # Return control to write();
    return undef;
}

################################################################################

sub string_width {
	my $worksheet = $_REQUEST {__xl_workbook} -> get_worksheet_by_name ($_REQUEST {__xl_sheet_name});
	my $length_string;

	if ($worksheet -> {__fraction} -> {flag} == 1) {
		if ((index $_[0], "." ) != -1) {
			$length_string = index $_[0], "." ;
		}
		else {
			$length_string = length $_[0];
		}

		$length_string = $length_string + $worksheet -> {__fraction} -> {length};

		$worksheet -> {__fraction} -> {flag} = 0;
	}
	else {
		$length_string = length $_[0];
	}

	if ($length_string < $_REQUEST {__xl_max_width_col} / 4) {
		return  $length_string + 2;
	}
	if ($_[0] =~ /^\-?\d+(\,|\.)\d+$/) {
		return  ($_REQUEST {__xl_width_ratio} + 0.1) * $length_string;
	}

	return  $_REQUEST {__xl_width_ratio} * $length_string;
}

################################################################################

sub width_string_with_linebreak {
	my $text = $_[0];

	my $end_substring = index $text, "\n";
	my $max_len = 0;
	my $substring;

	while (length $text != 0) {
		if ($end_substring == -1) {
			$end_substring = length $text;
		}

		$substring = substr $text, 0, $end_substring, '';

		my $len = length $substring;
		$text =~ s/\n//;
		$end_substring = index $text, "\n";
		if ($len > $max_len) {
			$max_len = $len;
		}
	}

	return $max_len;
}

################################################################################

sub write_as_string {
	my $worksheet = shift;
    return $worksheet -> write_string (@_);
}

################################################################################

sub decode_rus{
	my $worksheet = shift;
    return $worksheet -> write ($_[0], $_[1], decode ("cp-1251", $_[2]), $_[3]);
}

################################################################################

sub processing_string{
	my $string = @_[0];

	$string =~ s/&nbsp;/ /ig;
	$string =~ s/\<br\/?\>$//ig;
	$string =~ s/\<br\/?\>/\n/ig;
	$string =~ s/&rArr;/ \=\> /ig;

	$string =~ s/&#x([a-fA-F0-9]+);/"&#". hex($1) .";"/ge;
	$string =~ s/&#([0-9]+);/chr($1)." "/ge;

	$string =~ s/<[^>]*>//ig;

	return $string;
}
1;