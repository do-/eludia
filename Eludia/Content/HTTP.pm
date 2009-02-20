use Eludia::Content::HTTP::FileTools;

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

	if ($_REQUEST {__uri} ne '/' && $url =~ m{^\/\?}) {
		$url =~ s{^\/\?}{$_REQUEST{__uri}\?};
	}

	$options ||= {};
	$options -> {kind} ||= 'http';
	$options -> {kind}   = 'http' if ($_REQUEST {__windows_ce} && $_REQUEST {select});

	if ($options -> {kind} eq 'js') {
	
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

1;