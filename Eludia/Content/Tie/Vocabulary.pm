package Eludia::Tie::Vocabulary;

################################################################################

sub TIEARRAY {

	my ($class, $options) = @_;
	
	$options or return [];

	bless $options, $class;
	
}

################################################################################

sub label {

	my ($self, $id, $template) = @_;
	
	my $h = $self -> _select_hash ($id);
	
	$h -> {id} or return '';
	
	$template or return $h -> {label};
	
	$template =~ s{\$_(?!\w)}{$h->{label}};
	
	return $template;

}

################################################################################

sub _select_hash {

	my ($self, $id) = @_;
	
	my $sql = $self -> {sql};
	
	$sql =~ s{WHERE.*}{WHERE id = ?}gism;
	
	my $h = &{"$self->{package}::sql_select_hash"} ($sql, $id);
	
	return $h;

}

################################################################################

sub _check {

	my ($self) = @_;
	
	return if $self -> {body};		
	
	my $time = &{"$self->{package}::time"} ();

	my $list = &{"$self->{package}::sql_select_all"} ($self -> {sql}, @{$self -> {params}});

	if ($self -> {tree}) {
	
		$list = &{"$self->{package}::tree_sort"} ($list);
				
		if (!$self -> {_REQUEST} -> {__read_only} || $self -> {_REQUEST} -> {__only_form}) {

			foreach (@$list) { $_ -> {label} = ('&nbsp;&nbsp;' x $_ -> {level}) . $_ -> {label} }
	
		}
		
	}

	$self -> {body} = $list;

}

################################################################################

sub FETCH {

	my ($self, $index) = @_;
	
	$self -> _check;

	return $self -> {body} -> [$index];

}

################################################################################

sub STORE {
	
	my ($self, $index, $value) = @_;

	$self -> _check;

	$self -> {body} -> [$index] = $value;
	
}

################################################################################

sub FETCHSIZE {

	my ($self) = @_;
	
	$self -> _check;

	return scalar @{$self -> {body}};
	
}

################################################################################

sub STORESIZE {

	my ($self, $count) = @_;
	
	$self -> _check;

	$self -> {body} = [splice @{$self -> {body}}, 0, $count];

}

################################################################################

sub EXTEND {}

################################################################################

sub EXISTS {

	my ($self, $index) = @_;
	
	$self -> _check;

	return defined $self -> {body} -> [$index];

}

################################################################################

sub DELETE {

	my ($self, $index) = @_;
	
	$self -> _check;

	$self -> {body} -> [$index] = {};

}

################################################################################

sub CLEAR {

	my ($self) = @_;
	
	delete $self -> {body};

}

################################################################################

sub PUSH {

	my ($self, @list) = @_;
	
	$self -> _check;

	return push @{$self -> {body}}, @list;

}

################################################################################

sub POP {

	my ($self) = @_;
	
	$self -> _check;

	return pop @{$self -> {body}};

}

################################################################################

sub SHIFT {

	my ($self) = @_;
	
	$self -> _check;

	return shift @{$self -> {body}};

}

################################################################################

sub UNSHIFT {

	my ($self, @list) = @_;
	
	$self -> _check;

	return unshift @{$self -> {body}}, @list;

}

################################################################################

sub SPLICE {

	my ($self, $offset, $length, @list) = @_;
	
	$self -> _check;
	
	my @result = splice @{$self -> {body}}, $offset, $length, @list;

	$self -> {body} = \@result;
	
	return @result;

}

################################################################################

sub UNTIE {}

################################################################################

sub DESTROY {}

1;