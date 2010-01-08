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
	
	my $token = $_COOKIE {$preconf -> {_} -> {opensso_cookie_name}};

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
		
		$r -> headers_out -> {'Location'} = $preconf -> {ldap} -> {opensso} . "/UI/Login?goto=http://$ENV{HTTP_HOST}/";
		
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
		
	
	foreach my $entry ($mesg -> entries) {

		my $user = {-fake => 0};

		my $f = $preconf -> {ldap} -> {fields};

		foreach my $key (keys %$f) {
		
			my $s = $entry -> get_value ($f -> {$key});

			Encode::from_to ($s, 'utf8', 'windows-1251');
			
			$f -> {$key} eq $login_field or $key = "-$key";

warn Dumper ([$key, $login_field]);

			$user -> {$key} = $s;

		}

		($user -> {-f}, $user -> {-i}, $user -> {-o}) = split /\s+/, $user -> {-label};

		$user -> {-is_female} = $user -> {-o} =~ /à$/ ? 1 : 0;

warn Dumper ($user);

		start_session (sql (users => $user, ['login']));

	}	

	delete $_REQUEST {type};

warn Dumper (\%_REQUEST);

};

1;