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

	return 'auth_toolbar000';

}

################################################################################

sub draw_page {

	my ($_SKIN, $page) = @_;
	
	return "$_REQUEST{__script};$page->{body};_body_iframe.doLayout();";

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

sub draw_toolbar_button {

	my ($_SKIN, $_options) = @_;

	return 'draw_toolbar_button';

}

################################################################################

sub draw_hr {};

################################################################################

sub draw_window_title {

	my ($_SKIN, $options) = @_;

	return $options -> {label};

}

################################################################################

sub draw_table {

	my ($_SKIN, $tr_callback, $list, $options) = @_;

	$options -> {id}     ||= 0 + $options;
		
	my $data     = '';
	
	my $n = 0 + @{$options -> {header}};
	
	my @rows = ();
	
	foreach my $i (@$list) {

		my $field_values = $i -> {__field_values};
		
		$n ||= 0 + @$field_values;
		
		my %field_values = (id => $i -> {id});
		
		foreach my $j (0 .. @$field_values - 1) {
		
			$field_values {"f$j"} = $field_values -> [$j]
		
		}

		push @rows, \%field_values;

	}
		
	$data = $_JSON -> encode (\@rows);
	
	my $columns  = $_JSON -> encode ($options -> {header} ||= [
	
		map {{
		
			header    => '',
		
			dataIndex => 'f' . $_,
	
		}} (1 .. $n)
	
	]);
	
	my $fields   = $_JSON -> encode (['id', map {{name => $_ -> {dataIndex}}} @{$options -> {header}}]);

	my $storeOptions = $_JSON -> encode ({
		storeId     => "store_$options->{name}",
	});

	my $panelOptions = $_JSON -> encode ({
		anchor     => '100 100%',
		title      => $options -> {title},
		border     => \0,
		viewConfig => {autoFill => \1},
	});

	return "_body_iframe.add (createGridPanel ($data, $columns, $storeOptions, $fields, $panelOptions));"
	
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

	push @{${$_PACKAGE . 'i'} -> {__field_values}}, $data -> {label};
		
	return undef;
	
}

####################################################################

sub draw_table_header_cell {
	
	my ($_SKIN, $cell) = @_;

	return $cell;

}

####################################################################

sub draw_table_header_row {
	
	my ($_SKIN, $data_cells, $html_cells) = @_;

	return $html_cells;

}

####################################################################

sub draw_table_header {
	
	my ($_SKIN, $raw_rows, $rows) = @_;

	@$rows > 0 or return '[]';

	my @cols = ();
	
	my $n    = 0;
	
	foreach my $i (@{$rows -> [0]}) {
	
		my $col = {
		
			header    => $i -> {label},
			
			dataIndex => 'f' . $n ++,
		
		};
		
		$col -> {width} = $i -> {width} if $i -> {width};
		
		push @cols, $col;
	
	}

	return \@cols;

}

################################################################################

sub draw_error_page {

	my ($_SKIN, $page) = @_;

	$_REQUEST {__content_type} ||= 'text/html; charset=' . $i18n -> {_charset};

	my $data = $_JSON -> encode (['<pre>' . $_REQUEST {error} . '</pre>']);

	return qq {

		var data = $data;
		Ext.MessageBox.alert ('ќшибка', data [0]);

	};

}

################################################################################

sub draw_logon_form {

	return qq {
	
		var dialog = Ext.Msg.show ({
			title    : '¬ход в систему',
			closable : false,
			msg      : 'You are closing a tab that has unsaved changes. Would you like to save your changes?',
			buttons  : Ext.Msg.YESNO,
		//	fn: processResult,
		//	icon: Ext.MessageBox.QUESTION
		});

	};

}

1;