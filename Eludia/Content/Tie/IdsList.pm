package Eludia::Tie::IdsList;

################################################################################

sub TIESCALAR {

	my ($class, $options) = @_;

	bless $options, $class;
	
}

################################################################################

sub _sql {

	my ($self) = @_;
	
	return $self -> {sql_interpolated} if $self -> {sql_interpolated};
	
	$self -> {sql_interpolated} = $self -> {sql};
	
	$self -> {sql_interpolated} =~ s{\?}{\%s}g;
	
	$self -> {sql_interpolated} = sprintf ($self -> {sql_interpolated}, map {$self -> {db} -> quote ($_)} @{$self -> {params}});
	
	return $self -> {sql_interpolated};

}

################################################################################

sub _check {

	my ($self) = @_;

	return if $self -> {body};		

	$self -> {body} = '-1';

	my $sql;
                                        
	if ($self -> {sql_translator_ref}) {
		$sql = $self -> {sql_translator_ref} ($self -> {sql});
	} else {
		$sql = $self -> {sql};
	}

	my $st = $self -> {db} -> prepare_cached ($sql, {}, 3);
	
	&{"$self->{package}::sql_safe_execute"} ($st, $self -> {params}, $self -> {db});
	
	while (my @a = $st -> fetchrow_array) {
		foreach my $id (@a) {
			$self -> {body} .= ",$id" if $id
		}
	}

	$st -> finish;

}

################################################################################

sub FETCH {

	my ($self) = @_;
	
	$self -> _check;

	return $self -> {body};

}

################################################################################

sub STORE {}

################################################################################

sub UNTIE {}

################################################################################

sub DESTROY {}

1;