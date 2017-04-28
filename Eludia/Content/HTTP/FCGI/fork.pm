use FCGI;
use IO;
use POSIX ":sys_wait_h", 'setsid';
use Carp;

$SIG {__DIE__} = \&Carp::confess;

################################################################################

sub o ($) {
	my %o = options_unix ();
	print $o {$_[0]}
}

################################################################################

sub options_unix {

	do 'Eludia/Conf.pm';

	my %options = %{$preconf -> {fcgi}};

	$options {address}      ||= $options {port} ? ":$options{port}" : '/tmp/elud';
	$options {pidfile}      ||= '/var/run/elud.pid';
	$options {backlog}      ||= 1024;
	$options {processes}    ||= 20;
	$options {timeout}      ||= 1;
	$options {kill_timeout} ||= 1;
	$options {signal}       ||= 15;

	return %options;

}

################################################################################

sub pid_unix {

	my %options = options_unix ();

	open (PIDFILE, "$options{pidfile}") or return undef;

	my $pid = <PIDFILE>;

	close (PIDFILE);

	if (!kill (0, $pid)) {

		print STDERR "Process $pid is already dead, but pidfile is still remaining...\n";

		unlink $options {pidfile};
		
		print STDERR -f $options {pidfile} ? "Can't remove stale pidfile $options{pidfile}.\n" : "Stale pidfile $options{pidfile} removed.\n";

		return undef;

	}

	return $pid;

}

################################################################################

sub stop {

	my %options = options_unix ();

	$options {pid_to_stop} = pid_unix (%options);

	if (!$options {pid_to_stop}) {

		print STDERR "Can't open $options{pidfile}.\n";

		return;
		
	}
	
	keep_trying_to_stop (%options);

}

################################################################################

sub keep_trying_to_stop {

	my %options = @_;
	
	while (1) {
	
		print STDERR "Sending signal $options{signal} to process $options{pid_to_stop}...\n";

		kill ($options {signal}, $options {pid_to_stop});
		
		sleep ($options {kill_timeout});
		
		next if kill (0, $options {pid_to_stop});
		
		print STDERR "OK, it is down.\n";
		
		last;

	}	

}

################################################################################

sub REAPER {

	my $child;

	while (($child = waitpid (-1,WNOHANG)) > 0) {}
	
	$SIG {CHLD} = \&REAPER;
	
	alarm 0;

}

$SIG {CHLD} = \&REAPER;

################################################################################

sub start {
	
	require Eludia::Loader;

	my %options = options_unix ();	
	
	$0 = $options {name} if $options {name};
	
	$options {pid_to_stop} = pid_unix (%options);

	Eludia::Loader -> import ();	
	APP::sql_reconnect  ();
	APP::require_model  ();		

	open (PIDFILE, ">$options{pidfile}") or die "Can't write to $options{pidfile}: $!\n";
	
	chdir '/' or die "Can't chdir to /: $!";
		
	open STDIN, '/dev/null' or die "Can't read /dev/null: $!";
		
	open STDOUT, '>/dev/null' or die "Can't write to /dev/null: $!";
		
	defined (my $pid = fork) or die "Can't fork: $!";
		
	exit if $pid;
		
	die "Can't start a new session: $!" if setsid == -1;
			
	print PIDFILE $$;
	close (PIDFILE);

	my %pids = ();

	$SIG {'HUP'} = 'INGNORE';
	
	$SIG {'TERM'} = sub { 
		
		kill (15, keys %pids);

		while (1) { waitpid (-1, WNOHANG) > 0 or last }
				
		pid_unix (%options) == $$ and unlink $options {pidfile};
		
		exit;
		
	};

	my $socket = FCGI::OpenSocket ($options {address}, $options {backlog});
	
	$options {address} =~ /^\:/ or chmod 0777, $options {address};

	for (; 1; sleep) {
	
		foreach (keys %pids) {
		
			kill (0, $_) or delete $pids {$_};
		
		}
	
		for (1 .. $options {processes} - keys %pids) {
		
			if (my $pid = fork ()) {
			
				$pids {$pid} = 1;
				
				next;
			
			}
			
			$SIG {'TERM'} = 'DEFAULT';

			my $request = FCGI::Request (\*STDIN, \*STDOUT, new IO::File, \%ENV, $socket);

			while ($request -> Accept >= 0) {

				eval {APP::handler ()};

				warn $@ if $@;

			}
		
		}
		
		if ($options {pid_to_stop}) {
			
			my %o = %options;
		
			delete $options {pid_to_stop};
			
			unless (fork ()) {

				keep_trying_to_stop (%o);
				
				exit;

			}
		
		}

	}

}

1;