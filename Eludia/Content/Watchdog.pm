
################################################################################

sub notify_about_error {

	my ($options) = @_;

	ref $options eq 'HASH' or $options = {error => $options};

	my $delimiter = "\n" . ('=' x 80) . "\n";

	$error_details = $delimiter . "$$options{label}:\n$$options{error}";

	log_error ($options);

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

		my $subject = "[watchdog][$_NEW_PACKAGE]$options->{tags}";

		!$blame or $subject .= " $blame";

		$_REQUEST {__was_notify_about_error} and return;

		$_REQUEST {__was_notify_about_error} = 1;

		send_mail ({
			to      => [keys %unique_recipients],
			subject => $subject,
			text    => $error_details . error_detail_tail ($options),
			log     => 'info',
		}) if !internal_error_is_duplicate ($options -> {error});
	}
}

################################################################################

sub investigate_error {

	my ($options, $sql, $params) = @_;

	ref $options eq 'HASH' or $options = {error => $options, sql => $sql, params => $params};

	if ($options -> {error} =~ s/^\#([\w-]+)\#\://) {

		my ($label) = split / at/sm, $options -> {error};

		return {
			field => $1,
			label => $label,
		};
	}

	if ($options -> {error} !~ /called at/) {

		return {
			label => $options -> {error},
		};
	}

	my $error_details = _adjust_core_error_kind ($options);

	my $id_error = internal_error_id ();

	my $msg;
	if ($options -> {error_kind} eq "sql lock") {
		$msg = $i18n -> {try_again};
	} else {
		$msg = $i18n -> {internal_error} . (
			$preconf -> {mail} -> {admin}? (" "  . $i18n -> {internal_error_we_know}) : ""
		);
	}

	return {
		label => "[$id_error]$$options{error_tags}",
		error => $error_details . $options -> {error},
		msg   => $msg,
		kind  => $options -> {error_kind},
		tags  => $options -> {error_tags},
		sql   => $options -> {sql},
		params => $options -> {params},
	};
}

################################################################################

sub try_to_repair_error {

	my ($options) = @_;

	$_REQUEST {__was_repair_attempt} and return;

	$_REQUEST {__was_repair_attempt} = 1;

	if ($options -> {sql}) {

		my ($missing_column_table, $column) = $options -> {error} =~ /Unknown column '(\w+)\.(\w+)'/i;

		my ($database, $missing_table) = $options -> {error} =~ /Table '(\w+)\.(\w+)' doesn't exist/i;

		repair_table_model ($missing_table || $missing_column_table || sql_query_table ($options -> {sql}));
	}
}

################################################################################

sub exists_sql_table {

	my ($table)	 = @_;

	$table && keys %{$DB_MODEL -> {tables} -> {$table}} or return 0;

	return keys %{$DB_MODEL -> {tables} -> {$table} -> {columns}} > 0;
}

################################################################################

sub repair_table_model {

	my ($tables) = @_;

	$tables or return;

	ref $tables eq 'ARRAY' or $tables = [$tables];

	@$tables = grep {exists_sql_table ($_)} @$tables;

	@$tables or return;

	my $table_names = join ',', @$tables;

	$ENV {ELUDIA_SILENT} or print STDERR "\n\n" . script_log_signature ()
		. "refresh model for tables: $table_names...\n";

	sql_weave_model ($DB_MODEL);

	$model_update -> assert (

		prefix => 'application model#',

		default_columns => $DB_MODEL -> {default_columns},

		tables => {
			(map {$_ => $DB_MODEL -> {tables} -> {$_} } grep {$DB_MODEL -> {tables} -> {$_}} @$tables),
		},
	);

	$ENV {ELUDIA_SILENT} or print STDERR script_log_signature () . "refresh model done\n";
}

################################################################################

sub log_error {

	my ($options) = @_;

	print STDERR $options -> {error} . "\n";

	my $log = $preconf -> {_} -> {logs} . 'fatal.log';

	my $delimiter = "\n" . ('=' x 80) . "\n";
	open (F, ">>$log") or die "Can't write to $log:$1\n";
	print F "$delimiter$$options{label}:\n$$options{error}";
	close F;
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

	my $warning_subject = "[watchdog][$_NEW_PACKAGE][script] $script_type $total_ms ms is above threshold warning $limit_ms ms";

	print STDERR "$warning_subject\n";

	if ($preconf -> {mail} -> {admin}) {

		my ($warning_details, @guessed_causers) = ("[" . internal_error_id () . "][script]:\n");

		@$scripts = sort {$b -> {execution_ms} <=> $a -> {execution_ms}} @$scripts;


		my $is_need_blame;

		$preconf -> {core_warn_script_time_top} ||= 5;

		if ($preconf -> {core_warn_script_time_top}) {
			for (my $i = 0; $i < $preconf -> {core_warn_script_time_top} && $i < @$scripts; $i++) {
				$is_need_blame -> {$scripts -> [$i] -> {name}} = 1;
			}
		}

		foreach my $i (@$scripts) {

			$warning_details .= $i -> {execution_ms} . ' ms ' . $i -> {path};

			if ($is_need_blame -> {$i -> {name}}) {

				my @script_authors = guess_error_author_mail ({error_kind => 'script', file => $i -> {path}, line => 1});

				$warning_details .= !@script_authors? ""
					: (" (blame " . join (', ', map {$_ -> {label}} @script_authors) . ")");

				push @guessed_causers, @script_authors;
			}

			$warning_details .= "\n";
		}

		my %unique_recipients;
		foreach (@{$preconf -> {mail} -> {admin}}, map {$_ -> {mail}} @guessed_causers) {
			$unique_recipients {$_} = 1;
		}

		send_mail ({
			to      => [keys %unique_recipients],
			subject => $warning_subject,
			text    => $warning_details,
			log     => 'info',
		}) if !internal_error_is_duplicate ($warning_details);
	}
}

################################################################################

sub error_detail_tail {

	my ($options) = @_;

	return ''
		if $options -> {kind} ne 'code';

	local %_REQUEST = %_REQUEST_VERBATIM;

	local %_REQUEST = %_REQUEST;

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

	my $error_details;

	my $subdelimiter = "\n" . ('-' x 80) . "\n";

	if ($options -> {error} =~ /Invalid response/i
		|| $options -> {error} =~ /server has gone away/i
		|| $options -> {error} =~ /Can't connect/i
		|| $options -> {error} =~ /Lost connection/i
	) {
		$options -> {error_kind} ||= "network";
	}

	if ($options -> {sql}) {

		$options -> {error_kind} eq 'network'
			or $options -> {error_tags} .= '[' . sql_query_table ($options -> {sql}) . ']';

		$options -> {error_kind} ||= "sql";

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

	if ($options -> {error} =~ /Unknown column/i || $options -> {error} =~ /Duplicate entry/i) {
		$options -> {error_kind} = "model";
	}


	if ($options -> {error} =~ /Can't open file/i
		|| $options -> {error} =~ /Can't write/i
		|| $options -> {error} =~ /File not found/i) {

		$options -> {error_kind} = "file";
	}

	$options -> {error_kind} ||= "code";

	$options -> {error_tags} = '[' . $options -> {error_kind} . ']' . $options -> {error_tags};

	return $error_details;
}

################################################################################

sub sql_query_table {

	my ($sql) = @_;

	$sql =~ s/^\s+//ig;

	$sql =~ s/\s*#.*$//i;

	$sql =~ s/\s+/ /ig;

	$sql =~ s/^(SELECT|DELETE).*FROM //i;

	$sql =~ s/^INSERT INTO //i;

	$sql =~ s/^REPLACE( INTO)? //i;

	$sql =~ s/^UPDATE //i;

	$sql =~ s/^CREATE TABLE //i;

	$sql =~ s/^ALTER TABLE //i;

	my ($table) = $sql =~ /(\w+)/i;

	return $table;
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
