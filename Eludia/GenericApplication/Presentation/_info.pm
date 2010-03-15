################################################################################

sub draw__info {

	my ($data) = @_;
	
	draw_table (
		
		[
			'Component',
			'Product',
			'Version',
			'Location',
		],
	
		sub {
							
			draw_cells ({}, [			
				$i -> {id},
				{label => $i -> {product}, max_len => 10000000},
				{label => $i -> {version}, max_len => 10000000},
				{label => $i -> {path}, max_len => 10000000},
			])
			
		},
		
		$data -> {rows},
		
		{		
			
			title => {label => 'Version info'},
			
		},
	
	);
	
}

1;
