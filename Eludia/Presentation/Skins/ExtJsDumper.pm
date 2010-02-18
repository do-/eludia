package Eludia::Presentation::Skins::ExtJsDumper;

################################################################################

sub options { return {no_presentation => 1}}

################################################################################

sub no_presentation { 1 }

################################################################################

sub draw_hash {

	my ($_SKIN, $h) = @_;

	$_REQUEST {__content_type} ||= 'application/json; charset=' . $i18n -> {_charset};
	
	$_JSON -> pretty (1);
	
	$_JSON -> canonical ([$enable]);

	$_JSON -> encode ($h);

}

################################################################################

sub draw_page {

	my ($_SKIN, $page) = @_;
	
	my $c = $page -> {content};
	
	$c -> {success} = 1;
	
#	while (my ($k, $v) = each %$_USER) {

#		$c -> {"__user_$k"} = $v;

#	}
	
	while (my ($k, $v) = each %_REQUEST) {

		next if ref $v;

		$c -> {__request} -> {$k} = $v;

	}
	
	$c -> {__subsets} = $_SUBSET -> {items};
	
	$c -> {__menu} = $page -> {menu};

	return $_SKIN -> draw_hash ($c);

}

################################################################################

sub draw_error_page {

	my ($_SKIN, $page) = @_;

	return $_SKIN -> draw_hash ({

		success => 0,
		
		errorMessage => $_REQUEST {error},

		errors => {

			$page -> {error_field} => $_REQUEST {error},

		},

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