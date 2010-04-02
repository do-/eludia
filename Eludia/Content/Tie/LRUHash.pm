package Eludia::Content::Tie::LRUHash;

################################################################################

sub TIEHASH  {

	my ($package, $self) = @_;
	
	my ($calling_package, $app, $line) = caller ();

	$self ||= {};
	
	$self -> {package} = $calling_package;
	
	$self -> {body}  ||= {};
	$self -> {size}  ||= 300;
	$self -> {delta} ||= (int ($self -> {size} / 10)) || 10;
	
	$self -> {size} --;
	
	return bless $self, $package;

}

################################################################################

sub FETCH {

	my ($self, $key) = @_;

	my $value = $self -> {body} -> {$key};
	
	$value or return undef;
	
	$value -> {hits} ++;

	return $value -> {value};

}

################################################################################

sub STORE {

	my ($self, $key, $value) = @_;
	
	$value or return undef;

	if (%{$self -> {body}} >= $self -> {size}) {
	
		my $time = Time::HiRes::time ();
	
		foreach my $i (values %{$self -> {body}}) {
								
			$i -> {freq} = $i -> {hits} / (($time - $i -> {time}) || 1)
		
		}
		
		my @keys = sort {$a -> {freq} <=> $b -> {freq}} keys %{$self -> {body}};

		foreach my $i (@keys [0 .. $self -> {delta} - 1]) {
		
			delete $self -> {body} -> {$i};
		
		}
		
		&{"$self->{package}::__log_profilinig"} ($time, "     <st cache downsized>");

	}
	
	$self -> {body} -> {$key} = {
	
		time  => $time,
	
		value => $value,
		
	};
	
	return $value;

}

################################################################################

sub DELETE {

	my ($self, $key) = @_;

	delete $self -> {body} -> {$key};

}

################################################################################

sub CLEAR {

	my ($self) = @_;
	
	$self -> {body} = {};

}

################################################################################

sub EXISTS {

	my ($self, $key) = @_;

	exists $self -> {body} -> {$key};

}

################################################################################

sub FIRSTKEY {

	my ($self) = @_;
	
	my $a = keys %{$self -> {body}};
	
	each %{$self -> {body}};

}

################################################################################

sub NEXTKEY {

	my ($self) = @_;
	
	each %{$self -> {body}};

}

################################################################################

sub SCALAR {

	my ($self) = @_;
	
	0 + %{$self -> {body}};

}

################################################################################

sub UNTIE {

	my ($self) = @_;
	
	$self -> {body} = {};

}

1;