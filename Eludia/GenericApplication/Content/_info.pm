################################################################################

sub select__info {

	my $os_name = $^O;
	my $os_version;

	if ($^O eq 'MSWin32') {		
	
		eval {
		
			require Win32;
			
			my ($string, $major, $minor, $build, $id) = Win32::GetOSVersion ();
			
			$os_name    = 'MS Windows';
			
			$os_version = {
			
				140  => '95',
				1410 => '98',
				1490 => 'Me',
				2351 => 'NT 3.51',
				240  => 'NT 4.0',
				250  => '2000',
				251  => 'XP',
				252  => '2003',
				260  => 'Vista',
				
			} -> {$id . $major . $minor} . " Build $build";
			
		};	
		
	} 
	else {
	
		eval {

			require POSIX;

			($os_name, my $nodename, $os_version, my $version, my $machine) = POSIX::uname ();

		};	
		
	}
	
	setup_skin ();
	
	my $data = {rows => [
	
		{
			id    => 'OS',
			label => $os_name,
			version => $os_version,
		},

		{
			
			id    => 'WEB server',
			label => $ENV {SERVER_SOFTWARE},
			path  => $^X,
		
		},	

		{
			id    => 'Interpreter',
			label => (sprintf "Perl %vd", $^V),
		},
	
		{
			id      => 'DBMS',
			label   => $SQL_VERSION -> {string},
			version => $SQL_VERSION -> {number},
			path    => $SQL_VERSION -> {path},
		},

		{
			id    => 'DB interface',
			label => 'DBI ' . $DBI::VERSION,
		},

		{
			id    => 'DB driver',
			label => 'DBD::' . $db -> {Driver} -> {Name} . ' ' . ${'DBD::' . $db -> {Driver} -> {Name} . '::VERSION'},
		},
		
		{			
			id    => 'Parameters module',
			label => ref $apr,
			version => ${(ref $apr) . '::VERSION'},
		},
		
		{			
			id    => 'Engine',
			label => "Eludia",
			path  => $preconf -> {core_path},
			version => $Eludia::VERSION,
		},

		{
			id    => 'JSON module',
			label => ref $_JSON,
			version => ${(ref $_JSON) . '::VERSION'},
		},

		{			
			id    => 'Application package',
			label => ($_PACKAGE =~ /(\w+)/),
			path  => join ', ', @$PACKAGE_ROOT,
		},

		{
			id    => 'Skin',
			path  => $INC {$_SKIN},
			label => $_SKIN
		},

	]};
	
	foreach my $i (@{$data -> {rows}}) {
	
		unless ($i -> {path}) {
		
			my ($key) = split / /, $i -> {label};
			
			$key =~ s{\:\:}{\/}g;
			
			$i -> {path} = $INC {$key . '.pm'};
		
		}
		
		if ($i -> {version}) {
		
			$i -> {product} = $i -> {label};
		
		}
		else {
	
			($i -> {product}, $i -> {version}) = split m{[ /]}, $i -> {label};
	
		}
		
		$i -> {product} =~ s{^Eludia::Presentation::Skins::}{};
						
	}

	return $data;
		

}

1;
