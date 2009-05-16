no warnings;

################################################################################

sub offline_script_log_signature () {

	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime (time);

	$year += 1900;

	$mon ++; 

	return sprintf "[%04d-%02d-%02d %02d:%02d:%02d $$ $0] ", $year, $mon, $mday, $hour, $min, $sec;

}

################################################################################

sub lock_file_name () {

	my $fn = File::Spec -> rel2abs ($0);

	$fn = readlink $fn while -l $fn;

	$fn =~ y{\\/.}{___};
	
	return "/var/run/$fn.lock";

}

################################################################################

sub initialize_offline_script_execution () {

	warn offline_script_log_signature . " starting...\n";

	eval 'require LockFile::Simple';
	
	if ($LockFile::Simple::VERSION) {

		our $LOCK_MANAGER = LockFile::Simple -> make (
		
			-autoclean => 1,
			
			-stale => 1,
			
		);
		
		my $fn = lock_file_name;

		unless ($LOCK_MANAGER -> trylock ($fn)) {
		
			warn offline_script_log_signature . "Can't acquire a lock $fn. Quit.\n";

			exit;

		}

	}

}

################################################################################

sub finalize_offline_script_execution () {

	if ($LOCK_MANAGER) {
	
		$LOCK_MANAGER -> unlock (lock_file_name);
	
	}

	warn offline_script_log_signature . " finished.\n";

}

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
	
	initialize_offline_script_execution;	
	
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
	
	finalize_offline_script_execution;
	
	exit;

}

1;
