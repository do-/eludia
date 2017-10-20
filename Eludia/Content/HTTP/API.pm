use Encode;

################################################################################

sub check_configuration_for_application {

	my ($app) = @_;

	return if $main::configs -> {$app};

	my $httpd_conf = $app . "/conf/httpd.conf";

	my $is_utf;

	if (open (CONF, $app . "/lib/Config.pm")) {
		$is_utf = (join '', (<CONF>)) =~ /^\s*lang\s*=>.*UTF8/m;
		close (CONF);
	}

	my $cnf_src = '';

	open C, $httpd_conf or die "Can't read $httpd_conf: $!\n";

	my $last_location = '';

	my $package;

	while (my $s = <C>) {

		next if $s =~ /^\s*\#/;

		$cnf_src .= $s;

		if ($s =~ /Location\s+(.*)\>/) {

			$last_location = $1;

			$last_location =~ s{^[\"\']}{};
			$last_location =~ s{[\"\']\s*&}{};

		}

		if ($s =~ /PerlHandler\s+((\w+(\:\:\w+)*?)(\:\:\w+)?)\r?$/) {

			$package = $2;
			my $handler = $1;
			$handler    =~ /\:\:/ or $handler .= '::handler';

			$main::configs -> {$app} -> {handler_src}  .= "\n \$ENV{SCRIPT_NAME} =~ m{^$last_location} ? $handler (\@_) : ";

		}

		if ($s =~ /SetEnv\s+(\w+)\s+(.*)/ || $s =~ /\$ENV\s*{(\w+)}\s*=\s*\"(.*)\"/) {

			my ($k, $v) = ($1, $2);

			$v =~ s{^\s*\"?}{};
			$v =~ s{\"?\s*$}{};

			$main::configs -> {$app} -> {env} -> {$k} = $v;

		}

	}

	foreach my $app (keys %$main::configs) {

		my $src = "\$main::configs -> {'$app'} -> {handler} = sub {$main::configs->{$app}->{handler_src} 0}";

		eval $src;

	}

	close C;

	$cnf_src =~ m{\<[Pp]erl\s*\>(.*)\</[Pp]erl\s*\>}ism;

	delete $INC {'Eludia.pm'};

	$is_utf ? eval "use utf8; " . Encode::decode('windows-1251', $1) : eval $1;

	die "Application initialization error: $@" if $@;

	&{"${package}::sql_reconnect"} ();

	return $package;

}

################################################################################

sub handle_request_for_application {

	my ($app) = @_;

	my $config = $main::configs -> {$app} or die "Configuration is not defined for '$app'\n";

	foreach my $k (keys %{$config -> {env}}) {

		$ENV {$k} = $config -> {env} -> {$k};

	}

	my $handler = $config -> {handler};

	ref $handler eq CODE or die "handler '$handler' not defined for '$app' ($ENV{SCRIPT_NAME})\n";

	eval { my $result = &$handler (); }; $@ or return;

	warn $@; print "Status: 500 Internal Error\r\nContent-type: text/html\r\n\r\n<pre>$@</pre>";

	return $@;

}

################################################################################

sub check_configuration_and_handle_request_for_application {

	my ($app) = @_;

	check_configuration_for_application ($app);

	handle_request_for_application ($app);

}

1;