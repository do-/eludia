################################################################################

sub select__names_list {

	my %names = map {{$_ => 1}} @{$db -> tables};
	
	my $the_path = $PACKAGE_ROOT -> [0];
		
	opendir (DIR, "$the_path/Content") || die "can't opendir $the_path/Content: $!";
	my @files = readdir (DIR);
	foreach (@files) {
		s{\.pm}{} or next;
		$names {$_} = 1;
	}	
	closedir DIR;	

	opendir (DIR, "$the_path/Presentation") || die "can't opendir $the_path/Presentation: $!";
	my @files = readdir (DIR);
	foreach (@files) {
		s{\.pm}{} or next;
		$names {$_} = 1;
	}	
	closedir DIR;	
	
	sql_select_loop ("SELECT * FROM $conf->{systables}->{roles}", sub {$names {$i -> {name}} = 1});
	
	$r -> status (200);
	$r -> headers_out -> {'Content-Disposition'} = "attachment;filename=$_PACKAGE.txt";
	MP2 ? $r->content_type('text/plain') : $r -> send_http_header ('text/plain');
	
	foreach (sort keys %names) {
		$r -> print ("\r\n");
		$_ or next;
		$r -> print ($_);
	}

	$_REQUEST {__response_sent} = 1;

	return {
		_names_list => [ map {{label => $_}} sort keys %names ],
	};
	
}

1;