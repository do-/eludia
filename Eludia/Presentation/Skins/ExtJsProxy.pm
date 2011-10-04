package Eludia::Presentation::Skins::ExtJsProxy;

################################################################################

sub options { return {}}

################################################################################

sub no_presentation {1}

################################################################################

sub static_path {

	my ($package, $file) = @_;
	my $path = __FILE__;

	$path    =~ s{\.pm}{/$file};

	return $path;

};

################################################################################

sub draw_hash {

	my ($_SKIN, $h) = @_;

	$_REQUEST {__content_type} ||= 'application/json; charset=utf-8';

	$_JSON -> encode ($h);

}

################################################################################

sub draw_page {

	my ($_SKIN, $page) = @_;
	
	$page -> {success} = \1;
		
	return $_SKIN -> draw_hash ($page);

}

################################################################################

sub draw_auth_toolbar  {}
sub register_hotkey    {}
sub __adjust_menu_item {}
sub draw_menu          {}

################################################################################

sub draw_error_page {

	my ($_SKIN, $page) = @_;
	
	$page -> {error_field} =~ s{^_}{};

	return $_SKIN -> draw_hash ({ 
	
		success => \0,
	
		message => $_REQUEST {error},
		
		field   => $page -> {error_field},
		
	});

}

###############################################################################

sub draw_redirect_page {

	my ($_SKIN, $page) = @_;

	return $_SKIN -> draw_hash ({ 
	
		success => 'redirect',
	
		url   => $page -> {url},
		
	});

}

1;