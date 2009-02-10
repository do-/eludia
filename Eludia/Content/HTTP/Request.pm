package Eludia::Request;

use Data::Dumper;

use Eludia::Content::HTTP::Request::Upload;

################################################################################

sub print {
	shift;
	print @_;
}

################################################################################

sub new {

	my $proto = shift;
	my $class = ref($proto) || $proto;

	my ($preconf, $conf) = @_;

	my $self  = {
		preconf => $preconf,
		conf => $conf,
	};

	undef @CGI::QUERY_PARAM;

	$self -> {Q} = new CGI;

	$self -> {Filename} = $ENV{PATH_INFO};
	$self -> {Filename} = '/' if $self -> {Filename} =~ /index\./;

	$self -> {Document_root} = $ENV{DOCUMENT_ROOT};
	$self -> {Out_headers} = {-type => 'text/html', -status=> 200};

	bless ($self, $class);

	return $self;
	
}

################################################################################

sub request_time {

	return time;

}

################################################################################

sub get_handlers {

	return [];

}

################################################################################

sub internal_redirect {

	my $self = shift;
	my $q = $self -> {Q};

	my $url = $_[0];

	unless ($url =~ /^http:\/\//) {
		$url =~ s{^/}{};
		$url = "http://$ENV{HTTP_HOST}/$url";
	}

#	my $http_host = $ENV {HTTP_X_FORWARDED_HOST} || $self -> {preconf} -> {http_host};
#	if ($http_host) {
#		substr ($url, index ($url, $ENV{HTTP_HOST}), length ($ENV{HTTP_HOST})) = $http_host;
#	}

	print $q -> redirect (-uri => $url);

}

################################################################################

sub args {
	return $ENV {QUERY_STRING};
}

################################################################################

sub header_in {
	my $self = shift;
	my $q = $self -> {Q};
	return $q -> http ($_ [0]);
}

################################################################################

sub headers_in {

	my $self = shift;

	my $q = $self -> {Q};
	my @inheaders = $q -> http ($_ [1]);

	shift(@inheaders);
	foreach $header (@inheaders){
		@arr=();
		$strout="";
		@arr=split(/_/,$header);
		shift(@arr);
		foreach $key ( @arr){
			if (length($key)>0) {
				$str=ucfirst(lc($key));
		    			if (length($strout)>0) {
						$strout=$strout."-";
					}
			$strout=$strout.$str;
			}
		}
		$ret->{$strout}=$ENV{$header};

	}

	return $ret;

}

################################################################################

sub content_type {

	my $self = shift;
	my $q = $self -> {Q};

	if ($_ [0]) {
		$self -> {Out_headers} -> {-type} = $_ [0];
	} else {
		return $self -> {Out_headers} -> {-type};
	}

}

################################################################################

sub content_encoding {

	my $self = shift;
	my $q = $self -> {Q};

	if ($_ [0]) {
		$self -> {Out_headers} -> {-content_encoding} = $_ [0];
	} else {
		return $self -> {Out_headers} -> {-content_encoding};
	}

}

################################################################################

sub status {

	my $self = shift;
	my $q = $self -> {Q};
	if ($_ [0]) {
		$self -> {Out_headers} -> {-status} = $_ [0];
	} else {
		return $self -> {Out_headers} -> {-status};
	}

}

################################################################################

sub header_out {

	my $self = shift;
	my $q = $self -> {Q};

	$self -> {Out_headers} -> {"-$_[0]"} = $_[1];

}

################################################################################

sub headers_out {

	my $self = shift;
	my $q = $self -> {Q};

	return ($self -> {Out_headers} ||= {});

}
################################################################################

sub send_http_header {

	my $self = shift;
	my $q = $self -> {Q};

	my @params = ();

	foreach $header (keys %{$self -> {Out_headers}}) {
		push (@params, $header, $self -> {Out_headers} -> {$header});
	}

	print $q -> header (@params);
}

################################################################################

sub send_fd {

	my $self = shift;
	my $q = $self -> {Q};

	my $fh = CGI::to_filehandle($_ [0]);
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

	my $self = shift;

	return $self -> {Document_root};

}

################################################################################

sub parms {

	my $self = shift;
	my $q = $self -> {Q};
	my $params = $self -> {Q} -> Vars;
	my %vars = ();

	foreach my $k (keys %$params) {
		($vars {$k}) = grep {$_} split ("\0", $params -> {$k});
	}

	return \%vars;

}

################################################################################

sub param {

	my $self = shift;
	my $q = $self -> {Q};

	return $q -> param ($_ [0]);

}

################################################################################

sub upload {

	my $self = shift;
	my $q = $self -> {Q};

	my $param = $_ [0];
	return $self -> {$param} if ($self -> {$param});

	$self -> {$param} = Eludia::Request::Upload -> new($q, $param);

	return $self -> {$param};

}

################################################################################

sub uri {
	my $self = shift;
	my $uri = $self -> {Q} -> url (-path_info => 1);
	$uri =~ s{(http://.*?/.*)/$}{$1};
	return $uri;
}

################################################################################

sub header_only {
	my $self = shift;
	return $self -> {Q} -> request_method () eq 'HEAD';
}

################################################################################

sub the_request {

        my $self = shift;
        my $q = $self -> {Q};
	my @names = $q -> param;
        my %vars = $q -> Vars;
	my $url;

	foreach my $name (@names) {
		my @values = split ("\0", $vars{$name});
		$url .= '&' . (@values > 0 ? join ('&', (map {"$name=$_"} @values)) : "$name=");
	}

	$url =~ s/^\&//;

        return "$ENV{REQUEST_METHOD} $self->{Filename}?$url $ENV{SERVER_PROTOCOL}";

}


################################################################################

package Apache::Constants;

sub OK () {
	return MP2 ? 0 : 200;
}

1;
