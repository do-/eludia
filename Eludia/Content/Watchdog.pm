
################################################################################

sub notify_about_error {

	my ($options) = @_;

	ref $options eq 'HASH' or $options = {error => $options};


	my $delimiter = "\n" . ('=' x 80) . "\n";

	my $error_details = _adjust_core_error_kind ($options);

	my $id_error = internal_error_id ();

	$error_details = $delimiter . "[$id_error][$options->{error_kind}]:\n" . $error_details;

	print STDERR $error_details . $options -> {error} . "\n";

	my $blame;

	if ($preconf -> {mail} -> {admin}) {

		my %unique_recipients;
		my @guessed_causers = guess_error_author_mail ($options);
		foreach (@{$preconf -> {mail} -> {admin}}, map {$_ -> {mail}} @guessed_causers) {
			$unique_recipients {$_} = 1;
		}

		my $location = join "\n", map {$_ -> {file} . ':' . $_ -> {line}} @guessed_causers;
		$error_details = $location . $error_details;

		$blame = !@guessed_causers? ""
			: "blame " . join (', ', map {$_ -> {label}} @guessed_causers);

		my $subject = "[watchdog][$_NEW_PACKAGE][$options->{error_kind}]";

		!$blame or $subject .= " $blame";

		send_mail ({
			to      => [keys %unique_recipients],
			subject => $subject,
			text    => $error_details . $options -> {error} . error_detail_tail ($options),
		}) if !internal_error_is_duplicate ($options -> {error});
	}

	if ($_REQUEST {__skin} eq 'STDERR') { # offline script
		return $error_details . $options -> {error};
	}

	my @msg = ("[$id_error]");

	!$preconf -> {testing} or !$blame or push @msg, "[$blame]";

	push @msg, ($options -> {error_kind} eq 'sql lock error'?
		$i18n -> {try_again} : $i18n -> {internal_error});

	return join ("\n", @msg);
}

################################################################################

sub notify_script_execution_time {

	my ($scripts, $script_type) = @_;

	return
		if $ENV {ELUDIA_SILENT};

	my $total_ms = 0;

	foreach my $i (@$scripts) {
		$total_ms += $i -> {execution_ms};
	}

	my $limit_ms = $preconf -> {core_warn_script_time} || 5000;

	$total_ms > $limit_ms or return;

	my $warning_subject = "[watchdog][$_NEW_PACKAGE][script] $script_type total execution time $total_ms ms is above threshold warning $limit_ms ms";

	print STDERR "$warning_subject\n";

	if ($preconf -> {mail} -> {admin}) {

		my ($warning_details, @guessed_causers) = ("[" . internal_error_id () . "][script]:\n");

		@$scripts = sort {$b -> {execution_ms} <=> $a -> {execution_ms}} @$scripts;

		foreach my $i (@$scripts) {

			my @script_authors = guess_error_author_mail ({error_kind => 'script', file => $i -> {path}, line => 1});

			my $blame = !@script_authors? ""
				: (" (blame " . join (', ', map {$_ -> {label}} @script_authors) . ")");

			$warning_details .= $i -> {execution_ms} . ' ms ' . $i -> {path} . " $blame\n";

			push @guessed_causers, @script_authors;
		}

		my %unique_recipients;
		foreach (@{$preconf -> {mail} -> {admin}}, map {$_ -> {mail}} @guessed_causers) {
			$unique_recipients {$_} = 1;
		}

		send_mail ({
			to      => [keys %unique_recipients],
			subject => $warning_subject,
			text    => $warning_details,
		}) if !internal_error_is_duplicate ($warning_details);
	}
}

################################################################################

sub error_detail_tail {

	my ($options) = @_;

	return ''
		if $options -> {error_kind} ne 'code';

	local %_REQUEST = %_REQUEST_VERBATIM;

	delete $_REQUEST {error};

	foreach $key (keys %_REQUEST) {
		delete $_REQUEST {$key} if $key =~ m/^__/;
	}

	my $error_tail;

	local $Data::Dumper::Terse = 1;

	$error_tail .= "\n\n\$_REQUEST = " . Dumper (\%_REQUEST);

	$error_tail .= "\n\n\$_USER = " . Dumper ({
		(map {$_ => $_USER -> {$_}} qw(id id__real label label__real))
	});

	return $error_tail;
}

################################################################################

sub guess_error_author_mail { # error author = last file commiter

	my ($options) = @_;

	$options -> {error_kind} ~~ ['sql', 'code', 'script']
		or return ();

	my ($file, $line) = ($options -> {file}, $options -> {line});

	if (!$file) {
		($file, $line) = $options -> {error} =~ /called at (\/.*lib\/.*\.pm) line (\d+)/;
	}

	if (!$file) {
		($file, $line) = $options -> {error} =~ /require (\/.*lib\/.*\.p[lm]) called at.*line (\d+)/;
	}

	$file && $line or return ();

	my ($module_root) = split /lib\/\w+\//, $file;
	my $git_dir = $module_root . '.git';

	local $SIG {'CHLD'} = 'DEFAULT';
	my $command = "git --git-dir $git_dir --work-tree=$module_root log -1 --format='%aN:%aE' $file";

	my $result = `$command`;
	if ($?) {
		warn "guess_error_author_mail '$command'\nerror: $?";
		return ();
	}
	chomp $result;

	my ($label, $mail) = split /:/, $result;

	return ({label => $label, mail => $mail, file => $file, line => $line});
}

################################################################################

sub _adjust_core_error_kind {

	my ($options) = @_;

	$options -> {error_kind} ||= "code";

	my $error_details;

	my $subdelimiter = "\n" . ('-' x 80) . "\n";

	if ($options -> {sql}) {

		$options -> {error_kind} = "sql";

		$error_details .= $options -> {sql} . "\n";

		if (@{$options -> {params}}) {
			$error_details .= "params:\n(" . join (", ", @{$options -> {params}}) . ")\n";
		}

		my $is_lock_error = 0 + ($options -> {error} =~ /failed:\s*(dead)?lock/i);

		if ($is_lock_error) {
			$error_details .= $subdelimiter . sql_engine_status ();
			$options -> {error_kind} = "sql lock";
		}
	}

	if ($options -> {error} =~ /Invalid response/i) {
		$options -> {error_kind} = "network";
	}

	if ($options -> {error} =~ /Unknown column/i || $options -> {error} =~ /Duplicate entry/i) {
		$options -> {error_kind} = "model";
	}


	if ($options -> {error} =~ /Can't open file/i
		|| $options -> {error} =~ /Can't write/i
		|| $options -> {error} =~ /File not found/i) {

		$options -> {error_kind} = "file";
	}

	return $error_details;
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

	my $max_size = $preconf -> {internal_error_duplicate_cache_size} || 100;

	my $time = time;

	my $delta = $max_size - keys %{$preconf -> {_} -> {checksums} -> {internal_error}};

	if ($delta <= 0) {

		foreach my $i (values %{$preconf -> {_} -> {checksums} -> {internal_error}}) {

			$i -> {freq} = $i -> {hits} / (($time - $i -> {time}) || 1)

		}

		my @keys = sort {$a -> {freq} <=> $b -> {freq}} values %{$preconf -> {_} -> {checksums} -> {internal_error}};

		foreach my $i (@keys [0 .. $delta + 1]) {

			delete $preconf -> {_} -> {checksums} -> {internal_error} -> {$i -> {md5}};

		}

	}

	$preconf -> {_} -> {checksums} -> {internal_error} -> {$error_md5} = {

		time  => $time,

		hits  => 1,

		md5   => $error_md5,

	};

	checksum_unlock ('internal_error_repeats');

	return 0;
}

1;
