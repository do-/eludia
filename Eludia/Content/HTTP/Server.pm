##/usr/bin/perl -w

use HTTP::Headers;
use HTTP::Daemon;
use HTTP::Status;

use CGI;
use Carp;
use Data::Dumper;

use File::Temp qw/:POSIX/;

use Time::HiRes 'time';

no strict;
no warnings;

$SIG {__DIE__} = \&Carp::confess;

################################################################################

sub start {
	
	$ENV {GATEWAY_INTERFACE} = 'CGI/';

	open (ACCESS_LOG, ">>logs/access.log");
#	open (STDERR, ">>logs/error.log");

	my $src = '';

	my $perl_section = '';
	my $current_section = '';
	our $sections = {};

	open (I, "conf/httpd.conf");
	while (my $line = <I>) {
	
		$line =~ s{[\n\r]}{}gsm;
		
		if ($line =~ /^\s*\<\/.*\>\s*$/) {
			$current_section = '';
			next;
		}

		if ($line =~ /^\s*\<(.*)\>\s*$/) {
			$current_section = $1;
			next;
		}
		
		if ($current_section =~ /^perl\s*$/i) {
			$perl_section .= "$line\n";
			next;
		}

		if ($line =~ /^\s*(\w+)\s+(.*)\s*$/) {
			my ($k, $v) = ($1, $2);
			$v =~ s{^\"(.*)\"$}{$1};
			$sections -> {$current_section} -> {$k} = $v;
		}
				
	}
	
	our $document_root = $sections -> {''} -> {DocumentRoot};

	$document_root or die "DocumentRoot not found\n";
	
	my $temp = $ENV{TEMP};
	$temp =~ y{\\}{/};
	
	$perl_section =~ s/\%TEMP\%/$temp/;

	eval $perl_section;
	print STDERR "$@\n\n$perl_section" if $@;	
	
	my $sub_src = "sub exec_handler {\n my (\$connection, \$request, \$uri) = \@_;\n";

	foreach my $k (keys %$sections) {
	
		$k =~ /^Location\s+/ or next;
		
		my $uri = $';
		
		my $location = $sections -> {$k};
		
		$location -> {SetHandler} eq 'perl-script' or next;
		
		$location -> {PerlHandler} .= '::handler' unless $location -> {PerlHandler} =~ /\:\:/;		
		$location -> {PerlHandler} =~ /\:\:/;
		$location -> {perl_module} = $`;
		$location -> {perl_sub} = $';

		$sub_src .= <<EOS;
			if (\$uri =~ m{^${uri}}) {
				\$$$location{perl_module}::connection = \$connection;
				\$$$location{perl_module}::request    = \$request;
				\$ENV {'PERL_MODULE'} = '$$_{perl_module}';
				package $$location{perl_module};
				return $$location{perl_sub} (\$uri);			
			}
EOS

	}
	
	$sub_src .= "}\n";

	eval $sub_src;
		
	my ($host, $port) = split /:/, ($_[0] || $ARGV [0] || 'localhost:80');

	my $daemon;
	
	while (1) {
	
		$daemon = new HTTP::Daemon (
			LocalPort => $port,
			Listen    => 50,
			Reuse     => 1,
		) and last;
						
		my $error = $@ || $!;
		
		if ($error =~ /already in use/) {
		
			warn "Port $port is in use, wait 1s...\n";
		
			sleep 1;
			
			next;
		
		}
		elsif ($error) {
		
			die $error;
		
		}
		else {
		
			$daemon or die "\$daemon is left undefined without any error: epic fail :-((\n";
		
		}
		
		last;
	
	}
	
	print STDERR "HTTP daemon is listening on ", $daemon -> url, "...\n";
	
	$ENV {'SERVER_SOFTWARE'} = $daemon -> product_tokens;
		
	my $pidfile = "logs/$port.pid";

	open (PIDFILE, ">$pidfile");
	print PIDFILE $$;		
	close (PIDFILE);
	
	my $n = $_[1] || -1;

	my $shut_down = sub {

		warn "$$ is shutting down.\n";
		
		$daemon -> close;
		
		unlink $pidfile;

		exit;

	};
	
	$SIG {INT}  = $shut_down;
	$SIG {TERM} = $shut_down;
	
	while (my $connection = $daemon -> accept) {

		eval {
			handle_connection ($connection);
		};
		
		if ($@) {
			$connection -> send_error (500, "<pre>$@</pre>");
		}

		$connection -> close;
		
		undef ($connection);
		
		$n -- if $n > 0;
		
		warn "$$: it lasts $n requests\n";
		
		$n or $daemon -> close and &$shut_down ();

	}
		
}

################################################################################

sub handle_connection {

	my $connection = $_[0];
		
	my $request = $connection -> get_request;

	$connection -> force_last_request;
	
	if ($request) {

		my $uri = $request -> uri -> as_string;
		
		print ACCESS_LOG $request -> method . " $uri\n";

		if ($uri =~ m{^/i/}) {
		
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

}

1;