no warnings;

push @{$preconf -> {_} -> {pre_auth}}, sub {

	my $proto = $ENV {SERVER_PORT} == 443 ? 'https' : 'http';

	$_REQUEST {sid} or $_REQUEST {login} or redirect ($preconf -> {ldap} -> {tinysso} . '?goto=' . uri_escape ("${proto}://$ENV{HTTP_HOST}$ENV{REQUEST_URI}"));
		
};

1;