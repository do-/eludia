no warnings;

#################################################################################

sub get_request_problem {

	get_request (@_);

	$ENV {REQUEST_METHOD} eq 'POST' or return 405;
	
	$r -> header_in ('Content-Type') eq 'application/json' or return (400 => 'Wrong Content-Type');

	Encode::_utf8_on ($_) foreach (values %_REQUEST);
	
	setup_json ();

	if (my $postdata = delete $_REQUEST {POSTDATA}) {
	
		eval {%_REQUEST = (%_REQUEST, %{$_JSON -> decode ($postdata)})};
		
		$@ and return (400 => 'Wrong JSON');
		
	}

	while (my ($k, $v) = each %{$r -> {headers_in}}) {
	
		$k =~ /X-Request-Param-/ or next;
		
		my $s = uri_unescape ($v);
		
		Encode::_utf8_on ($s);
		
		$_REQUEST {lc $'} = $s;
	
	}

	undef;

}

#################################################################################

sub is_request_ok {

	my ($code, $message) = get_request_problem (@_);
	
	$code or return 1;

	$r -> status ($code);
	send_http_header ();
	$r -> print ($message);	
	
	warn "Request problem $code $message\n";
	
	return 0;
	
}

################################################################################

sub recalculate_sessions {

	$_REQUEST {action} =~ /^execute/ or return;
	
	$_USER = get_user ();
	
	$_USER -> {id} or return;
	
	my $h = {
		ip    => $ENV {REMOTE_ADDR},
		ip_fw => $ENV {HTTP_X_FORWARDED_FOR},
	};
	
	$h -> {tz_offset} = $_REQUEST {tz_offset} if $preconf -> {core_fix_tz} && $_REQUEST {tz_offset};
	
	if ($conf -> {core_delegation} && !$_USER -> {id__real}) {
		$_USER -> {id__real} or $h -> {id_user_real} = $_USER -> {id};
	}
	
	sql_select_id ($conf -> {systables} -> {sessions} => $h, ['id']);
	
}

################################################################################

sub out_html {

	my ($options, $html) = @_;

	$html and !$_REQUEST {__response_sent} or return;

	__profile_in ('core.out_html'); 

	$html = Encode::encode ('utf-8', $html);

	return print $html if $_REQUEST {__response_started};

	$r -> content_type ($_REQUEST {__content_type} ||= 'text/html; charset=utf-8');
	
	$r -> headers_out -> {'Content-Length'} = my $length = length $html;
		
	send_http_header ();

	$r -> header_only && !MP2 or print $html;
	
	$_REQUEST {__response_sent} = 1;

	__profile_out ('core.out_html' => {label => "$length bytes"});

}

################################################################################

sub out_json ($) {

	$_REQUEST {__content_type} = 'application/json';

	out_html ({}, $_JSON -> encode ($_[0]));

}

1;