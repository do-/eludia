use threads;

use FCGI;
use IO;
use Eludia::Content::HTTP::API;
use POSIX ":sys_wait_h", 'setsid';
use Getopt::Long;
use Data::Dumper;

################################################################################

sub cmd_unix {

	my $signal, $single_task;

	GetOptions (
	    'signal=i' => \$signal,
	    'x'        => \$single_task,
	);

	my $command = $ARGV [0];

	if ($command eq 'start') {

		start (
			-daemonize => 1 - $single_task,
		);

	}
	elsif ($command eq 'stop') {

		stop (
			-signal => $signal,
		);

	}
	else {

		print "Usage: elud {start|stop} [--signal {9|15}]\n";

	}

}

################################################################################

sub options_unix {

	my %options = @_;
	
	$options {-address}      ||= '/tmp/elud';
	$options {-pidfile}      ||= '/var/run/elud.pid';
	$options {-backlog}      ||= 1024;
	$options {-processes}    ||= 2;
	$options {-timeout}      ||= 1;
	$options {-kill_timeout} ||= 1;
	$options {-signal}       ||= 15;
	$options {-error_file}   ||= '/tmp/elud_error';

	return %options;

}

################################################################################

sub stop {

	stop_unix (@_);
	
}

################################################################################

sub pid_unix {

	my %options = options_unix (@_);

	open (PIDFILE, "$options{-pidfile}") or return undef;

	my $pid = <PIDFILE>;
	
	close (PIDFILE);

	if (!kill (0, $pid)) {

		print STDERR "Process $pid is already dead, but pidfile is still remaining...\n";

		unlink $options {-pidfile};
		
		print STDERR -f $options {-pidfile} ? "Can't remove stale pidfile $options{-pidfile}.\n" : "Stale pidfile $options{-pidfile} removed.\n";

		return undef;

	}

	return $pid;

}

################################################################################

sub stop_unix {

	my %options = options_unix (@_);

	$options {-pid_to_stop} = pid_unix (%options);

	if (!$options {-pid_to_stop}) {

		print STDERR "Can't open $options{-pidfile}.\n";

		return;
		
	}
	
	keep_trying_to_stop_unix (%options);

}

################################################################################

sub keep_trying_to_stop_unix {

	my %options = options_unix (@_);
	
	while (1) {
	
		print STDERR "Sending signal $options{-signal} to process $options{-pid_to_stop}...\n";

		kill ($options {-signal}, $options {-pid_to_stop});
		
		sleep ($options {-kill_timeout});
		
		next if kill (0, $options {-pid_to_stop});
		
		print STDERR "OK, it is down.\n";
		
		last;

	}	

}

################################################################################

sub start {

	$^O eq 'MSWin32' ? start_win32 (@_) : start_unix (@_);
	
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

sub find_nginx {

	my $nginx;

	foreach (split /\n/, `ps ax`) {
	
		/^\s*(\d+).*?nginx: master process/ or next;
		
		$nginx -> {pid} = $1;

		$' =~ /-c\s+([\w\/\.]+)/ or last;
		
		$nginx -> {conf} = $1;
		
		last;
	
	}
	
	if (!$nginx -> {conf}) {

		if (`nginx -V 2>&1` =~ /--conf-path=([\w\/\.]+)/) {
		
			$nginx -> {conf} = $1;
		
		}
	
	}
	
	if (!$nginx -> {conf}) {
	
		my $path = '/usr/local/nginx/conf/nginx.conf';
		
		-f $path and $nginx -> {conf} = $path;

	}	
	
	if ($nginx -> {conf}) {
	
		$nginx -> {eludia_fastcgi_pass} = $nginx -> {conf};
		
		$nginx -> {eludia_fastcgi_pass} =~ s{/[\w\.]+$}{};
	
		$nginx -> {eludia_fastcgi_pass} .= '/eludia_fastcgi_pass';
		
		-f $nginx -> {eludia_fastcgi_pass} or delete $nginx -> {eludia_fastcgi_pass};

	}

	return $nginx;

}

################################################################################

sub start_unix {

	print STDERR "Starting elud\n";

	my %options = options_unix (@_);	
	
	$options {-pid_to_stop} = pid_unix (%options);

	my $nginx = find_nginx ();
	
	if ($nginx -> {conf} and open (N, $nginx -> {conf})) {
	
		open STDOUT, '>/dev/null';

		while (<N>) {

			next if /^\s*\#/;
			
			/root\s+/ or next;
			
			my $app = $';
			
			$app =~ s{\s*;\s*$}{};

			$app =~ s{/docroot/?$}{};
			
			-f "$app/conf/httpd.conf" and -f "$app/lib/Config.pm" or next;
			
			next if $main::configs -> {$app};
			
			print STDERR "Loading $app...\n";
	
			check_configuration_for_application ($app);

			print STDERR "Trying $app...\n";
			
			open (E, ">$options{-error_file}") or die "Can't write to $options{-error_file}:$!\n";
			close E;
			unlink $options {-error_file};

			if (my $pid = fork ()) {
			
				waitpid ($pid, 0);
				
				if (-f $options {-error_file}) {
				
					open (E, ">$options{-error_file}");
					
					my $error = join '', (<E>);
					
					close (E);
					
					print STDERR $error;
					
					exit;
				
				}
			
			}
			else {

				$ENV {SCRIPT_NAME} = '/';

				my $error = handle_request_for_application ($app);
				
				if ($error) {
				
					open (E, ">$options{-error_file}");
					
					print E $error;
					
					close (E);
									
				} 
				
				exit;

			}

		}
	
		close (N);
	
	}

	open (PIDFILE, ">$options{-pidfile}") or die "Can't write to $options{-pidfile}: $!\n";

	if ($options {-daemonize}) {
	
		chdir '/' or die "Can't chdir to /: $!";
		
		open STDIN, '/dev/null' or die "Can't read /dev/null: $!";
		
		open STDOUT, '>/dev/null'
		
		or die "Can't write to /dev/null: $!";
		
		defined(my $pid = fork) or die "Can't fork: $!";
		
		exit if $pid;
		
		die "Can't start a new session: $!" if setsid == -1;
		
		open STDERR, '>&STDOUT' or die "Can't dup stdout: $!";

	}	
	
	print PIDFILE $$;
	close (PIDFILE);
	
	if ($options {-address} !~ /^\:/ && $nginx -> {eludia_fastcgi_pass} && open (N, ">$nginx->{eludia_fastcgi_pass}")) {
	
		$nginx -> {reload} = 1;

		$options {-address} .= "_$$";
		
		print N "fastcgi_pass unix:$options{-address};";
		
		close (N);
	
	}
	
	my %pids = ();

	$SIG {'HUP'} = 'INGNORE';
	
	$SIG {'TERM'} = sub { 
		
		kill (15, keys %pids);

		while (1) { waitpid (-1, WNOHANG) > 0 or last }
				
		pid_unix (%options) == $$ and unlink $options {-pidfile};
		
		exit;
		
	};

	my $socket = FCGI::OpenSocket ($options {-address}, $options {-backlog});
	
	$options {-address} =~ /^\:/ or chmod 0777, $options {-address};

	for (; 1; sleep) {
	
		foreach (keys %pids) {
		
			kill (0, $_) or delete $pids {$_};
		
		}
	
		for (1 .. $options {-processes} - keys %pids) {
		
			if (my $pid = fork ()) {
			
				$pids {$pid} = 1;
				
				next;
			
			}
			
			$SIG {'TERM'} = 'DEFAULT';

			my $request = FCGI::Request (\*STDIN, \*STDOUT, new IO::File, \%ENV, $socket);

			while ($request -> Accept >= 0) {

				my $app = $ENV {DOCUMENT_ROOT};

				$app =~ s{/docroot/?$}{};
				
				open (STDERR, ">>$app/logs/error.log");

				check_configuration_and_handle_request_for_application ($app);

			}
		
		}
		
		if ($nginx -> {reload}) {
		
			kill 1, $nginx -> {pid};
		
			delete $nginx -> {reload};
		
		}
		
		if ($options {-pid_to_stop}) {
			
			my %o = %options;
		
			delete $options {-pid_to_stop};
			
			unless (fork ()) {

				keep_trying_to_stop_unix (%o);
				
				exit;

			}
		
		}

	}

}

################################################################################

sub options_win32 {

	my %options = @_;
	
	$options {-address}      ||= ':9000';
	$options {-backlog}      ||= 1024;
	$options {-processes}    ||= 2;
	$options {-timeout}      ||= 1;

	return %options;

}

################################################################################

sub start_win32 {

	my %options = options_win32 (@_);

	require Win32::Pipe;

	$options {-address} =~ /\d+/;

	my $pipe_out = new Win32::Pipe ("\\\\.\\pipe\\winserv.scm.out.Eludia_$&");
	my $pipe_in  = new Win32::Pipe ("\\\\.\\pipe\\winserv.scm.in.Eludia_$&");

	if ($pipe_in) {

		threads -> create (sub {

			$pipe_in -> Read ();

			exit;

		}, @_) -> detach;
	
	}
	
	my $nginx = {conf => 'c:/nginx/conf/nginx.conf'};

	if ($nginx -> {conf} and open (N, $nginx -> {conf})) {

		open STDOUT, '>/dev/null';

		while (<N>) {

			next if /^\s*\#/;
			
			/root\s+/ or next;
			
			my $app = $';
			
			$app =~ s{\s*;\s*$}{};
			
			if ($app =~ /^"(.*)"$/) {$app = $1}

			$app =~ s{/docroot/?}{};

			-f "$app/conf/httpd.conf" and -f "$app/lib/Config.pm" or next;
			
			next if $main::configs -> {$app};
			
			print STDERR "Loading $app...\n";
	
			check_configuration_for_application ($app);

			print STDERR "Trying $app...\n";
			
			$ENV {SCRIPT_NAME} = '/__try__and__disconnect';

			my $error = handle_request_for_application ($app);
						
			die $error if $error;

		}
	
		close (N);
	
	}

	my $socket = FCGI::OpenSocket ($options {-address}, $options {-backlog});
	
	my @threads = ();
		
	for (; 1; sleep ($options {-timeout})) {

		@threads = grep {$_ -> is_running} @threads;
		
		foreach (1 .. $options {-processes} - @threads) {
	
			push @threads, (my $thread = threads -> create ({'exit' => 'threads_only'}, sub {

				my $request = FCGI::Request (\*STDIN, \*STDOUT, new IO::File, \%ENV, $socket);

				while ($request -> Accept >= 0) {

					my $app = $ENV {DOCUMENT_ROOT};

					$app =~ s{/docroot/?$}{};

					open (STDERR, ">>$app/logs/error.log");

					check_configuration_and_handle_request_for_application ($app);

				}

			}));
			
			$thread -> detach;
			
		}

	}

}

1;