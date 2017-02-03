################################################################################

sub checksum_lock {}

################################################################################

sub checksum_unlock {}

################################################################################

sub checksum_file_name {

	my ($kind) = @_;

	return "DB";

}

################################################################################

sub checksum_init {

	my ($kind) = @_;

	loading_log "   $kind stored in table $conf->{systables}->{__checksums}... ";

	my %h;
	tie (%h, 'Eludia::Tie::Checksums', {
		kind        => $kind,
		__checksums => $conf -> {systables} -> {__checksums},
		}) or die "Couldn't tie to database: $!\n";

	$preconf -> {_} -> {checksums} -> {$kind} = \%h;

	loading_log "ok.\n";

}

################################################################################

BEGIN {

	if ($preconf -> {_} -> {docroot}) {

		$preconf -> {_} -> {checksums} = {};

		loading_log "DB, ok.\n";

	}

}

1;
