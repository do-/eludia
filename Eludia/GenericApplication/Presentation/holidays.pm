################################################################################

sub draw_holidays {

	my ($data) = @_;
		
	my @color = ('#FFFFFF', '#FFa0a0');
		
	js qq {
		
		var color = ['$color[0]', '$color[1]'];
		
		function sw (dt) {
				
			nope ('/?type=holidays&action=switch&sid=$_REQUEST{sid}&dt=' + dt + '&_salt=' + Math.random (), 'invisible');
			
			setCursor ();
		
		}

	};

	my $holidays = $data -> {holidays};	

	return

		draw_calendar_year (

			sub {
			
				my ($cell, $day) = @_;
									
				my $dt = $day -> {iso};
					
				$cell -> {href}                    = "javascript:sw('$dt')";
				$cell -> {attributes} -> {bgcolor} = $color [$holidays -> {$dt}];
									
			},

			{
			
				title => {label => " алендарь праздников и выходных на $_REQUEST{year} год"},

				top_toolbar => [
					{
						keep_params => ['type'],
					},
					{
						name	=> 'year',
						type	=> 'input_select',
						values	=> $data -> {years},
					},
					{
						icon    => 'print',
						label   => 'MS Excel',
						href    => {xls => 1},
						target  => 'invisible',
					},
				],
				
			}
			
		);
}


1;
