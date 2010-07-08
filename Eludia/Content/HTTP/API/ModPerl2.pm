use constant MP2 => 1;

################################################################################

sub get_request {

	our $r        = $_[0];
	our $apr      = Apache2::Request -> new ($r);
	our %_COOKIES = Apache2::Cookie  -> fetch;
	our %_REQUEST = %{$apr -> param};

}

################################################################################

sub send_http_header {}

################################################################################

sub set_cookie {

	my $cookie = Apache2::Cookie -> new ($r, @_);
		
	$r -> err_headers_out -> add ('Set-Cookie' => $cookie -> as_string);

}

################################################################################

sub upload_file_dimensions {

	my ($upload) = @_;
	
	($upload -> upload_fh, $upload -> upload_filename, $upload -> upload_size, $upload -> upload_type);

}

################################################################################

sub _ok {0};

################################################################################

BEGIN {
	
	require Apache2::Request;
	require Apache2::compat;
	require Apache2::Cookie;

#	$ENV {PERL_JSON_BACKEND} = 'JSON::PP';

	Apache -> push_handlers (PerlChildInitHandler => \&sql_reconnect );
	Apache -> push_handlers (PerlChildExitHandler => \&sql_disconnect);

	print STDERR "Apache2::Request $Apache2::Request::VERSION, ok.\n";

}

1;