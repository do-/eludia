
################################################################################

sub notify_about_error {

	my ($options) = @_;

	ref $options eq 'HASH' or $options = {error => $options};


	my $delimiter = "\n" . ('=' x 80) . "\n";

	my $subdelimiter = "\n" . ('-' x 80) . "\n";

	my $error_details;

	$options -> {error_kind} = "code error";

	if ($options -> {sql}) {

		$options -> {error_kind} = "sql error";

		$error_details .= $options -> {sql} . "\n";

		if (@{$options -> {params}}) {
			$error_details .= "params:\n(" . join (", ", @{$options -> {params}}) . ")\n";
		}

		my $is_lock_error = 0 + ($options -> {error} =~ /failed:\s*(dead)?lock/i);

		if ($is_lock_error) {
			$error_details .= $subdelimiter . sql_engine_status ();
			$options -> {error_kind} = "sql lock error";
		}
	}

	my $id_error = internal_error_id ();

	$error_details = $delimiter . "[$id_error][$options->{error_kind}]:\n" . $error_details;

	print STDERR $error_details . $options -> {error};

	if ($preconf -> {mail} -> {admin}) {

		my $now = sprintf ('%04d-%02d-%02d %02d:%02d:%02d', Today_and_Now ());
		send_mail ({
			to      => $preconf -> {mail} -> {admin},
			subject => "[watchdog][$id_error][$options->{error_kind}]",
			text    => $error_details . $options -> {error},
		}) if !internal_error_is_duplicate ($options -> {error});
	}

	my $msg = $options -> {error_kind} eq 'sql lock error'? $i18n -> {try_again} : $i18n -> {internal_error};

	return "[" . internal_error_id () . "]\n" . $msg;
}

################################################################################

sub internal_error_id {

	my $now = time;
	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime ($now);
	$year += 1900;
	$mon ++;

	return sprintf ("$_NEW_PACKAGE %04d-%02d-%02d %02d:%02d:%02d:%03d %s%s"
		, $year
		, $mon
		, $mday
		, $hour
		, $min
		, $sec
		, int (1000 * ($now - int $now))
		, "process=$$"
		, ($_REQUEST {_id_log}? " id_log=$_REQUEST{_id_log}" : "")
	);
}

################################################################################

sub internal_error_is_duplicate {

	my ($error)  = @_;

	$error =~ s/\(0x\w{7}\)/\(HxHHHHHHH\)/g;
	$error =~ s/\d+/digits/g;

	my $error_md5 = Digest::MD5::md5_hex ($error);

	checksum_lock ('internal_error_repeats');
	$preconf -> {_} -> {checksums} -> {internal_error} ||= {};
	if ($preconf -> {_} -> {checksums} -> {internal_error} -> {$error_md5}) {
		$preconf -> {_} -> {checksums} -> {internal_error} -> {$error_md5} -> {hits}++;
		checksum_unlock ('internal_error_repeats');
		return 1;
	}

	my $max_size = $preconf -> {internal_error_duplicate_cache_size} || 10;

	my $time = time;

	my $delta = $max_size - keys %{$preconf -> {_} -> {checksums} -> {internal_error}};

	if ($delta <= 0) {

		foreach my $i (values %{$preconf -> {_} -> {checksums} -> {internal_error}}) {

			$i -> {freq} = $i -> {hits} / (($time - $i -> {time}) || 1)

		}

		my @keys = sort {$a -> {freq} <=> $b -> {freq}} values %{$preconf -> {_} -> {checksums} -> {internal_error}};

		foreach my $i (@keys [0 .. $delta + 1]) {

			delete $preconf -> {_} -> {checksums} -> {internal_error} -> {$i};

		}

	}

	$preconf -> {_} -> {checksums} -> {internal_error} -> {$error_md5} = {

		time  => $time,

		hits  => 1,

	};

	checksum_unlock ('internal_error_repeats');

	return 0;
}

1;
