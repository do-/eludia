package Eludia::Tie::Checksums;

################################################################################

sub TIEHASH {

	my ($class, $options) = @_;

	$options or return {};

	my ($calling_package, $app, $line) = caller ();

	$options -> {package} = $calling_package;

	$options -> {__checksums} ||= '__checksums';

	bless $options, $class;
}

################################################################################

sub FETCH {

	my ($self, $key) = @_;

	$self -> _check;

	return $self -> {body} -> {$key};

}

################################################################################

sub STORE {

	my ($self, $key, $value) = @_;

	$self -> _check;

	if ($self -> {body} -> {$key} && $self -> {body} -> {$key} == $value) {
		return $value;
	}

	my $id_checksum = &{"$self->{package}::sql_select_scalar"} (
		"SELECT id FROM $self->{__checksums} WHERE id_checksum = ? AND kind = ?"
		, $key
		, $self -> {kind}
	);

	if ($id_checksum) {
		&{"$self->{package}::sql_do"} (
			"UPDATE $self->{__checksums} SET checksum = ? WHERE id_checksum = ? AND kind = ?"
			, $value
			, $key
			, $self -> {kind}
		);
	} else {
		&{"$self->{package}::sql_do"} (
			"INSERT INTO $self->{__checksums} (kind, id_checksum, checksum) VALUES (?, ?, ?)"
			, $self -> {kind}
			, $key
			, $value
		);
	}

	$self -> {body} -> {$key} = $value;

}

################################################################################

sub _check {

	my ($self) = @_;

	my $list = &{"$self->{package}::sql_select_all"} ("SELECT * FROM $self->{__checksums}");

	my $checksum_hash = {};

	foreach (@$list) {

		$checksum_hash -> {$_ -> {id_checksum}} = $_ -> {checksum};
	}

	$self -> {body} = $checksum_hash;
}

################################################################################

sub EXTEND {
}

################################################################################

sub EXISTS {

	my ($self, $key) = @_;

	$self -> _check;

	return exists $self -> {body} -> {$key};

}

################################################################################

sub DELETE {

	my ($self, $key) = @_;

	$self -> _check;

	return delete $self -> {body} -> {$key};
}

################################################################################

sub CLEAR {

	my ($self) = @_;

	delete $self -> {body};

}

################################################################################

sub FIRSTKEY {

	my ($self) = @_;

	$self = keys %{$self};

	return scalar each %{$self};

}

################################################################################

sub NEXTKEY {

	my ($self) = @_;

	return scalar each %{$self};

}

################################################################################

sub DESTROY {}

1;