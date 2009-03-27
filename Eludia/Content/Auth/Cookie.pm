no warnings;

push @{$preconf -> {_} -> {pre_auth}}, sub {

	my $c = $_COOKIES {sid} or return;

	$_REQUEST {sid} ||= $c -> value;

};

push @{$preconf -> {_} -> {post_auth}}, sub {

	$_REQUEST {sid} or return;

	set_cookie_for_root (sid =>  $_REQUEST {sid} || 0);

};

1;