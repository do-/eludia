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

	$fn =~ y{\\/.\: }{___};
	
	return $^O eq 'MSWin32' ? "C:/$fn.lock" : "/var/run/$fn.lock";

}

################################################################################

sub initialize_offline_script_execution () {

	$ENV {ELUDIA_SILENT} or warn "\n" . offline_script_log_signature . " starting...\n";

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

	$ENV {ELUDIA_SILENT} or warn offline_script_log_signature . " finished.\n";

}

################################################################################

BEGIN {

	$| = 1;
	
	initialize_offline_script_execution;
	
	require Eludia::Loader;	
	Eludia::Loader -> import ();
	
	package APP;
		
	sql_reconnect ();
	require_model ();	

	do $0;
	
	my $err = $@ || $!; die "${err}\n" if $err;
	
	finalize_offline_script_execution;
	
	exit;

}

1;