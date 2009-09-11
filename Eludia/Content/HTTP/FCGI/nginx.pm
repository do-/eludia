use FCGI;
use Eludia::Content::HTTP::API;
use IO;

sub start {

	my $request = FCGI::Request (\*STDIN, \*STDOUT, new IO::File, \%ENV, FCGI::OpenSocket ($_[0] || ':9000', $_[1] || 10));

	while ($request -> Accept >= 0) {

		my $app = $ENV {DOCUMENT_ROOT};

		$app =~ s{/docroot/?$}{};

		check_configuration_and_handle_request_for_application ($app);

	}

}

1;