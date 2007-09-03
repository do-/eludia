package Eludia::Presentation::Skins::XMLDumper;

use XML::Simple;

################################################################################

sub options {
	return {
		no_presentation => 1,
	};
}

################################################################################

sub no_presentation {
	return 1;
}

################################################################################

sub draw_hash {

	my ($_SKIN, $h) = @_;

	$_REQUEST {__content_type} ||= 'text/plain; charset=' . $i18n -> {_charset};
						
	return XML::Simple::XMLout (
		$h, 
		RootName => 'data', 
		XMLDecl  => qq{<?xml version="1.0" encoding="$i18n->{_charset}"?>},
	)

}

################################################################################

sub draw_page {

	my ($_SKIN, $page) = @_;
	
	return $_SKIN -> draw_hash ({ 
		content => $page -> {content}
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