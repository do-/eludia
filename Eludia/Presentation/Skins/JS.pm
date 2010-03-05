package Eludia::Presentation::Skins::JS;

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

sub static_path {

	my ($package, $file) = @_;
	
	$file ||= '';
	
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
		
		if ($field -> {type} eq 'date' || $field -> {type} eq 'datetime') {

			$_REQUEST{__on_load} .= " load_$field->{name} (); ";

			$_REQUEST {__script} .= <<EOJS;
				function load_$field->{name} () {
					var doc = window.parent.document;
					var element = doc.getElementById ('input$field->{name}');
					if (!element) return;					
					element.value = '$field->{value}';
				}
EOJS
			return '';
		
		}
		
		my $a = $_JSON -> encode ([$field -> {html}]);
		
		$_REQUEST{__on_load} .= " load_$field->{name} (); ";

		my $field_name = $field -> {name};
		$field_name .= '_span' if ($field -> {type} eq 'string_voc');

		$_REQUEST {__script} .= <<EOJS;
	function load_$field->{name} () {
		var a = $a;				
		var doc = window.parent.document;
EOJS

		if ($field -> {type} eq 'radio') {
			$_REQUEST {__script} .= <<EOJS;
		var element = doc.getElementById ('input_$field->{name}');
EOJS
		} else {
			$_REQUEST {__script} .= <<EOJS;
		var element = doc.getElementById ('input_$field_name');
		if (!element) element = doc.forms ['$_REQUEST{__only_form}'].elements ['_$field_name'];
		if (!element) element = doc.forms ['$_REQUEST{__only_form}'].all.namedItem ('_$field_name');
EOJS
		}

		$_REQUEST {__script} .= <<EOJS;
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
