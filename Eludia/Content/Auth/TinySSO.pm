no warnings;

push @{$preconf -> {_} -> {pre_auth}}, sub {

	$_REQUEST {sid} or $_REQUEST {login} or redirect ($preconf -> {ldap} -> {tinysso} . '?goto=' . uri_escape ("http://$ENV{HTTP_HOST}$ENV{REQUEST_URI}"));
		
};

1;