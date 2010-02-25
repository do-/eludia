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
		no_trunc_string => 1,
		
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

	$_REQUEST_VERBATIM {type} or return &{$_PACKAGE . 'draw_logon'} ();

	my ($_SKIN, $page) = @_;
	
	my $user_subset_menu = Data::Dumper::Dumper (
		
		&{$_PACKAGE . 'get_user_subset_menu'} ()
			
	);

	my $md5 = Digest::MD5::md5_hex ($user_subset_menu);
	
	return "$_REQUEST{__script};checkMenu('$md5');$page->{body};target.doLayout();";

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
	
	!exists $_REQUEST {__only_table} or $_REQUEST {__only_table} eq $options -> {name} or return '';

	$options -> {id}     ||= 0 + $options;
	
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
	
	my $content = {
		
		success => \1,
	
		root    => \@rows,
		
	};
	
	foreach my $button (@{$options -> {top_toolbar} -> {buttons}}) {
	
		if ($button -> {type} eq 'pager') {
		
			$content -> {$_} = $button -> {$_} foreach qw (total cnt);
		
		}
	
	}
		
	my $data = $_JSON -> encode ($content);
	
	!exists $_REQUEST {__only_table} or return out_html ({}, $data);
	
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
	
	my %base_params = %_REQUEST_VERBATIM;
	
	$base_params {__only_table} = $options -> {name};
	
	my $base_params = $_JSON -> encode (\%base_params);

	return "target.add (createGridPanel ($data, $columns, $storeOptions, $fields, $panelOptions, $base_params));"
	
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

	return 'draw_toolbar_pager';
	
}

################################################################################

sub draw_toolbar {

	my ($_SKIN, $options) = @_;

	return $options;

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
		Ext.MessageBox.alert ('Ошибка', data [0]);

	};

}

################################################################################

sub draw_logon_form {

	return <<EOS;
<html>
	<head>
		<link rel="stylesheet" type="text/css" href="/i/ext/resources/css/ext-all.css" />
		<script type="text/javascript" src="/i/ext/adapter/ext/ext-base.js"></script>
		<script type="text/javascript" src="/i/ext/ext-all.js"></script>
		<script type="text/javascript" src="/i/ext/src/locale/ext-lang-ru.js"></script>
		<script type="text/javascript" src="/i/_skins/ExtJs/navigation.js"></script>

		<style>
			.ext-ie .x-form-text {
			    margin: 0px;
			    height: 22px;
			    font-size: 12px;
			}
		</style>

		<script type="text/javascript">

			var oldSubset = '';

			function checkMenu (md5) {

				if (menu_md5 != md5) refreshSubset (subsetCombo, null, 0);

			}

			var refreshSubset = function (combo, record, index) {

				subsetStore.proxy.setUrl ("/content/?type=menu&action=serialize&sid=" + sid + "&__subset=" + (

					record ? record.data.name : combo.getValue ()

				));

				subsetStore.load ({

					params   : {},
					scope    : subsetStore,
					callback : function () {

						var data = subsetStore.reader.jsonData;

						subsetCombo.setValue (data.user.subset);
												
						createMenu (center.getTopToolbar (), data.__menu, oldSubset != data.user.subset);

						oldSubset = data.user.subset;

						menu_md5 = data.md5;

						combo.collapse ();

						center.focus ();

					}

				});

			}

			var	subsetStore = new Ext.data.JsonStore ({

				url        : "/",
				root       : "__subsets",
				fields     : ['name', 'label'],
				idProperty : 'name'

			});


			var	subsetCombo = new Ext.form.ComboBox ({

				editable         : false,
				forceSelection   : true,

				displayField     : 'label',
				valueField       : 'name',
				mode			 : 'local',

				fieldLabel       : 'Бизнес-процесс',

				disableKeyFilter : false,
				triggerAction    : 'all',

				listeners        : {

					select : refreshSubset

				},

				store: subsetStore

			});

			var	north = new Ext.form.FormPanel ({

				frame:true,
				bodyStyle:'padding:1px 1px 0',
				layout: 'hbox',
				layoutConfig  : {
					align: 'middle',
					defaultMargins  : {top:0, right:20, bottom:0, left:0}
				},
				region: 'north',
				split: true,
				header: false,
				height: 80,
				collapsible: true,
				margins: '0 0 0 0'

			});

			var exitButton = new Ext.Button ({

				text       : 'Выход',
				icon       : '/i/ext/examples/shared/icons/fam/user_delete.png',
				iconAlign  : 'right',
				scale      : 'medium',
				listeners  : {click : applicationExit}

			});

			north.add ([

				new Ext.form.Label ({html : '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src="/i/logo_in.gif"></img>'}),
				new Ext.form.Label ({text : 'Бизнес-процесс: '}),

				subsetCombo,

				new Ext.form.Label ({text : fio}),
				new Ext.form.Label ({text : ' ', flex : 1}),

				exitButton

			]);

			var	center = new Ext.form.FormPanel ({
				tbar   : {},
				region : 'center',
				layout : 'anchor'
			});

			Ext.onReady (function () {

				var viewport = new Ext.Viewport ({

					layout: 'border',

					items: [north, center]

				});

				nope ("/content/?type=logon&action=check");

			});

		</script>

	</head>

	<body></body>

</html>
EOS

}

1;