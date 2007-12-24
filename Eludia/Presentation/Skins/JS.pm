package Eludia::Presentation::Skins::JS;

use JSON::XS;

################################################################################

sub options {

	return {
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
			window.parent.document.body.style.cursor = 'default';
		}
EOJ

	return qq{<html><head><script>$_REQUEST{__script}</script></head><body onLoad="onload ()"></body><html>};

}

################################################################################

sub draw_redirect_page {

	my ($_SKIN, $options) = @_;

	my $target = 
		$options -> {target} ? "'$$options{target}'" : 
		"(window.name == 'invisible' ? '_parent' : '_self')";

	if ($options -> {label}) {
		my $data = $_JSON -> encode ([$options -> {label}]);
		$options -> {before} = "var data = $data; alert(data[0]); ";
	}
	
	$$options{before} .= ';' if $$options{before};

	return <<EOH;
<html>
	<script for=window event=onload>
		$$options{before}
		var w = window; 
		w.open ('$options->{url}&salt=' + Math.random (), $target);
	</script>
	<body>
	</body>
</html>
EOH

}

################################################################################

sub static_path {

	my ($package, $file) = @_;
	my $path = __FILE__;

	$path    =~ s{\.pm}{/$file};

	return $path;

};

################################################################################

sub draw_form_field {

	my ($_SKIN, $field, $data) = @_;
	

	if ($_REQUEST {__only_form}) {
		my $js;
		my @fields = split (',', $_REQUEST {__only_field});
		my @tabs = split (',', $_REQUEST {__only_tabindex});
		my $i;
		for ($i = 0; $i < @fields; $i ++) {
			last if $fields [$i] eq $field -> {name};
		}
		
		my $a = $_JSON -> encode ([$field -> {html}]);
		
		$_REQUEST{__on_load} .= " load_$field->{name} (); ";
			
		$_REQUEST {__script} .= <<EOJS;
	function load_$field->{name} () {
		var a = $a;				
		var doc = window.parent.document;				
		var element = doc.forms ['$_REQUEST{__only_form}'].elements ['_$field->{name}'];
		if (!element) element = doc.getElementById ('input_$field->{name}');
		if (!element) return;					
		element.outerHTML = a [0];
		element.tabIndex = "$tabs[$i]";
//		if (element.onChange) element.onChange ();
	}
EOJS
		
		return '';
	}
	
}			

1;
