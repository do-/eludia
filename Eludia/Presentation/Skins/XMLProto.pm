package Eludia::Presentation::Skins::XMLProto;

BEGIN {
	require Eludia::Presentation::Skins::Generic;
	delete $INC {"Eludia/Presentation/Skins/Generic.pm"};
}

################################################################################

sub options {
	return {
		no_static    => 1,
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
	return $options -> {label};	

}

################################################################################
# FORMS & INPUTS
################################################################################

sub draw_form {

	my ($_SKIN, $options) = @_;
			
	my $html = qq {\t<form path="$$options{path}">\n};
	
	foreach my $row (@{$options -> {rows}}) {
		$html .= "\t\t<row>\n" if @$row > 1;
		foreach (@$row) { $html .= $_ -> {html} };
		$html .= "\t\t</row>\n" if @$row > 1;
	}

	$html .=  "\t</form>\n";
	
	$html .= $options -> {bottom_toolbar};
	
	return $html;	

}


################################################################################

sub draw_path {

	my ($_SKIN, $options, $list) = @_;
	
	return join ' / ', map {$_ -> {label}} @$list;
		
}

################################################################################

sub draw_form_field {
	my ($_SKIN, $field, $data) = @_;	
	return $field -> {html};								
}

################################################################################

sub draw_form_field_banner {
	my ($_SKIN, $options, $data) = @_;
	return qq {\t\t\t<banner label="$$options{label}" />\n};
}

################################################################################

sub draw_form_field_button {
	my ($_SKIN, $options, $data) = @_;
 	return qq{\t\t\t<input label="$$options{label}" type="button" />\n};
}

################################################################################

sub draw_form_field_string {
	my ($_SKIN, $options, $data) = @_;	
 	return qq{\t\t\t<input label="$$options{label}" type="text" size="$$options{size}" value="$$options{value}" />\n};
}

################################################################################

sub draw_form_field_datetime {
	my ($_SKIN, $options, $data) = @_;
 	return qq{\t\t\t<input label="$$options{label}" type="datetime" value="$$options{value}" />\n};	
}

################################################################################

sub draw_form_field_file {
	my ($_SKIN, $options, $data) = @_;	
 	return qq{\t\t\t<input label="$$options{label}"  size="$$options{size}" type="file" />\n};	
}

################################################################################

sub draw_form_field_hidden {
	my ($_SKIN, $options, $data) = @_;
	return '';
}

################################################################################

sub draw_form_field_hgroup {

	my ($_SKIN, $options, $data) = @_;

	my $html = qq{\t\t\t<hgroup label="$$options{label}">\n};

	foreach my $item (@{$options -> {items}}) {
		next if $item -> {off};
		$html .= $item -> {html};
	}

	$html .= qq{\t\t\t</hgroup>\n};

	return $html;
	
}

################################################################################

sub draw_form_field_text {
	my ($_SKIN, $options, $data) = @_;
 	return qq{\t\t\t<input label="$$options{label}" type="textarea" cols="$$options{cols}" rows="$$options{rows}" />\n};
}

################################################################################

sub draw_form_field_password {
	my ($_SKIN, $options, $data) = @_;
 	return qq{\t\t\t<input label="$$options{label}" type="password" size="$$options{size}" value="$$options{value}" />\n};
}

################################################################################

sub draw_form_field_static {
	my ($_SKIN, $options, $data) = @_;
 	return qq{\t\t\t<input label="$$options{label}" type="static" value="$$options{value}" />\n};
}

################################################################################

sub draw_form_field_checkbox {
	my ($_SKIN, $options, $data) = @_;
 	return qq{\t\t\t<input label="$$options{label}" type="checkbox" />\n};	
}

################################################################################

sub draw_form_field_radio {

	my ($_SKIN, $options, $data) = @_;
				
	my $html = qq{\t\t\t<input label="$$options{label}" type="radio">\n};

	foreach my $value (@{$options -> {values}}) {
	
		if ($value -> {html}) {
			$html .= qq{\t\t\t\t<option label="$$value{label}">\n};
			$html .= $value -> {html};
			$html .= qq{\t\t\t\t</option>\n};
		}
		else {
			$html .= qq{\t\t\t\t<option label="$$value{label}" />\n};
		}
					
	}
	
	$html .= "\t\t\t</input>\n";
		
	return $html;
	
}

################################################################################

sub draw_form_field_select {

	my ($_SKIN, $options, $data) = @_;
	
	my $html = qq{\t\t\t<input label="$$options{label}" type="select">\n};

	foreach my $value (@{$options -> {values}}) {
		$html .= qq{\t\t\t\t<option label="$$value{label}" />\n};					
	}
	
	$html .= "\t\t\t</input>\n";
		
	return $html;
	
}

################################################################################

sub draw_form_field_checkboxes {

	my ($_SKIN, $options, $data) = @_;
	
	my $html = qq{\t\t\t<input label="$$options{label}" type="checkboxes" height="$$options{height}">\n};

	foreach my $value (@{$options -> {values}}) {
		$html .= qq{\t\t\t\t<option label="$$value{label}" />\n};					
	}
	
	$html .= "\t\t\t</input>\n";
		
	return $html;
	
}

################################################################################

sub draw_form_field_image {

	my ($_SKIN, $options, $data) = @_;	
 	return qq{\t\t\t<input label="$$options{label}" type="image" />\n};	

}

################################################################################

sub draw_form_field_iframe {
	
	my ($_SKIN, $options, $data) = @_;
 	return qq{\t\t\t<input label="$$options{label}" type="iframe" />\n};	

}

################################################################################

sub draw_form_field_color {
	
	my ($_SKIN, $options, $data) = @_;	
 	return qq{\t\t\t<input label="$$options{label}" type="color" />\n};	

}

################################################################################

sub draw_form_field_htmleditor {
	
	my ($_SKIN, $options, $data) = @_;
 	return qq{\t\t\t<input label="$$options{label}" type="htmleditor" />\n};	

}

################################################################################
# TOOLBARS
################################################################################

################################################################################

sub draw_toolbar {

	my ($_SKIN, $options) = @_;
	my $html = qq{\t\t<toolbar>\n};
	foreach (@{$options -> {buttons}}) { $html .= $_ -> {html}; }
	$html .= qq{\t\t</toolbar>\n};
	return $html;

}

################################################################################

sub draw_toolbar_break {

	my ($_SKIN, $options) = @_;
	return '';

}

################################################################################

sub draw_toolbar_button {

	my ($_SKIN, $options) = @_;
	return qq {\t\t\t<button label="$$options{label}" icon="$$options{icon}" />\n};
	
}

################################################################################

sub draw_toolbar_input_select {

	my ($_SKIN, $options) = @_;	
	return qq {\t\t\t<input type="select" />\n};
	
}

################################################################################

sub draw_toolbar_input_checkbox {

	my ($_SKIN, $options) = @_;	
	return qq {\t\t\t<input type="checkbox" label="$$options{label}" />\n};

}

################################################################################

sub draw_toolbar_input_submit {

	my ($_SKIN, $options) = @_;
	return qq {\t\t\t<input type="submit" label="$$options{label}" />\n};

}

################################################################################

sub draw_toolbar_input_text {

	my ($_SKIN, $options) = @_;
	return qq {\t\t\t<input type="text" label="$$options{label}" size="$$options{size}" />\n};

}

################################################################################

sub draw_toolbar_input_datetime {

	my ($_SKIN, $options) = @_;
	return qq {\t\t\t<input type="datetime" label="$$options{label}" />\n};

}

################################################################################

sub draw_toolbar_pager {
	return qq {\t\t\t<pager />\n};
}

################################################################################

sub draw_centered_toolbar_button {

	my ($_SKIN, $options) = @_;
	return qq {\t\t\t<button label="$$options{label}" icon="$$options{icon}" />\n};

}

################################################################################

sub draw_centered_toolbar {

	my ($_SKIN, $options, $list) = @_;
	
	my $html = qq{\t\t<panel>\n};
	foreach (@$list) { $html .= $_ -> {html}; }
	$html .= qq{\t\t</panel>\n};

	return $html;

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

sub draw_text_cell {
	my ($_SKIN, $data, $options) = @_;
	my $label = shift @__HEADS;
	return qq {\t\t\t<column label="$label" text="$$data{label}" />\n};
}

################################################################################

sub draw_radio_cell {
	my ($_SKIN, $data, $options) = @_;
	return qq {\t\t\t<input type="radio" />\n};
}

################################################################################

sub draw_checkbox_cell {
	my ($_SKIN, $data, $options) = @_;
	return qq {\t\t\t<input type="checkbox" />\n};
}

################################################################################

sub draw_select_cell {
	my ($_SKIN, $data, $options) = @_;
	return qq {\t\t\t<input type="select" />\n};
}

################################################################################

sub draw_input_cell {
	my ($_SKIN, $data, $options) = @_;
	return qq {\t\t\t<input />};
}

################################################################################

sub draw_row_button {

	my ($_SKIN, $options) = @_;
	return qq {\t\t\t<button label="$$options{label}" icon="$$options{icon}" />\n};

}

####################################################################

sub draw_table_header {
	
	my ($_SKIN, $data_rows, $html_rows) = @_;
	return '';
	
}

####################################################################

sub draw_table_header_row {
	
	my ($_SKIN, $data_cells, $html_cells) = @_;
	return '';
	
}

####################################################################

sub draw_table_header_cell {
	
	my ($_SKIN, $cell) = @_;	
	return '' if $cell -> {hidden} || $cell -> {off} || (!$cell -> {label} && $conf -> {core_hide_row_buttons} == 2) || $cell -> {colspan} > 1;
	push @__HEADS, $cell -> {label};	
	return '';

}

####################################################################

sub draw_table {

	my ($_SKIN, $tr_callback, $list, $options) = @_;
	
	my $html = qq{\t\t<table};	
	
	$html .= qq{ title="$options->{title}"} if $options -> {title};			
	$html .= qq{ path="$options->{path}"}   if $options -> {path};			
	$html .= qq{>\n};			

	$html .= $options -> {top_toolbar};
	$html .= qq{\t\t\t<body>\n};			
	$html .= $list -> [0] -> {__trs} -> [0] if (@$list > 0);	
	$html .= qq{\t\t\t</body>\n};			
	$html .= $options -> {toolbar};		
	$html .= qq{\t\t</table>\n};
	
	undef @__HEADS;
	
	return $html;

}

################################################################################

sub draw_one_cell_table {

	my ($_SKIN, $options, $body) = @_;	
	return '';			

}

################################################################################

sub draw_error_page {

	my ($_SKIN, $page) = @_;
	return '';			

}

################################################################################

sub start_page {
}

################################################################################

sub draw_page {

	my ($_SKIN, $page) = @_;
						
	$_REQUEST {__content_type} ||= 'text/xml; charset=' . $i18n -> {_charset};

	return <<EOH;
<?xml version="1.0" encoding="windows-1251"?>
<!-- ?xml-stylesheet type="text/xsl" href="i/eludia-html.xsl"? -->
<xml>
	<page>
$$page{body}
	</page>
</xml>
EOH

}

1;