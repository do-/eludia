use Eludia::Content::HTTP::FileTools;

################################################################################

sub set_cookie_for_root {

	my ($name, $value, $expires) = @_;


	if ($value) {
		$expires ||= '+1M';
	} else {
		$value = '1';
	}

	my @expires = (-expires => $expires);
	if ($expires eq 'session') {
		@expires = ();
	}

	set_cookie (-name => $name, -value => $value, -path => '/', @expires);
}

################################################################################

sub esc {

	my ($options) = @_;
	
	$options -> {kind} = 'js';

	redirect (esc_href (), $options);

}

################################################################################

sub redirect {

	my ($url, $options) = @_;

	if (ref $url eq HASH) {
		$url = create_url (%$url);
	}
	
	if ($options -> {keep_esc}) {
		$url =~ s{[\&\?]__last_query_string=\d*}{};
		$url =~ s{[\&\?]__last_scrollable_table_row=\d*}{};
		$url .= "&__last_query_string=$_REQUEST{__last_last_query_string}&__last_scrollable_table_row=$_REQUEST{__last_scrollable_table_row}";
	}

	if ($_REQUEST {__uri} ne '/' && $url =~ m{^\/\?}) {
		$url =~ s{^\/\?}{$_REQUEST{__uri}\?};
	}

	$options ||= {};
	$options -> {kind} ||= 'http';
	$options -> {kind}   = 'http' if ($_REQUEST {__windows_ce} && $_REQUEST {select});

	if ($options -> {kind} eq 'js') {
	
		setup_skin ();
		$options -> {url} = $url;	
		out_html ({}, draw_redirect_page ($options));
		
	}
	elsif ($options -> {kind} eq 'http' || $options -> {kind} eq 'internal') {

		$r -> status ($options -> {status} || 302);
		$r -> headers_out -> {'Location'} = $url;
		send_http_header ();
		
	}

	$_REQUEST {__response_sent} = 1;
	
}

################################################################################

sub external_session {

	my ($host, $login_params, $ua_options) = @_;

	require LWP::UserAgent;
		
	require Eludia::Content::HTTP::ExternalSession;
	
	$_JSON or setup_json ();
	
	my $o = {
	
		json => $_JSON,
	
		host => $host,
	
		ua   => LWP::UserAgent -> new (%{$ua_options || {}}),
	
		package  => current_package (),

	};
	
	push @{$o -> {ua} -> requests_redirectable}, 'POST';	
	
	$o -> {ua} -> agent ('Want JSON');

	require HTTP::Cookies;
	require File::Temp;

	$o -> {ua} -> cookie_jar (HTTP::Cookies -> new (file => File::Temp::tempfile ()));

	bless $o, 'Eludia::Content::HTTP::ExternalSession';
	
}

1;