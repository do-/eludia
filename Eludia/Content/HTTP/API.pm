################################################################################

sub check_configuration_and_handle_request_for_application {

	my ($app) = @_;
	
	unless ($configs -> {$app}) {
	
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
	
	foreach my $k (keys %{$configs -> {$app} -> {env}}) {
	
		$ENV {$k} = $configs -> {$app} -> {env} -> {$k};
	
	}	

	eval "$configs->{$app}->{handler}::handler ()";
	
	if ($@) {
	
		warn $@ if $@;

		print "Status: 500 Internal Auth Error\r\n";
		print "Content-type: text/html\r\n\r\n";
		print "<pre>$@</pre>";
		
	}		

}

1;