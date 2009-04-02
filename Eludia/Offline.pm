no warnings;

################################################################################

sub config_file () {

	use File::Spec;

	my $fn = File::Spec -> rel2abs ($0);
	
	$fn = readlink $fn while -l $fn;
	
	$fn =~ y{\\}{/};
	
	$fn =~ s{/lib/.*}{/conf/httpd.conf};
	
	return $fn;
	
}

################################################################################

sub perl_section_from ($) {

	my ($fn) = @_;

	my $code = '';
	my $flag = 0;

	open (CONF, $fn) or die ("Can't open $fn:$!\n");

	while (<CONF>) {
	
		if (/<[Pp]erl\s*>/)      { $flag = 1   }

		elsif (/<\/[Pp]erl\s*>/) { $flag = 0   }

		elsif ($flag)            { $code .= $_ }
	
	}

	close (CONF);
	
	return $code;

}

################################################################################

sub the_rest_of_the_script () {

	my @code = ();

	my $flag = 0;
	
	open (SCRIPT, $0);
	
	while (<SCRIPT>) {
	
		if    (/use\s+Eludia::Offline/) { $flag = 1 }

		else                            { $code [$flag] .= $_ }
	
	}
	
	close (SCRIPT);

	return $code [1] || $code [0];	

}

################################################################################

BEGIN {

	$| = 1;
	
	eval perl_section_from config_file;		
	
	my $package = __PACKAGE__;
	
	$package = $Eludia::last_loaded_package if $package eq 'main';
		
	my $code = qq {
	
		package $package;

		\$_REQUEST {__skin} = 'STDERR';

		sql_reconnect ();
		
		require_model ();
		
		no warnings;
	
	} . the_rest_of_the_script;
	
	eval $code; die $@ if $@;
	
	exit;

}

1;