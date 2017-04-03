use FCGI;
use IO::File;
use JSON;
use Cwd;

################################################################################

sub start {
	
	warn "\n ------------------------------------------------------\n";
	warn " == Starting Eludia.pm FastCGI single process server ==\n";
	warn " ------------------------------------------------------\n\n";
	
	my $fn = 'conf/elud.json';
	open (I, $fn) or die "Can't read $fn: $!";
	my $json = join '', grep /^[^\#]/, (<I>);
	close (I);
	
	my $o = decode_json ($json);

	$o -> {fcgi} -> {address} ||= ':' . $o -> {fcgi} -> {port};
	$o -> {fcgi} -> {backlog} ||= 1024;

	require Eludia::Loader;
	
	Eludia::Loader -> import (Cwd::abs_path ('lib'), 'APP', $o -> {app});
		
	APP::require_config ();
	APP::sql_reconnect  ();
	APP::require_model  ();		
	
	my $socket = FCGI::OpenSocket ($o -> {fcgi} -> {address}, $o -> {fcgi} -> {backlog});
			
	my $request = FCGI::Request (\*STDIN, \*STDOUT, new IO::File, \%ENV, $socket);

	open (STDERR, ">>logs/error.log");

	while ($request -> Accept >= 0) {

		eval {APP::handler ()};
		
		warn $@ if $@;

	}

}

1;