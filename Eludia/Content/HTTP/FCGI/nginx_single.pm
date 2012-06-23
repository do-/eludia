use FCGI;
use IO;
use Eludia::Content::HTTP::API;
use Getopt::Long;
use Data::Dumper;

################################################################################

sub options_win32 {

	my %options = @_;
	
	$options {-backlog}      ||= 1024;
	$options {-processes}    ||= 2;
	$options {-timeout}      ||= 1;

	return %options;

}

################################################################################

sub start {

	my $len = 60;
	
	my $bar	= '+' . ('-' x ($len + 2)) . "+\n";

	my $line = sub {
		my ($k, $v) = @_;
		my $bar = '.' x ($len - length ($k) - length ($v));
		return "+ ${k}${bar}${v} +\n";
	};

	my %options = options_win32 (@_);
	
	warn "\n -------------------------------------------------\n";
	warn " == Starting Eludia.pm FastCGI server for nginx ==\n";
	warn " -------------------------------------------------\n\n";

	unless ($options {-nginx_conf}) {
	
		print STDERR "Nginx configuration file location is unknown, looking for running process...";
	
		eval  {

			my $ps = `wmic process where (name="nginx.exe") get executablepath 2>&1`;
			
			foreach (split /[\r\n]+/, $ps) {
				s{nginx\.exe\s*$}{conf\\nginx.conf}i or next;
				$options {-nginx_conf} = $_ and last;
			}
			
			if ($options {-nginx_conf}) {
				print STDERR "Found!\nThe config should be $options{-nginx_conf}\n";
			}
			else {
				$ps =~ s/\s+$//gsm;
				print STDERR "\nNo luck: WMIC said ``$ps'' :-(\n(Could you you fire up nginx before?)\n";
				$options {-nginx_conf} = "C:\\nginx\\conf\\nginx.conf";
				print STDERR "Falling back to $options{-nginx_conf}\n";
			}			
						
		}		
		
	}
	
	my $nginx = {conf => $options {-nginx_conf}};
			
	-f $nginx -> {conf} or die "$nginx->{conf} is not a file, giving up\n";

	open (N, $nginx -> {conf}) or die "Can't open $nginx->{conf}: $!\n";

	print STDERR "Reading nginx configuration...\n";

	open STDOUT, '>/dev/null';

	while (<N>) {

		next if /^\s*\#/;
		
		if (/^\s*server\s+127\.0\.0\.1(\:\d+)/ && !$options {-address}) {
			$options {-address} = $1;
			print STDERR "By the way, seems like we are meant to listen at 127.0.0.1$options{-address}.\n";
			next;
		}		
		
		/root\s+/ or next;
		
		my $app = $';
		
		$app =~ s{\s*;\s*$}{};
		
		if ($app =~ /^"(.*)"$/) {$app = $1}

		$app =~ s{/docroot/?.*}{};
		
		print STDERR "Found some document root at $app...";
		
		if (-f "$app/conf/httpd.conf" and -f "$app/lib/Config.pm") {

			print STDERR " yes, this is ours. Let's load it...\n";

		}
		else {
		
			print STDERR " oh sorry, I'm mistaken\n" and next;
		
		}
		
		next if $main::configs -> {$app};
			
		check_configuration_for_application ($app);

		print STDERR "Trying $app...\n";
		
		$ENV {SCRIPT_NAME} = '/__try__and__disconnect';

		my $error = handle_request_for_application ($app);
					
		die $error if $error;

	}
	
	close (N);
	
	my $socket = FCGI::OpenSocket ($options {-address}, $options {-backlog});
			
	my $request = FCGI::Request (\*STDIN, \*STDOUT, new IO::File, \%ENV, $socket);

	while ($request -> Accept >= 0) {

		my $app = $ENV {DOCUMENT_ROOT};

		$app =~ s{/docroot/?$}{};

		open (STDERR, ">>$app/logs/error.log");
		
		eval {

			check_configuration_and_handle_request_for_application ($app);
		
		};

	}

}

1;