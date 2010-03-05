no warnings;

################################################################################

sub js_escape {
	my ($s) = @_;	
	$s =~ s/\"/\'/gsm; #"
	$s =~ s{[\n\r]+}{ }gsm;
	$s =~ s{\\}{\\\\}g; #'
	$s =~ s{\'}{\\\'}g; #'
	return "'$s'";	
}

################################################################################

sub draw_gantt_bars {}

################################################################################

sub __submit_href {

	my ($_SKIN, $name) = @_;

	"javaScript:var f = document.$name; f.fireEvent ('onsubmit'); f.submit()";

}

################################################################################

sub __adjust_form_field {

	my ($options) = @_;

	my $attributes = ($options -> {attributes} ||= {});

	$attributes -> {class}    ||= $options -> {mandatory} ? 'form-mandatory-inputs' : 'form-active-inputs';

	$attributes -> {tabindex}   = ++ $_REQUEST {__tabindex};

}

################################################################################

sub __adjust_form_field_string {

	my ($options) = @_;

	$options -> {value} =~ s{\"}{\&quot;}gsm;

	my $attributes = ($options -> {attributes} ||= {});

	$attributes -> {value}        = \$options -> {value};
	
	$attributes -> {name}         = '_' . $options -> {name};
			
	$attributes -> {size}         = ($options -> {size} ||= 120);

	$attributes -> {maxlength}    = $options -> {max_len} || $options -> {size} || 255;
	
	$attributes -> {autocomplete} = 'off' unless exists $attributes -> {autocomplete};
		
	$attributes -> {id}           = 'input_' . $options -> {name};

}

################################################################################

sub __adjust_form_field_date {

	__adjust_form_field_string (@_);

}

################################################################################

sub __adjust_form_field_datetime {

	__adjust_form_field_string (@_);

}

################################################################################

sub __adjust_form_field_suggest {

	my ($_SKIN, $options) = @_;

	__adjust_form_field_string (@_);

}

################################################################################

sub __adjust_form_field_hidden {

	my ($options) = @_;

	$options -> {value} =~ s/\"/\&quot\;/gsm; #";

}

################################################################################

sub __adjust_button_href {

	my ($_SKIN, $options) = @_;
	
	my $js_restore_cursor = "document.body.style.cursor = 'default';";
	
	my $cursor_state = $options -> {no_wait_cursor} ? ";window.document.body.onbeforeunload=function(){$js_restore_cursor};" : '';

	if ($options -> {confirm}) {
	
		my $js_action;
		
		if ($options -> {href} =~ /^javaScript\:/i) {
		
			$js_action = $'
		
		}
		else {

			$options -> {target} ||= '_self';
			
			$js_action = "nope('$options->{href}','$options->{target}')";

		}
		
		my $condition = 'confirm(' . js_escape ($options -> {confirm}) . ')';
		
		if ($options -> {preconfirm}) {

			$condition = "!$options->{preconfirm}||($options->{preconfirm}&&$condition)";

		}

		$options -> {href} = qq {javascript:if($condition){$cursor_state$js_action}else{${js_restore_cursor}nop()}};
		
	} 
	elsif ($options -> {no_wait_cursor}) {
	
		$options -> {onclick} = qq {onclick="$cursor_state void(0);"};
		
	} 
		
	if ($options -> {href} =~ /^javaScript\:/i) {
		
		delete $options -> {target};
		
	}

	$options -> {id} ||= '' . $options;

	if ((my $h = $options -> {hotkey}) && !$h -> {off}) {
	
		$h -> {data} = $options -> {id};
		
		hotkey ($h);

	}	

}

################################################################################

sub draw_error_page {

	my ($_SKIN, $page) = @_;

	$_REQUEST {__content_type} ||= 'text/html; charset=' . $i18n -> {_charset};

	my $data = $_JSON -> encode ([$_REQUEST {error}]);

	$_REQUEST {__script} = <<EOJ;
		function on_load () {
EOJ

	if ($page -> {error_field}) {
		$_REQUEST{__script} .= <<EOJ;
			var e = window.parent.document.getElementsByName('$page->{error_field}'); 
			if (e && e[0]) { try {e[0].focus ()} catch (e) {} }				
EOJ
	}
	
	$_REQUEST {__no_back} or $_REQUEST {__script} .= "\n if (window.name != 'invisible') {history.go (-1)}\n";
								
	$_REQUEST {__script} .= <<EOJ;
			var data = $data;
			alert (data [0]);
			try {window.top.setCursor ()} catch (e) {}
			window.parent.document.body.style.cursor = 'default';
		}
EOJ

	return qq{<html><head><script>$_REQUEST{__script}</script></head><body onLoad="on_load ()"></body></html>};

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
	
	$options -> {$_} ||= '' foreach qw (before window_options);

	return <<EOH;
<html>
	<script for=window event=onload>
		$options->{before};
		var w = window; 
		w.open ('$options->{url}&salt=' + Math.random (), $target, '$options->{window_options}');
	</script>
	<body>
	</body>
</html>
EOH

}

1;