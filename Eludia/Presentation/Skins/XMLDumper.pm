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

sub draw_page {

	my ($_SKIN, $page) = @_;

	$_REQUEST {__content_type} ||= 'text/plain; charset=' . $i18n -> {_charset};
						
	return XML::Simple::XMLout (
		{ content => $page -> {content} }, 
		RootName => 'data', 
		XMLDecl  => qq{<?xml version="1.0" encoding="$i18n->{_charset}"?>},
	)

}

################################################################################

sub draw_error_page {

	my ($_SKIN, $page) = @_;

	$_REQUEST {__content_type} ||= 'text/plain; charset=' . $i18n -> {_charset};

	return XML::Simple::XMLout ({
		message => $_REQUEST {error},
		field   => $page -> {error_field},
	}, 
		RootName => 'error',
		XMLDecl  => qq{<?xml version="1.0" encoding="$i18n->{_charset}"?>},
	);

}

1;