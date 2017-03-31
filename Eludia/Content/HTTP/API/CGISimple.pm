no warnings;

use constant MP2 => 0;

################################################################################

sub get_request {

	my @params = $connection ? ($connection, $request) : ();
	
	our $r        = new Eludia::ApacheLikeRequest (@params);
	our $apr      = $r;
	our %_COOKIES = CGI::Simple::Cookie -> parse ($r -> {headers_in} -> {Cookie});
	our %_REQUEST = %{$apr -> parms};

}

################################################################################

sub send_http_header {

	$r -> send_http_header;

}

################################################################################

sub set_cookie {

	my $cookie = CGI::Simple::Cookie -> new (@_);
	
	unless ($cookie) {
	
		warn "WARNING: no cookie set for " . Data::Dumper::Dumper (\@_));
		
		return;
	
	}

	push @{$r -> {_headers} -> {'Set-Cookie'}}, $cookie -> as_string;

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

	require CGI::Simple;
	require CGI::Simple::Cookie;

	loading_log "CGI::Simple, ok.\n";

}

################################################################################
################################################################################

package Eludia::ApacheLikeRequest;

use HTTP::Response;
use HTTP::Headers;
use HTTP::Status;

use File::Temp qw/:POSIX/;

################################################################################

sub args {

	return $ENV {QUERY_STRING};
	
}

################################################################################

sub post_data {

	my $self = shift;
	
	return $self -> {Q} -> param ('POSTDATA');
	
}

################################################################################

sub header_in {

	my $self = shift;
	
	return $self -> {Q} -> http ($_ [0]);
	
}

################################################################################

sub content_type {

	my $self = shift;
	
	return $self -> {headers} -> content_type (@_);
	
}

################################################################################

sub content_encoding {

	my $self = shift;
	
	return $self -> {headers} -> content_encoding (@_);
	
}

################################################################################

sub status {

	my $self = shift;
	
	$self -> {status} = $_[0] if $_[0];
	
	return $self -> {status};
	
}

################################################################################

sub header_out {

	my $self = shift;	
	
	return $self -> {headers} -> header (@_);
	
}

################################################################################

sub send_http_header {
	
	my $self = shift;
		
	$self -> {_headers} -> {status} = $self -> {status} . ' ' . status_message ($self -> {status});

	while (my ($name, $value) = each %{$self -> {_headers}}) {
	
		$self -> {headers} -> header ($name, $value);
	
	}

	my $h = "HTTP/1.1 $self->{_headers}->{status} \015\012" . $self -> {headers} -> as_string;
	
	$h =~ s{[\015\012]+}{\015\012}gsm;
	
	print "$h\015\012";
	
}

################################################################################
# Copyright 1995-1998 Lincoln D. Stein.  All rights reserved.
# It may be used and modified freely, but I do request that this copyright
# notice remain attached to the file.  You may modify this module as you 
# wish, but if you redistribute a modified version, please attach a note
# listing the modifications you have made.

# The most recent version and complete docs are available at:
#   http://stein.cshl.org/WWW/software/CGI/

#$CGI::revision = '$Id: CGI.pm,v 1.234 2007/04/16 16:58:46 lstein Exp $';
#$CGI::VERSION='3.29';

sub to_filehandle {
    my $thingy = shift;
    return undef unless $thingy;
    return $thingy if UNIVERSAL::isa($thingy,'GLOB');
    return $thingy if UNIVERSAL::isa($thingy,'FileHandle');
    if (!ref($thingy)) {
	my $caller = 1;
	while (my $package = caller($caller++)) {
	    my($tmp) = $thingy=~/[\':]/ ? $thingy : "$package\:\:$thingy"; 
	    return $tmp if defined(fileno($tmp));
	}
    }
    return undef;
}

################################################################################

sub send_fd {

	my $self = shift;
	
	my $q = $self -> {Q};

	my $fh = to_filehandle ($_ [0]);
	
	binmode($fh);

	my $buf;

	while (read ($fh, $buff, 8 * 2**10)) {
		print STDOUT $buff;
	}
	
}

################################################################################

sub filename {

	my $self = shift;
	
	return $self -> {Filename};
	
}

################################################################################

sub connection {

	my $self = shift;
	
	return $self;
	
}

################################################################################

sub remote_ip {

	return $ENV {REMOTE_ADDR};
	
}

################################################################################

sub document_root {

	my $path = $ENV {DOCUMENT_ROOT};
	
	$path =~ y{\\}{/}; 
	
	return $path;
	
}

################################################################################

sub request_time { 
	
	shift; return time 
	
}
################################################################################

sub parms {

	my $self = shift;
	
	my %vars = ();
	
	my @names = $self -> {Q} -> param;
	
	foreach my $name (@names) {
		my @v = $self -> {Q} -> param ($name);
		$vars {$name}        = $v [-1];
#		$vars {$name . '[]'} = \@v;
	}
	
	return \%vars;	
	
}

################################################################################

sub param {

	my $self = shift;
	
	return $self -> {Q} -> param ($_ [0]);
	
}

################################################################################

sub upload {

	my ($self, $name) = @_;

	(my $h = ($self -> {upload_cache} ||= {}))
		
		-> {$name} ||= 
	
			Eludia::ApacheLikeRequest::Upload 
			
				-> new ($self -> {Q}, $name);
			
	seek ($h -> {$name} -> {FH}, 0, 0);

	return $h -> {$name};
	
}

################################################################################

sub uri {

	my $self = shift;

	return $ENV {'PATH_INFO'} . '/';

}

################################################################################

sub header_only {

	my $self = shift;
	
	return $self -> {Q} -> request_method () eq 'HEAD';
	
}

################################################################################

sub print { shift; print @_};


################################################################################

sub new {

	my $proto = shift;
	
	my $class = ref ($proto) || $proto;

	my $self  = {};

	CGI::Simple::_initialize_globals ();
	
	$CGI::Simple::USE_PARAM_SEMICOLONS = 0;
	$CGI::Simple::DISABLE_UPLOADS = 0;
	$CGI::Simple::POST_MAX = -1;

	if (@_) {	# HTTP::Server: no STDIN, but connection is available
	
		$self -> {connection} = shift;
		$self -> {request}    = shift;
		
		$self -> {request} -> headers -> scan (sub {$self -> {headers_in} -> {$_[0]} = $_[1]});

		if ($self -> {request} -> method eq 'POST') {

			my $fn = tmpnam ();
			open (T, ">$fn");
			binmode T;

			my $content = $self -> {request} -> content;
			print T $content;
			close (T);

			open (STDIN, "$fn");
			$self -> {Q} = new CGI::Simple ();
			$self -> {Q} -> parse_query_string ();
			open (STDIN, $^X);
			unlink $fn;

		}
		else {
			$self -> {Q} = new CGI::Simple ($ENV {QUERY_STRING});
		}

	}
	else {								# conventional CGI STDIN/STDOUT environment
	
		$self -> {Q} = new CGI::Simple;
		$self -> {Q} -> parse_query_string ();
		
		$ENV {HTTP_COOKIE}  =~ /\w/;				# PerlEx specific
		$ENV {HTTP_ACCEPT_ENCODING} =~ /\w/;			# PerlEx specific

		foreach ($self -> {Q} -> http) {

			my $key = $_;

			s/^HTTP_//;
			$_ = join '-', map {ucfirst ("\L$_")} split /_/;
			$self -> {headers_in} -> {$_} = $ENV {$key};

		}
	
	}
		
	$self -> {Filename} = $ENV {PATH_INFO};
	$self -> {Filename} = '/' if $self -> {Filename} =~ /index\./;
	
	$self -> {status} = 200;
	
	$self -> {headers} = new HTTP::Headers (
		Content_Type => 'text/html',
       	);

	$self -> {_headers} = {};

	bless ($self, $class);
	
	return $self;
	
}

################################################################################

sub the_request {

	my $self = shift;

	return ($self -> {request} ? $self -> {request} -> method : $ENV{REQUEST_METHOD}) . ' ' . $self -> {Q} -> url (-query => 1);

}

################################################################################

sub headers_in {

	my $self = shift;
	
	return $self -> {headers_in};

}

################################################################################

sub headers_out {

	my $self = shift;

	return $self -> {_headers};
	
}

################################################################################

sub internal_redirect {

	my ($self, $url) = @_;	
 
	unless ($url =~ /^http:\/\//) {
		$url =~ s{^/}{};
		$url = "http://$ENV{HTTP_HOST}/$url";
	}
	
	if ($self -> {connection}) {

		$self -> {connection} -> send_redirect ($url);

	}
	else {

		print $q -> redirect (-uri => $url);

	}

}

################################################################################

sub get_handlers {}
	
################################################################################
################################################################################

package Eludia::ApacheLikeRequest::Upload;

################################################################################

sub new {

	my $proto = shift;
	my $class = ref ($proto) || $proto;

	my $self  = {};
	$self -> {Q} = $_ [0];
	$self -> {Param} = $_ [1];
	$self -> {FH} = $self -> {Q} -> upload ($self -> {Param});
	$self -> {FN} = $self -> {Q} -> param ($self -> {Param});
	
	return bless ($self, $class) unless ($self -> {FH} && $self -> {FN});
	
	eval { $self -> {Type} = $self -> {Q} -> uploadInfo ($self -> {FN}) -> {'Content-Type'}; };
	
	return bless ($self, $class) if $@;
	
	my $current_position = tell ($self -> {FH});
	seek ($self -> {FH},0,2);
	$self -> {Size} = tell ($self -> {FH});
	seek ($self -> {FH}, $current_position, 0);

	bless ($self, $class);

	return $self;
}

################################################################################

sub size {
	my $self = shift;
	return $self -> {Size};
}

################################################################################

sub fh {
	my $self = shift;
	return $self -> {FH};
}

################################################################################

sub filename {
	my $self = shift;
	return $self -> {FN};
}

################################################################################

sub type {
	my $self = shift;
	return $self -> {Type};
}

1;