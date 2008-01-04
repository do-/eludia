use FCGI;
use CGI;
use IO;

our $fake_stderr = new IO::File;

open STDERR, ">c:/error.log" or die "Can't write to c:/error.log: $!\n";

print STDERR "Eludia::IIS is starting\n";

my $path = __FILE__;
$path =~ s{Eludia/IIS\.pm}{lib};
push @INC, $path;

my $configs = {};

my $request = FCGI::Request (\*STDIN, \*STDOUT, $fake_stderr, \%ENV, 0, 0);

while ($request -> Accept >= 0) {

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

	&{"$configs->{$app}->{handler}::handler"} ();

	$request ->  Finish;

}

1;