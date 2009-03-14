################################################################################

sub select_subset { return {} }

################################################################################

sub get_page {}

#############################################################################

sub fake_select {
	
	return {
		type    => 'input_select',
		name    => 'fake',
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

   	fill_in_button_presets (

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

sub fill_in_button_presets {

	my %entries = @_;
   	$conf -> {button_presets} ||= {};
	return if $conf -> {button_presets} -> {_is_filled};
	
	while (my ($key, $value) = each %entries) {
		$conf -> {button_presets} -> {$key} ||= $value;
	}
	
	$conf -> {button_presets} -> {_is_filled} = 1;

};

1;