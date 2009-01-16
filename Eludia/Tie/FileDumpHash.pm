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

	foreach my $dir (@{$options -> {path}}) {

		my $path = "${dir}/${key}.pm";

		-f $path or next;

		open (I, $path) or die "Can't open '$path': $!\n";
		my $src = join '', (<I>);
		eval "\$VAR1 = {$src}"; die $@ if $@;
		close I;
		
		$VAR1 -> {_src} = $src;

		last;

	}
	
	return $VAR1;

}

1;