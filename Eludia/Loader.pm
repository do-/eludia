package Eludia::Loader;

################################################################################

sub import {

	my ($dummy, $root, $package, $preconf) = @_;

	$Eludia::last_loaded_package = $package;
	
	ref $root eq ARRAY or $root = [$root];	
		
	$root -> [0] =~ /[A-Z0-9_]+$/;
	my $old_package = $& || '';
	
	eval "use lib '$$root[0]'";
	
	if ($old_package ne $package) {
		${$package . '::_OLD_PACKAGE'} = $old_package;
	}
	
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