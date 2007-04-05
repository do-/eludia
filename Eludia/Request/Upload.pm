package Eludia::Request::Upload;

################################################################################

sub new {

	my $proto = shift;
	my $class = ref ($proto) || $proto;

	my $self  = {};
	$self -> {Q} = $_ [0];
	$self -> {Param} = $_ [1];
	$self -> {FH} = $self -> {Q} -> upload ($self -> {Param});
	$self -> {FN} = $self -> {Q} -> param ($self -> {Param});
	
	eval { $self -> {Type} = $self -> {Q} -> uploadInfo ($self -> {FN}) -> {'Content-Type'}; };
	
	my $current_position = tell ($self -> {FH});
	seek ($self -> {FH},0,2);
	$self -> {Size} = tell ($self -> {FH});
	seek ($self -> {FH}, $current_position, 0);

	bless ($self, $class);

	return $self;
}

################################################################################

sub size {
	my $self = shift;
	return $self -> {Size};
}

################################################################################

sub fh {
	my $self = shift;
	return $self -> {FH};
}

################################################################################

sub filename {
	my $self = shift;
	return $self -> {FN};
}

################################################################################

sub type {
	my $self = shift;
	return $self -> {Type};
}

1;