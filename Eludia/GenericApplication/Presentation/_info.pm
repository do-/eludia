################################################################################

sub draw__info {

	my ($data) = @_;
	
	push @$data, {			
		id    => 'JSON module',
		label => $ENV {PERL_JSON_BACKEND} . ' ' . ${"$ENV{PERL_JSON_BACKEND}::VERSION"},
	};
						
	push @$data, {			
		id    => 'Skin',
		label => $_SKIN,
	};
	
	draw_table (
		
		[
			'Component',
			'Product',
			'Version',
			'Location',
		],
	
		sub {
		
			unless ($i -> {path}) {
			
				my ($key) = split / /, $i -> {label};
				$key =~ s{\:\:}{\/}g;
				$i -> {path} = $INC {$key . '.pm'};
			
			}
			
			if ($i -> {version}) {
			
				$i -> {product} = $i -> {label};
			
			}
			else {

				($i -> {product}, $i -> {version}) = split m{[ /]}, $i -> {label};

			}
			
			my ($product, $version) = split m{[ /]}, $i -> {label};
		
			draw_cells ({}, [			
				$i -> {id},
				{label => $i -> {product}, max_len => 10000000},
				{label => $i -> {version}, max_len => 10000000},
				{label => $i -> {path}, max_len => 10000000},
			])
			
		},
		
		$data,
		
		{		
			
			title => {label => 'Version info'},
			
			lpt => 1,
			
		},
	
	);
	
}

1;
