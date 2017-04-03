package Eludia::Loader;

################################################################################

sub import {

	my ($dummy, $root, $package, $preconf) = @_;
	
	$Eludia::last_loaded_package = $package;
	
	ref $root eq ARRAY or $root = [$root];	
			
	eval "use lib '$$root[0]'";
		
	${$package . '::_NEW_PACKAGE'} = $package;
	${$package . '::_PACKAGE'}     = $package . '::';
	${$package . '::PACKAGE_ROOT'} = $root;
	${$package . '::preconf'}      = $preconf;

	my $path = __FILE__;	
	$path =~ s{Loader.pm}{GenericApplication};

	unshift @$root, $path;

	eval "package $package; require Eludia;";

	print STDERR $@ if $@;	

}

1;