use FCGI;
use IO::File;
use JSON;
use Cwd;

################################################################################

sub start {

	my $efn = Cwd::abs_path ('logs/error.log');
	
	warn "Redirecting STDERR to $efn...\n";
	
	open (STDERR, ">>$efn") or die "Can't append to $fn: $!\n";
	
	my $fn = 'conf/elud.json';
	open (I, $fn) or die "Can't read $fn: $!";
	my $json = join '', grep /^[^\#]/, (<I>);
	close (I);
	
	my $o = decode_json ($json);

	$o -> {fcgi} -> {address} ||= ':' . $o -> {fcgi} -> {port};
	$o -> {fcgi} -> {backlog} ||= 1024;

	require Eludia::Loader;
	
	Eludia::Loader -> import (Cwd::abs_path ('lib'), 'APP', $o -> {app});
		
	APP::sql_reconnect  ();
	APP::require_model  ();		
	
	my $socket = FCGI::OpenSocket ($o -> {fcgi} -> {address}, $o -> {fcgi} -> {backlog});
			
	my $request = FCGI::Request (\*STDIN, \*STDOUT, new IO::File, \%ENV, $socket);

	while ($request -> Accept >= 0) {

		eval {APP::handler ()};
		
		warn $@ if $@;

	}

}

1;