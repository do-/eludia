use threads;

use FCGI;
use IO;
use Eludia::Content::HTTP::API;

sub start {

	if ($^O eq 'MSWin32') {

		threads -> create (sub {

			require Win32::Pipe;

			$_[0] =~ /\d+/;

			my $pipe_out = new Win32::Pipe ("\\\\.\\pipe\\winserv.scm.out.Eludia_$&");
			my $pipe_in  = new Win32::Pipe ("\\\\.\\pipe\\winserv.scm.in.Eludia_$&");

			$pipe_in -> Read ();

			exit;

		}, @_) -> detach;
	
	}

	while (1) {

		threads -> create ({'exit' => 'threads_only'}, sub {

			my $request = FCGI::Request (\*STDIN, \*STDOUT, new IO::File, \%ENV, FCGI::OpenSocket ($_[0], $_[2] || 10));

			while ($request -> Accept >= 0) {

				my $app = $ENV {DOCUMENT_ROOT};

				$app =~ s{/docroot/?$}{};

				check_configuration_and_handle_request_for_application ($app);

			}

		}, @_) -> join;	
	
	}

}

1;