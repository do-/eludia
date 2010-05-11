no warnings;

require LWP::UserAgent;
use Encode;
use Encode::Byte;
use Net::LDAP;

push @{$preconf -> {_} -> {pre_auth}}, sub {

	return if $_REQUEST {sid};
	
	my $ua = LWP::UserAgent -> new;
	
	unless ($preconf -> {_} -> {opensso_cookie_name}) {
	
		my $response = $ua -> post ($preconf -> {ldap} -> {opensso} . '/identity/getCookieNameForToken');
		
		$response -> is_success or die $response -> message;
		
		my $content = $response -> content;
		
		$content =~ /string=(\w+)/ or die "Incorrect OpenSSO response: '$content'\n";
		
		$preconf -> {_} -> {opensso_cookie_name} = $1;
	
	}

warn Dumper ($preconf -> {_} -> {opensso_cookie_name});
	
	my $token = $_REQUEST {$preconf -> {_} -> {opensso_cookie_name}};

warn Dumper ($token);

	if ($token) {
	
		my $response = $ua -> post ($preconf -> {ldap} -> {opensso} . '/identity/isTokenValid', Cookie => "$preconf->{_}->{opensso_cookie_name}=$token");

		$response -> is_success or die $response -> message;

warn Dumper ($response -> content);

		$response -> content =~ /boolean\=true/ or undef $token;
		
	}

warn Dumper ($token);

	unless ($token) {
	
		$r -> status (302);
		
		my $host = $preconf -> {ldap} -> {opensso};
		
		$host =~ s{^https?://}{};

		$host =~ s{(\:\d+)?(/.*)?$}{};

		my ($head, @tail) = split /\./, $host;

		my $domain = '';
						
		foreach my $part (reverse @tail) {
			
			$domain = '.' . $part . $domain;

			set_cookie (
			
				-name    => $preconf -> {_} -> {opensso_cookie_name},
 				-expires =>  '-1M',
				-value   => '',
				-path    => '/',
				-domain  => $domain,
				
			);
	
			
		}

		$r -> headers_out -> {'Location'}   = $preconf -> {ldap} -> {opensso} . "/UI/Login?goto=" . uri_escape ("http://$ENV{HTTP_HOST}$ENV{REQUEST_URI}");
		
		send_http_header ();
		
		print (' ' x 4096);

		$_REQUEST {__response_sent} = 1;

		return;
	
	}
	
	my $response = $ua -> post ($preconf -> {ldap} -> {opensso} . '/identity/attributes', Cookie => "$preconf->{_}->{opensso_cookie_name}=$token", 'Accept-Charset' => 'utf-8');

	$response -> is_success or die $response -> message;
	
warn Dumper ($response -> content);

	my %h = ();
	
	my $last_name;
	
	foreach (split /[\r\n]+/, $response -> content) {
	
		/^userdetails\.attribute\.(name|value)\=(.*)/ or next;
				
		if ($1 eq 'name') {
		
			$last_name = $2;
		
		}
		else {
		
			$h {$last_name} = $2;
		
		}
	
	}
		
	my $login_field = $preconf -> {ldap} -> {fields} -> {login};
		
	$h {$login_field} or die "Empty login: " . Dumper (\%h);
	
	my $ldap = Net::LDAP -> new ($preconf -> {ldap} -> {host}) or die $@;

	!$preconf -> {ldap} -> {user} ? 
	
		$ldap -> bind () : 
	
		$ldap -> bind ($preconf -> {ldap} -> {user}, password => $preconf -> {ldap} -> {password});
		
	$mesg = $ldap -> search (
	
		base   => $preconf -> {ldap} -> {base},
		
		filter => "(${login_field}=$h{$login_field})",
		
	);
		
	require_content 'logon';
	
	$_REQUEST {type}   = 'logon';
	$_REQUEST {action} = 'execute';
	$_REQUEST {login}  = $h {$login_field};

	eval { validate_execute_logon ()};
	
warn Dumper ($_USER);

	eval {       do_execute_logon ()};
	eval {      recalculate_logon ()};
		
	redirect ({}) if $_COOKIE {redirect_params};

	delete $_REQUEST {$_} foreach qw (login action);

warn Dumper (\%_REQUEST);

};

1;