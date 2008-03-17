use LWP::UserAgent;
use HTTP::Request::Common;

################################################################################

sub peer_get {

	$_[1] -> {xls} = 0;

	my $item = peer_query (@_);
	
	$_REQUEST {__read_only} = $item -> {__read_only};
		
	return $item;

}

################################################################################

sub peer_execute {

	my $data = peer_query (@_);

	return $_REQUEST {error} if $_REQUEST {error};
	
	redirect ({action => '', id => $data -> {id}}, {kind => 'js'});
	
	return undef;

}

################################################################################

sub peer_name {

	$preconf -> {peer_name} or die "Peer name not defined\n";

	return $preconf -> {peer_name};

}

################################################################################

sub peer_reconnect {

	unless ($UA) {
	
		our $UA = LWP::UserAgent -> new (
			agent                 => "Eludia/$Eludia_VERSION (" . peer_name () . ")",
			requests_redirectable => ['GET', 'HEAD', 'POST'],
		);
		
#		$HTTP::Request::Common::DYNAMIC_FILE_UPLOAD = 1;
		
	}
		
}

################################################################################

sub peer_proxy {

	my ($peer_server, $params) = @_;
	
	my $url = $preconf -> {peer_servers} -> {$peer_server} or die "Peer server '$peer_server' not defined\n";
	
	$_REQUEST {__peer_server} = $peer_server;
	
	peer_reconnect ();
		
	$url .= '?sid=';
	$url .= $_REQUEST {sid};
	
	my @keys = keys %$params;

	foreach my $k (@keys) {
		$url .= '&';
		$url .= $k;
		$url .= '=';
		$url .= uri_escape ($params -> {$k});
	}		
		
	my $request = HTTP::Request -> new ('GET', $url);
	
	my $virgin = 1;
		
	my $response = $UA -> request ($request,
				
		sub { 
			
			if ($virgin) {
				$r -> print ($r -> protocol);
				$r -> print (" 200OK\015\012");
				$r -> print ($_[1] -> headers_as_string);
				$r -> print ("\015\012");
				$virgin = 0;
			}
		
			$r -> print ($_[0]);
		},
		
	);
		
	$_REQUEST {__response_sent} = 1;

}

################################################################################

sub peer_query {

	my ($peer_server, $params, $options) = @_;
	
	my $url = $preconf -> {peer_servers} -> {$peer_server} or die "Peer server '$peer_server' not defined\n";
	
	peer_reconnect ();
	
	foreach my $k (keys %_REQUEST) {
		next if $k =~ /^__/ && $k ne '__edit';
		next if exists $params -> {$k};
		$params -> {$k} = ref $_REQUEST {$k} eq 'Math::FixedPrecision' ? $_REQUEST {$k} -> bstr () : $_REQUEST {$k};
	}
	
	$params -> {__d} = 1;
	delete $params -> {select};
	delete $params -> {xls};
	
	my @headers = (Accept_Encoding => 'gzip');

	$options -> {files} = [$options -> {file}] if $options -> {file};
	if (ref $options -> {files} eq ARRAY) {
		
		foreach my $name (@{$options -> {files}}) {
			my $file = upload_file ({ name => $name, dir => 'upload/images'});
			$params -> {'_' . $name} = [$file -> {real_path}, $params -> {'_' . $name}];
		}
		
		push @headers, (Content_Type => 'form-data');
		
	}
	
	my @args = ($url,
		@headers,
		Content         => [ %$params ],
	);	

	my $request = POST (@args);
			
	my $response = $UA -> request ($request);

	foreach my $k (keys %$params) {
		my $v = $params -> {$k};
		ref $v eq ARRAY or next;
		unlink $v -> [0];
	}		
	
	while (1) {
		
		$response -> is_success or die ("Invalid response from $peer_server: " . $response -> status_line . "\n");
		
		my $dump = $response -> content;
	
		if ($response -> headers -> header ('Content-Encoding') eq 'gzip') {
			$dump = Compress::Zlib::memGunzip ($dump);
		}
		
		eval $dump;
		
		my ($root, $data) = (%$VAR1);
		
		undef $VAR1;
			
		$_REQUEST {__peer_server} = $peer_server;
					
		if ($root eq 'data') {			
			return $data;
		}
		
		if ($root eq 'redirect') {
		
			$response = $UA -> request (GET $url . $data -> {url} . '&__d=1',
				Accept_Encoding => 'gzip',
			);
		
		}
		elsif ($root eq 'error') {
					
			$_REQUEST {error} = $data -> {message};
			$_REQUEST {error} = '#' . $data -> {field} . '#:' . $_REQUEST {error} if $data -> {field};
			
			return $_REQUEST {error};
			
		}
		else {
			die ("Invalid response from $peer_server: '$dump'\n");
		}
			
	}

}

1;