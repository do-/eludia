no warnings;

#################################################################################

sub get_request_problem {

	get_request (@_);

	$ENV {REQUEST_METHOD} eq 'POST' or return 405;
	
	my $enctype = $r -> header_in ('Content-Type');
	
	$enctype eq 'application/json' or $enctype eq 'text/plain' or return (400 => 'Wrong Content-Type');

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
		
		$_REQUEST {data} -> {lc $'} = $s;
	
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

sub out_html {

	my ($options, $html) = @_;

	$html and !$_REQUEST {__response_sent} or return;

	__profile_in ('core.out_html'); 

	$html = Encode::encode ('utf-8', $html);

	return print $html if $_REQUEST {__response_started};

	$r -> content_type ($_REQUEST {__content_type}) if $_REQUEST {__content_type};
	
	$r -> headers_out -> {'Content-Length'} = my $length = length $html;
		
	send_http_header ();

	$r -> header_only && !MP2 or print $html;
	
	$_REQUEST {__response_sent} = 1;

	__profile_out ('core.out_html' => {label => "$length bytes"});

}

################################################################################

sub out_json ($) {

	$_REQUEST {__content_type} = 'application/json';
	
	my ($page) = @_;

	eval {out_html ({}, $_JSON -> encode ($page))};

	$@ or return;
	
	$@ =~ /^encountered CODE/ or die $@;

	my %content = %{delete $page -> {content}};

	my $json_page = $_JSON -> encode ($page); chop $json_page;
	
	my @c = (); while (my ($k, $v) = each %content) {$c [CODE eq ref $v] -> {$k} = $v}

	my $json_content = $_JSON -> encode ($c [0]); chop $json_content;

	$r -> content_type ($_REQUEST {__content_type});
			
	send_http_header ();

	print $json_page;
	print ',"content":';
	print $json_content;

	while (my ($k, $v) = each %{$c [1]}) {
		print qq{,"$k":"}; #"
		&$v ();
		print '"';
	}
	
	print '}}';

}

1;