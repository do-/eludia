################################################################################

sub check_configuration_for_application {

	my ($app) = @_;
	
	return if $configs -> {$app};
	
	my $httpd_conf = $app . "/conf/httpd.conf";

	my $cnf_src = '';
	
	open C, $httpd_conf or die "Can't read $httpd_conf: $!\n";
	
	while (my $s = <C>) {
	
		next if $s =~ /\s*\#/;
	
		$cnf_src .= $s;
		
		if ($s =~ /PerlHandler\s+(\w+)/) {
		
			$configs -> {$app} -> {handler} = $1;
		
		}

		if ($s =~ /SetEnv\s+(\w+)\s+(.*)/) {
		
			my ($k, $v) = ($1, $2);
			
			$v =~ s{$\s*\"?}{};
			$v =~ s{\"?\s*$}{};
		
			$configs -> {$app} -> {env} -> {$k} = $v;
		
		}	
		
	}
	
	close C;
	
	$cnf_src =~ m{\<perl\>(.*)\</perl\>}ism;
	
	delete $INC {'Eludia.pm'};
			
	eval $1;
	
	die "Application initialization error: $@" if $@;
	
}

################################################################################

sub handle_request_for_application {

	my ($app) = @_;
	
	my $config = $configs -> {$app} or die "Configuration is not defined for '$app'\n";
	
	foreach my $k (keys %{$config -> {env}}) {
	
		$ENV {$k} = $config -> {env} -> {$k};
	
	}
	
	my $handler = $config -> {handler};

	*$handler {CODE} or $handler = ($config -> {handler} .= '::handler');

	*$handler {CODE} or die "handler '$handler' not defined for '$app'\n";

	eval { &$handler () }; $@ or return;

	warn $@; print "Status: 500 Internal Error\r\nContent-type: text/html\r\n\r\n<pre>$@</pre>";

}

################################################################################

sub check_configuration_and_handle_request_for_application {

	my ($app) = @_;
	
	check_configuration_for_application ($app);
	
	handle_request_for_application ($app);

}

1;