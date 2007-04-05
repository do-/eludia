package Eludia::FileDumpHash;

sub TIEHASH  {

	my ($package, $options) = @_;

	$options -> {path} or die "Path not defined\n";

	-d $options -> {path} or die "Path $options->{path} not found\n";

	bless $options, $package;

}

sub FETCH {

	my ($options, $key) = @_;

	my $src = '$VAR1 = {';
	
	my $path = $options -> {path} . '/' . $key . '.pm';
	
	-f $path or return {};
	
	open (I, $path) or die "Can't open '$path': $!\n";
	while (<I>) { $src .= $_ };
	close I;

	$src .= '}';

	my $VAR1;
	
	eval $src;
	
	die $@ if $@;
	
	return $VAR1;

}

1;
