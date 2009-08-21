################################################################################

sub dump_hiddens {

	join '', 
	
		map {
		
			dump_tag (
			
				input => {
				
					type  => 'hidden', 
					name  => $_ -> [0], 
					value => $_ -> [1],
					
				}
				
			)
			
		} 
		
	@_;

}

################################################################################

BEGIN {

	foreach (
		'XS', 
		'PP'
	) {
	
		eval "require Eludia::Presentation::Tools::$_";
		
		last if $preconf -> {_} -> {presentation_tools};
	
	}

}

1;