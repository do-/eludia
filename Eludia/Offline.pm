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

BEGIN {

	$| = 1;
	
	my $package = __PACKAGE__;

	my $code = (perl_section_from config_file) . qq {
	
		package $package;

		\$_REQUEST {__skin} = 'STDERR';

		sql_reconnect ();

	};
	
	eval $code;
	
	die $@ if $@;

}

################################################################################

END {
	sql_disconnect ();
}

1;