################################################################################

sub draw__benchmarks {
	
	my ($data) = @_;

	return

		draw_table (

			[
				{label => 'name',  href => {order => 'name'}},
				{label => 'count', href => {order => 'cnt'}},
				{label => 'time, ms',  href => {order => 'ms'}},
				{label => 'mean, ms',  href => {order => 'mean'}},
				{label => 'total selected',  href => {order => 'selected'}},
				{label => 'mean selected',  href => {order => 'mean_selected'}},
			],

			sub {

				draw_cells ({
				}, [
					$i -> {label},
					{
						label   => $i -> {cnt},
						picture => '### ### ### ###',
					},
					{
						label   => $i -> {ms},
						picture => '### ### ### ###',
					},
					{
						label   => $i -> {mean},
						picture => '### ### ### ###',
					},
					{
						label   => $i -> {selected},
						picture => '### ### ### ###',
					},
					{
						label   => $i -> {mean_selected},
						picture => '### ### ### ###',
					},
				])

			},

			$data -> {_benchmarks},

			{
				title => {label => 'Benchmarks'},

				top_toolbar => [{
							keep_params => ['type', 'select'],
						},
					{
						icon    => 'delete',
						label   => '&Flush',
						href    => '?type=_benchmarks&action=flush',
						target  => 'invisible',
						confirm => 'Are you sure?',
					},

					{
						type        => 'input_text',
						icon        => 'tv',
						name        => 'q',
						keep_params => [],
					},

					{
						type    => 'pager',
						cnt     => 0 + @{$data -> {_benchmarks}},
						total   => $data -> {cnt},
						portion => $data -> {portion},
					},

				],
				
			}
			
		);

}
