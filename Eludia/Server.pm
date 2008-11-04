##/usr/bin/perl -w

use HTTP::Headers;
use HTTP::Daemon;
use HTTP::Status;

use CGI;
use Data::Dumper;

use Config::ApacheFormat;

use File::Temp qw/:POSIX/;

use Time::HiRes 'time';

no strict;
no warnings;	

################################################################################

sub start {

	my $config = Config::ApacheFormat -> new ();

	open (ACCESS_LOG, ">>logs/access.log");
#	open (STDERR, ">>logs/error.log");

	open (I, "conf/httpd.conf");
	my $src = join '', (<I>);
	close (I);

	$src =~ s{\<perl\>(.*?)\</perl\>}{}gsm;
	my $perl_section = $1;
	
	my $temp = $ENV{TEMP};
	$temp =~ y{\\}{/};
	
	$perl_section =~ s/\%TEMP\%/$temp/;

	eval $perl_section;	
	print STDERR $@ if $@;	

	my $fn = tmpnam ();
	open (T, ">$fn");
	print T $src;
	close (T);

	$config -> read ($fn);

	unlink $fn;

	our $document_root = $config -> get ('DocumentRoot');

	my @locations = map {{uri => $_ -> [1]}} $config -> get ('Location');

	foreach my $location (@locations) {

		my $block = $config -> block (Location => $location -> {uri});
		$location -> {handler} = $block -> get ('SetHandler');
		if ($location -> {handler} eq 'perl-script') {
			$location -> {perl_handler} = $block -> get ('PerlHandler');
			$location -> {perl_handler} .= '::handler' unless $location -> {perl_handler} =~ /\:\:/;		
			$location -> {perl_handler} =~ /\:\:/;
			$location -> {perl_module} = $`;
			$location -> {perl_sub} = $';
			eval "require $$location{perl_module}";
		}

	}

	my @perl_locations = 

		sort { index ($a -> {uri}, $b -> {uri}) == 0 ? -1 : index ($b -> {uri}, $a -> {uri}) == 0 ? 1 : 0}

			grep {$_ -> {handler} eq 'perl-script'} @locations;


	my @sub_body = map {<<EOS} @perl_locations;
		if (\$uri =~ m{^$$_{uri}}) {
			\$$$_{perl_module}::connection = \$connection;
			\$$$_{perl_module}::request    = \$request;
			\$ENV {'PERL_MODULE'} = '$$_{perl_module}';
			package $$_{perl_module};
			return $$_{perl_sub} (\$uri);			
		}
EOS

	my $sub_src = <<EOS;
	sub exec_handler {
		my (\$connection, \$request, \$uri) = \@_;
	@sub_body
	}
EOS

warn $sub_src;

	eval $sub_src;
	
	my ($host, $port) = split /:/, ($_[0] || $ARGV [0] || 'localhost:80');

	my $daemon = new HTTP::Daemon (
#		LocalAddr => $host, 
		LocalPort => $port,
		Listen    => 50,

	) or die "Can't start HTTP daemon: $!\n";

	print STDERR "HTTP daemon is listening on ", $daemon -> url, "...\n";
	
	$ENV {'SERVER_SOFTWARE'} = $daemon -> product_tokens;
	
	if ($^O eq 'MSWin32') {
	
		my $pidfile = "$temp\\eludia.pid";
		open (PIDFILE, ">$pidfile");
		print PIDFILE $$;		
		close (PIDFILE);
		
	}

	while (my $connection = $daemon -> accept) {

		eval {
			handle_connection ($connection);
		};
		if ($@) {
			$connection -> send_error (500, "<pre>$@</pre>");
		}

	}
	
}

################################################################################

sub handle_connection {

	my $connection = $_[0];

	if (my $request = $connection -> get_request) {

		my $uri = $request -> uri -> as_string;
		
		print ACCESS_LOG $request -> method . " $uri\n";

		if ($uri =~ m{^/i/}) {
		
#warn Dumper ($request -> headers);

			my $path = $document_root . $uri;
			$path =~ s{\?.*}{};

			$| = 1;
			
			$connection -> send_basic_header;
			print $connection "Cache-Control: max-age=" . 24 * 60 * 60;
			$connection -> send_crlf;
			$connection -> send_crlf;
			$connection -> send_file ($path);
			
		}
		else {

			$uri =~ s{^/+}{/};
			$uri =~ s{/+$}{/};
		
			$ENV {'DOCUMENT_ROOT'} = $document_root;

			$ENV {'REMOTE_HOST'} = $connection -> peerhost;
			$ENV {'REMOTE_ADDR'} = $connection -> peerhost;
			
			$ENV {'HTTP_HOST'}   = $request -> header ('host');
			$ENV {'SERVER_PORT'} = $connection -> sockport;
		
			$ENV {'REQUEST_METHOD'} = $request -> method;
			$ENV {'REQUEST_URI'}    = $uri;
			
			$ENV {'CONTENT_TYPE'} = $request -> headers -> header ('Content-Type');
			$ENV {'CONTENT_LENGTH'} = $request -> headers -> header ('Content-Length');

			if ($uri =~ m{\/\?}) {
				$ENV {'PATH_INFO'}    = $` . '/';
				$ENV {'QUERY_STRING'} = $';
			}
			else {
				$ENV {'QUERY_STRING'} = '';
				$ENV {'PATH_INFO'}    = $uri;
			}

			local *STDOUT = $connection;

			exec_handler ($connection, $request, $uri);
						
		}				

	}

	$connection -> close ();

	undef ($connection);
	
print STDERR "\n";

}

1;