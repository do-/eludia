package Eludia::Presentation::Skins::ExtJs;

no warnings;

BEGIN {

	require Eludia::Presentation::Skins::Generic;
	delete $INC {"Eludia/Presentation/Skins/Generic.pm"};

	our $replacement = {};

}

################################################################################

sub options {

	return {
		core_unblock_navigation => $preconf -> {core_unblock_navigation},
	};
	
}

################################################################################

sub draw_dump_button { () }

################################################################################

sub register_hotkey {

	my ($_SKIN, $hashref) = @_;

}

################################################################################

sub static_path {

	my ($package, $file) = @_;
	my $path = __FILE__;

	$path    =~ s{\.pm}{/$file};

	return $path;

};

################################################################################

sub draw_auth_toolbar {

	my ($_SKIN, $options) = @_;

	return 'auth_toolbar';

}

################################################################################

sub draw_page {

	my ($_SKIN, $page) = @_;
	
	return '<pre>' . Data::Dumper::Dumper (\%_REQUEST_VERBATIM) . Data::Dumper::Dumper ($page) . '</pre>';

}

################################################################################

sub draw_vert_menu {

	my ($_SKIN, $name, $types, $level, $is_main) = @_;
	
	return 'draw_vert_menu';
	
}

################################################################################

sub draw_menu {

	my ($_SKIN, $_options) = @_;

	return 'draw_menu';

}

################################################################################

sub draw_hr {};

################################################################################

sub draw_window_title {

	my ($_SKIN, $options) = @_;

	return 'auth_toolbar';

}

################################################################################

sub draw_table {

	my ($_SKIN, $tr_callback, $list, $options) = @_;
	
	return 'draw_table';

}

################################################################################

sub draw_toolbar_input_text {

	my ($_SKIN, $options) = @_;

	return 'draw_toolbar_input_text';
	
}

################################################################################

sub draw_toolbar_input_select {

	my ($_SKIN, $options) = @_;

	return 'draw_toolbar_input_select';
	
}

################################################################################

sub draw_toolbar_pager {

	my ($_SKIN, $options) = @_;

	return 'draw_toolbar_input_select';
	
}

################################################################################

sub draw_toolbar {

	my ($_SKIN, $options) = @_;

	return 'draw_toolbar';

}

################################################################################

sub draw_text_cell {

	my ($_SKIN, $data, $options) = @_;

	return 'draw_text_cell';

}

####################################################################

sub draw_table_header_cell {
	
	my ($_SKIN, $cell) = @_;

	return 'draw_table_header_cell';

}

####################################################################

sub draw_table_header_row {
	
	my ($_SKIN, $data_cells, $html_cells) = @_;

	return 'draw_table_header_row';

}

####################################################################

sub draw_table_header {
	
	my ($_SKIN, $data_rows, $html_rows) = @_;

	return 'draw_table_header';

}

1;