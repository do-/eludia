package Eludia::Presentation::Skins::JS;

use JSON::XS;

BEGIN {
	our $_JSON = JSON::XS -> new -> latin1 (1);	
}

################################################################################

sub options {

	return {
		no_static => 1,
		no_navigation => 1,
	};

}

################################################################################

sub draw_page {

	my ($_SKIN, $page) = @_;

	$_REQUEST {__content_type} ||= 'text/plain; charset=' . $i18n -> {_charset};
						
	return qq{<html><head><script>$_REQUEST{__script}</script></head><body onLoad="$_REQUEST{__on_load}"></body><html>};

}

################################################################################

sub draw_error_page {

	my ($_SKIN, $page) = @_;

	$_REQUEST {__content_type} ||= 'text/plain; charset=' . $i18n -> {_charset};

	my $data = $_JSON -> encode ([$_REQUEST {error}]);

	$_REQUEST {__script} = <<EOJ;
		function onload () {
EOJ

	if ($page -> {error_field}) {
		$_REQUEST{__script} .= <<EOJ;
			var e = window.parent.document.getElementsByName('$page->{error_field}'); 
			if (e && e[0]) { try {e[0].focus ()} catch (e) {} }				
EOJ
	}
								
	$_REQUEST {__script} .= <<EOJ;
			history.go (-1);
			var data = $data;
			alert (data [0]);
			window.parent.document.body.style.cursor = 'normal';
		}
EOJ

	return qq{<html><head><script>$_REQUEST{__script}</script></head><body onLoad="onload ()"></body><html>};

}

1;