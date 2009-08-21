package Eludia::Tie::FileDumpHash;

sub TIEHASH  {

	my ($package, $options) = @_;

	$options -> {path} or die "Path not defined\n";
	
	ref $options -> {path} or $options -> {path} = [$options -> {path}];
	
	foreach my $dir (@{$options -> {path}}) {

		-d $dir or die "$dir is not a directory\n";

	}

	bless $options, $package;

}

sub FETCH {

	my ($options, $key) = @_;
	
	my $VAR1 = {};

	foreach my $dir (reverse @{$options -> {path}}) {

		my $path = "${dir}/${key}.pm";

		-f $path or next;

		my $VAR;
		open (I, $path) or die "Can't open '$path': $!\n";
		my $src = join '', (<I>);
		eval "\$VAR = {$src}"; die $@ if $@;
		close I;
		
		foreach my $object (keys (%$VAR)) {

			if (ref $VAR -> {$object} eq HASH) {

				foreach my $key (keys %{$VAR -> {$object}}) {
					$VAR1 -> {$object} -> {$key} ||= $VAR -> {$object} -> {$key};
				}

			} 
			elsif (ref $VAR -> {$object} eq ARRAY) {

				$VAR1 -> {$object} ||= [];
				push @{$VAR1 -> {$object}}, @{$VAR -> {$object}};

			}
			elsif (!ref $VAR -> {$object}) {

				$VAR1 -> {$object} ||= $VAR -> {$object};

			}

		}

		$VAR1 -> {_src} ||= $src;

	}
	
	return $VAR1;

}

1;