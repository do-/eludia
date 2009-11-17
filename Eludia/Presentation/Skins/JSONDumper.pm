package Eludia::Presentation::Skins::JSONDumper;

################################################################################

sub options { return {no_presentation => 1}}

################################################################################

sub no_presentation { 1 }

################################################################################

sub draw_hash {

	my ($_SKIN, $h) = @_;

	$_REQUEST {__content_type} ||= 'text/plain; charset=' . $i18n -> {_charset};

	$_JSON -> encode ($h);

}

################################################################################

sub draw_page {

	my ($_SKIN, $page) = @_;
	
	$page -> {content} -> {__this_content_is_ok_to_be_shown_completely} or $page -> {content} = 'Sorry?..';
	
	return $_SKIN -> draw_hash ({ 
	
		content => $page -> {content},

	});

}

################################################################################

sub draw_error_page {

	my ($_SKIN, $page) = @_;

	return $_SKIN -> draw_hash ({ 
	
		message => $_REQUEST {error},
		
		field   => $page -> {error_field},
		
	});

}

################################################################################

sub draw_redirect_page {

	my ($_SKIN, $page) = @_;

	return $_SKIN -> draw_hash ({ 
	
		url   => $page -> {url},
		
	});

}

1;