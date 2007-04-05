package Eludia::Loader;

################################################################################

sub import {

	my ($dummy, $root, $package, $preconf) = @_;
	
	ref $root eq ARRAY or $root = [$root];	
	
	$root -> [0] =~ /[A-Z0-9_]+$/;
	my $old_package = $&;
	
	eval "use lib '$$root[0]'";
	
	if ($old_package ne $package) {
		${$package . '::_OLD_PACKAGE'} = $old_package;
	}
	
	${$package . '::_NEW_PACKAGE'} = $package;
	${$package . '::_PACKAGE'}     = $package . '::';
	${$package . '::PACKAGE_ROOT'} = $root;
	${$package . '::preconf'}      = $preconf;
	
	my $dos = $preconf -> {core_path} ? <<EOL : 'require Eludia::Util; require Eludia;';
		do "$$preconf{core_path}/Eludia/Apache.pm";
		do "$$preconf{core_path}/Eludia/Content.pm";
		do "$$preconf{core_path}/Eludia/Validators.pm";
		do "$$preconf{core_path}/Eludia/InternalRequest.pm";
		do "$$preconf{core_path}/Eludia/Presentation.pm";
		do "$$preconf{core_path}/Eludia/Request.pm";
		do "$$preconf{core_path}/Eludia/Request/Upload.pm";
		do "$$preconf{core_path}/Eludia/SQL.pm";
		do "$$preconf{core_path}/Eludia/FileDumpHash.pm";
		do "$$preconf{core_path}/Eludia.pm";
	
		require_fresh ("$package::Config.pm");
		
EOL

	my $cmd = <<EOC;
		package $package;
		$dos
EOC
	
	eval $cmd;

	print STDERR $@ if $@;
	

}

1;