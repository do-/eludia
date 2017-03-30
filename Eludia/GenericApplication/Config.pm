################################################################################

sub get_page {}

#############################################################################

sub fake_select {

	my ($options) = @_;

	return {
		type    => 'input_select',
		name    => $options -> {name} || 'fake',
		values  => [
			{id => '0,-1', label => 'Все'},
			{id => '-1', label => 'Удалённые'},
		],
		empty   => 'Активные',
	}
	
}

################################################################################

sub del {
	
	return () if $_REQUEST {__no_navigation};
	
	my ($data) = @_;

	return () if $data -> {no_del};

	return (
		{
			preset  => 'delete',
			href    => {action => 'delete'},
			target  => 'invisible',
			off     => $data -> {fake} != 0 || !$_REQUEST {__read_only} || $_REQUEST {__popup},
		},		
		{
			preset  => 'undelete',
			href    => {action => 'undelete'},
			target  => 'invisible',
			off     => $data -> {fake} >= 0 || !$_REQUEST {__read_only} || $_REQUEST {__popup} || $conf -> {core_undelete_to_edit},
		},
		{
			preset  => 'undelete',
			href    => create_url() . "&__edit=1",
			off     => $data -> {fake} >= 0 || !$_REQUEST {__read_only} || $_REQUEST {__popup} || !$conf -> {core_undelete_to_edit},
		},
	);

}

################################################################################

sub fill_in {

	return if $conf -> {__filled_in};
	
	check_systables ();

	our $number_format ||= Number::Format -> new (%{$conf -> {number_format}});

   	$conf -> {lang} ||= 'RUS';   	

   	fill_in_things (core_modules =>
   		
		auth                 => 1,
		checksums            => 1,
		json                 => 1,
		log                  => 1,
		mail                 => 1,
		math_fixed_precision => 1,
		memory               => 1,
		presentation_tools   => 1,
		queries              => 1,
		schedule             => 1,
		uri_escape           => 1,
		want                 => 1,
		zlib                 => 1,
   	
	);

   	fill_in_things (sql_types =>
   	
		int      => {TYPE_NAME => 'int', FIELD_OPTIONS => {type => 'string'}},

		money    => {TYPE_NAME => 'decimal', COLUMN_SIZE => 10, DECIMAL_DIGITS => 2, FIELD_OPTIONS => {type => 'string', picture => '### ### ### ###,##'}},

		string   => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
   		
		checkbox => {TYPE_NAME => 'tinyint', NULLABLE => 0, COLUMN_DEF  =>  0 },
   		
		radio    => {TYPE_NAME => 'tinyint', NULLABLE => 0, COLUMN_DEF  => -1 },

		select   => {TYPE_NAME => 'int'},

		suggest  => {TYPE_NAME => 'int'},
   		
		text     => {TYPE_NAME => 'text'},

		ref      => {TYPE_NAME => 'int'},

   	);

   	fill_in_things (button_presets =>

   		ok => {
   			icon    => 'ok',
   			label   => 'ok',
   			hotkey  => {code => ENTER, ctrl => 1},
   			confirm => $conf -> {core_no_confirm_submit} ? undef : 'confirm_ok',
   		},
   		
   		cancel => {
   			icon   => 'cancel',
   			label  => 'cancel',
   			hotkey => {code => ESC},
   			confirm => confirm_esc,
   			preconfirm => 'is_dirty',
   		},

   		edit => {
   			icon   => 'edit',
   			label  => 'edit',
   			hotkey => {code => F4},
   		},

   		choose => {
   			icon   => 'choose',
   			label  => 'choose',
   			hotkey => {code => ENTER, ctrl => 1},
   		},

   		'close' => {
   			icon   => 'ok',
   			label  => 'close',
   			hotkey => {code => ESC},
   		},
   		
   		back => {
			icon => 'back', 
			label => 'back', 
			hotkey => {code => F11 },
		},

   		next => {
			icon => 'next',
			label => 'next',
   			hotkey => {code => F12},
		},

   		delete => {
   			icon    => 'delete',
   			label   => 'delete',
   			hotkey  => {code => DEL, ctrl => 1},
   			confirm => 'confirm_delete',
   		},

   		undelete => {
   			icon    => 'create',
   			label   => 'undelete',
   			confirm => 'confirm_undelete',
   		},

   	);

   	$conf -> {__filled_in} = 1;

}

################################################################################

sub fill_in_things {

	my ($name, %entries) = @_;
	
   	my $h = ($conf -> {$name} ||= {});
   	
	return if $h -> {_is_filled};
	
	while (my ($key, $value) = each %entries) {
	
		$h -> {$key} ||= $value;
		
	}
	
	$h -> {_is_filled} = 1;

};

1;