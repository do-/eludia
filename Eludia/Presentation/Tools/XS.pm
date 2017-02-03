################################################################################

sub dump_attributes {

	return HTML::GenerateUtil::generate_attributes (@_);

}

################################################################################

sub dump_tag {

	return HTML::GenerateUtil::generate_tag ($_[0], $_[1], $_[2] || undef, 0);

}

################################################################################

BEGIN {

	eval 'require HTML::GenerateUtil';
	
	return if $@;
	
	$preconf -> {_} -> {presentation_tools} = 'XS';
		
	loading_log "HTML::GenerateUtil, ok.\n";
	
}

1;