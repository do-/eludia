BEGIN {

	use File::Spec;
#	use DBIx::ModelUpdate;

	$| = 1;

	no warnings;

	my $fn = File::Spec -> rel2abs ($0);

	$fn = readlink $fn while -l $fn;
	$fn =~ s{/lib/.*}{};
	$fn =~ s{\\lib\\.*}{};
	
	my $package = -e $fn . '/lib/' . __PACKAGE__ ? __PACKAGE__ : '';

	$PACKAGE_ROOT = [$fn . '/lib/' . $package . '/'];
	
	my $config_path = $fn . '/lib/' . $package . '/Config.pm';
	
	
	push @INC, $PACKAGE_ROOT;
	
	$fn .= '/conf/httpd.conf';

	open (CONF, $fn) or die ("Can't open $fn:$!\n");
	my $conf = join '', (<CONF>);
	close (CONF);

	$conf =~ s{.*<[Pp]erl\s*>}{}gsm;
	$conf =~ s{</[Pp]erl\s*>.*}{}gsm;
	
	eval "\$^W = 0; $conf";
	
	die $@ if $@;
	
	require Eludia;
	
	sql_reconnect ();
	
	do $config_path;

	$package = __PACKAGE__;
	eval "\$conf = \$${package}::conf";

  $conf -> {systables} ||= {
      _db_model_checksums     => '_db_model_checksums',
      __voc_replacements      => '__voc_replacements',
      __access_log            => '__access_log',
      __benchmarks            => '__benchmarks',
      __last_update           => '__last_update',
      __moved_links           => '__moved_links',
      __required_files        => '__required_files',
      __screenshots           => '__screenshots',
      __queries               => '__queries',
      cache_html              => 'cache_html',
      log                     => 'log',
      roles                   => 'roles',
      sessions                => 'sessions',
      users                   => 'users',
  };

	our $number_format = Number::Format -> new (%{$conf -> {number_format}});

	$_REQUEST {__skin} ||= 'STDERR';
	
	setup_skin ();

}

END {

	sql_disconnect ();

}

1;
