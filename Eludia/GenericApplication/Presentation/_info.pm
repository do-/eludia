################################################################################

sub draw__info {

	my ($data) = @_;
	
	my $skin = $_SKIN;
	$skin =~ s{\:\:}{\/}g;

	push @$data, {			
		id    => 'JSON module',
		label => 
			ref ($_JSON) eq 'JSON'     ? ('JSON' . ' ' . $JSON::VERSION . ' (backend: ' . JSON->backend . ')', path => $INC {'JSON.pm'}) :
			ref ($_JSON) eq 'JSON::XS' ? ('JSON::XS' . ' ' . $JSON::XS::VERSION, path => $INC {'JSON/XS.pm'}) : 
			'none',
	};

	push @$data, {			
		id    => 'Skin',
		label => $_SKIN,
		path  => $INC {$skin . '.pm'},
	};
	
	draw_table (
	
		sub {
			draw_cells ({}, [
				$i -> {id},
				{label => $i -> {label}, max_len => 10000000},
				{label => $i -> {path}, max_len => 10000000},
			])
		},
		
		$data,
		
		{		
			
			title => {label => 'Информация о версиях'},
			
			lpt => 1,
			
		},
	
	);
	
}

1;