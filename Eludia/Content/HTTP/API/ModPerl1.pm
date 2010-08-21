use constant MP2 => 0;

################################################################################

sub get_request {

	our $r        = $_[0];
	our $apr      = Apache::Request -> new ($r);
	our %_COOKIES = Apache::Cookie -> fetch;
	our %_REQUEST = %{$apr -> parms};

}

################################################################################

sub send_http_header {

	$r -> send_http_header;

}

################################################################################

sub set_cookie {

	my $cookie = Apache::Cookie -> new ($r, @_);
		
	$r -> err_headers_out -> add ('Set-Cookie' => $cookie -> as_string);

}

################################################################################

sub upload_file_dimensions {

	my ($upload) = @_;
	
	($upload -> fh, $upload -> filename, $upload -> size, $upload -> type);

}

################################################################################

sub _ok {200};

################################################################################

BEGIN {

	require Apache::Request;
	require Apache::Cookie;

	Apache -> push_handlers (PerlChildInitHandler => \&sql_reconnect );
	Apache -> push_handlers (PerlChildExitHandler => \&sql_disconnect);

	loading_log "Apache::Request $Apache::Request::VERSION, ok.\n";

}

1;