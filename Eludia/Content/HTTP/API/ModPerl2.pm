use constant MP2 => 1;

################################################################################

sub get_request {

	our $r        = $_[0];
	our $apr      = Apache2::Request -> new ($r);
	our %_COOKIES = Apache2::Cookie  -> fetch;

}

################################################################################

sub send_http_header {}

################################################################################

sub set_cookie {

	my $cookie = Apache2::Cookie -> new ($r, @_);
		
	$r -> err_headers_out -> add ('Set-Cookie' => $cookie -> as_string);

}

################################################################################

sub _ok {0};

################################################################################

BEGIN {
	
	require Apache2::Request;
	require Apache2::compat;
	require Apache2::Cookie;

	$ENV {PERL_JSON_BACKEND} = 'JSON::PP';		

	print STDERR "mod_perl 2.x, ok.\n";

	Apache2 -> push_handlers (PerlChildInitHandler => \&sql_reconnect );
	Apache2 -> push_handlers (PerlChildExitHandler => \&sql_disconnect);

}

1;