#############################################################################

sub wish_to_clarify_demands_for_table_triggers {

	my ($i, $options) = @_;

	my ($phase, @events) = split /_/, $i -> {name};

	$i -> {phase} = uc $phase;

	$i -> {events} = [sort map {uc} @events];

	my $tail = lc (join '_', (
		$i -> {phase},
		@{$i -> {events}},
		$options -> {table}
	));

	length $tail < 61 or $tail = Digest::MD5::md5_hex ($tail);

	$i -> {global_name} = 'on_' . $tail;

}

#############################################################################

sub wish_to_actually_create_table_triggers {

	my ($items, $options) = @_;

	foreach my $i (@$items) {

		my $events = join ' OR ', @{$i -> {events}};

		foreach my $sql (

			qq {

				DROP TRIGGER IF EXISTS
					$i->{global_name}
				;

			},

			qq {

				CREATE TRIGGER
					$i->{global_name}
				$i->{phase} $events ON
					$options->{table}
				FOR EACH ROW
				BEGIN
					$i->{body}
				END;

			},

		) {

			$sql =~ s{\s+}{ }gsm;
			$sql =~ s{^ }{};
			$sql =~ s{ $}{};

			sql_do ($sql);
		}


	}

}

1;
