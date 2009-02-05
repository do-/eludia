################################################################################

sub draw__sync {

	my ($data) = @_;

	draw_form (
	
		{
#			no_edit => 1,

			target => '_self',
			
		},
		
		$data,
		
		[
				{
					label   => 'host',
					name    => 'host',
					size    => 20,
					max_len => 255,
					value   => $_REQUEST {last_host},
				},
				{
					label   => 'login',
					name    => 'login',
					size    => 20,
					max_len => 255,
					value   => $_REQUEST {last_login},
				},
				{
					label   => 'password',
					name    => 'password',
					type    => 'password',
					size    => 20,
					max_len => 255,
				},
#				{
#					label   => 'table',
#					name    => 'table',
#					size    => 20,
#					max_len => 255,
#				},

				{
					type   => 'checkboxes',
					values => $data -> {tables},
					name   => 'table',
					label  => 'tables',
					height => 200,
				},
			
		],
	
	)
		
}

1;