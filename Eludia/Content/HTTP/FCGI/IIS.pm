use FCGI;
use CGI;
use IO;
use Data::Dumper;
use Time::HiRes 'time';

our $fake_stderr = new IO::File;

#open STDERR, ">c:/error.log" or die "Can't write to c:/error.log: $!\n";

#print STDERR "Eludia::IIS is starting\n";

my $path = __FILE__;
$path =~ s{Eludia/IIS\.pm}{lib};
push @INC, $path;

my $configs = {};

my $request = FCGI::Request (\*STDIN, \*STDOUT, $fake_stderr, \%ENV, 0, 0);

my $handling_request = 0;
my $exit_requested = 0;

sub sig_handler {
	$exit_requested = 1;
	exit (0) if !$handling_request;
}

$SIG{USR1} = \&sig_handler;
$SIG{TERM} = \&sig_handler;
#$SIG{PIPE} = 'IGNORE';
$SIG{PIPE} = sub {warn "PIPE!\n"};

while (1) {

	$handling_request = $request -> Accept;

	warn "$$:accepted $handling_request...\n";
	
	last if $handling_request < 0;
	
	my $time = time;

	my $app = $ENV {DOCUMENT_ROOT};
	$app =~ s{\\docroot\\?$}{};
	
	open STDERR, ">>$app\\logs\\error.log" or die "Can't write to $app\\logs\\error.log: $!\n";
	
	unless ($configs -> {$app}) {
	
		my $httpd_conf = $app . "\\conf\\httpd.conf";

		my $cnf_src = '';
		
		open C, $httpd_conf or die "Can't read $httpd_conf: $!\n";
		
		while (my $s = <C>) {
		
			next if $s =~ /\s*\#/;
		
			$cnf_src .= $s;
			
			if ($s =~ /PerlHandler\s+(\w+)/) {
			
				$configs -> {$app} -> {handler} = $1;
			
			}

			if ($s =~ /SetEnv\s+(\w+)\s+(.*)/) {
			
				my ($k, $v) = ($1, $2);
				
				$v =~ s{$\s*\"?}{};
				$v =~ s{\"?\s*$}{};
			
				$configs -> {$app} -> {env} -> {$k} = $v;
			
			}	
			
		}
		close C;
		
		$cnf_src =~ m{\<perl\>(.*)\</perl\>}sm;
				
		eval $1;
		
		die "Application initialization error: $@" if $@;
	
	}
	
	foreach my $k (keys %{$configs -> {$app} -> {env}}) {
	
		$ENV {$k} = $configs -> {$app} -> {env} -> {$k};
	
	}
	
	warn "$$:calling handler...\n";

	&{"$configs->{$app}->{handler}::handler"} ();

	warn "$$:handler complete. (" . ((time - $time) * 1000) . " ms)\n";

#	warn Dumper (\%{"$configs->{$app}->{handler}::_REQUEST"});

	$handling_request = 0;

	last if $exit_requested;

}

$request ->  Finish;

exit (0);

1;