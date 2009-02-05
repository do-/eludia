################################################################################

sub select__sync {

	$_REQUEST {last_host } ||= 'http://' . $preconf -> {master_server} -> {host};
	$_REQUEST {last_login} ||= $_USER -> {login};

	my @tables = ();
	
	foreach ($db -> tables) {

		s{.*?(\w+)\W*$}{$1}gsm;
		
		push @tables, {
			id    => $_,
			label => $_,
		},

	}
	
	return {
		
		tables => \@tables,
		table  => [],
		
	};

}

################################################################################

sub do_update__sync {

	$_REQUEST {_host} =~ /^http/ or $_REQUEST {_host} = 'http://' . $_REQUEST {_host};
	
	lrt_start ();
	
	foreach (keys %_REQUEST) {
	
		/^_table_/ or next;
	
		download_table_data ({
			host     => $_REQUEST {_host},
			login    => $_REQUEST {_login},
			password => $_REQUEST {_password},
			table    => $',
		});
	
	}
		
	lrt_finish ('Done.', "/?type=_sync&sid=$_REQUEST{sid}&last_login=$_REQUEST{_login}&last_host=$_REQUEST{_host}");

}

1;