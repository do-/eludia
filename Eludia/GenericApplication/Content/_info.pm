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

	my $git_path;
	if ($^O eq 'MSWin32') {
		if (-e 'C:\Program Files (x86)\Git\bin\git.exe') {
			$git_path = '"C:\Program Files (x86)\Git\bin\git.exe"';
		} else {
			$git_path = '"C:\Program Files\Git\bin\git.exe"';
		}
	} else {
		$git_path = `which git`;
		chomp $git_path;
	}

	my $application_package = "";

	foreach my $library_path (@{Storable::dclone($PACKAGE_ROOT)}) {

		$application_package .= "$library_path";

		$library_path =~ s/\/GenericApplication//;

		if ( (-x "$git_path" || $^O eq 'MSWin32') && -d "$library_path/../.git" ) {

			my $branch = `$git_path --git-dir=$library_path/../.git rev-parse --abbrev-ref HEAD`;
			chomp $branch;

			my $last_commit = `$git_path --git-dir=$library_path/../.git log -1`;
			$last_commit =~ /\nDate:\s+([^\n]+)/gsm;
			$dt_last_commit = $1;

			$application_package .= " ($branch, $dt_last_commit)";

		}

		$application_package .= "<br>";

	}

	my $data = {rows => [

		{
			id      => 'OS',
			label   => $os_name,
			version => $os_version,
		},

		{

			id      => 'WEB server',
			label   => $ENV {SERVER_SOFTWARE},

		},

		{
			id      => 'Interpreter',
			label   => (sprintf "Perl %vd", $^V),
		},

		{
			id      => 'DBMS',
			label   => $SQL_VERSION -> {string},
			version => $SQL_VERSION -> {number},
			path    => $SQL_VERSION -> {path},
		},

		{
			id      => 'DB interface',
			label   => 'DBI ' . $DBI::VERSION,
		},

		{
			id      => 'DB driver',
			label   => 'DBD::' . $db -> {Driver} -> {Name} . ' ' . ${'DBD::' . $db -> {Driver} -> {Name} . '::VERSION'},
		},

		{
			id      => 'Parameters module',
			label   => ref $apr,
			version => ${(ref $apr) . '::VERSION'},
		},

		{
			id      => 'Engine',
			label   => "Eludia",
			path    => $preconf -> {core_path},
			version => $Eludia::VERSION,
		},

		{
			id      => 'JSON module',
			label   => ref $_JSON,
			version => ${(ref $_JSON) . '::VERSION'},
		},

		{
			id      => 'Application package',
			label   => ($_PACKAGE =~ /(\w+)/),
			path    => $application_package,
		},

		{
			id      => 'Skin',
			path    => $INC {$_SKIN},
			label   => $_SKIN
		},

	]};

	my $exe = $^X;

	$data -> {rows} -> [$exe =~ /perl(\.\w+)?/ ? 2 : 1] -> {path} = $exe;

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
