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
			
			$options -> {href} =~ s{\%}{\%25}g;
			
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

	$options -> {id} ||= '' . $options;

	if ((my $h = $options -> {hotkey}) && !$h -> {off}) {
	
		$h -> {data} = $options -> {id};
		
		hotkey ($h);

	}	

}

1;