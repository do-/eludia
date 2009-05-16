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