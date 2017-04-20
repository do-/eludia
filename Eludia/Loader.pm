package Eludia::Loader;
use JSON;
use Cwd;

################################################################################

sub import {

	package APP;

	my $fn = 'conf/elud.json';
	open (I, $fn) or die "Can't read $fn: $!";
	my $json = join '', grep /^[^\#]/, (<I>);
	close (I);

	our $preconf = JSON::decode_json ($json);

	my $path = __FILE__;
	$path =~ s{Loader.pm}{GenericApplication};
	our $PACKAGE_ROOT = [Cwd::abs_path ('lib'), $path];	
			
	unshift (@INC, $PACKAGE_ROOT -> [0]);

	require Eludia;

}

1;