################################################################################

sub dt_humanize {

	foreach my $h (@_) {
	
		foreach my $key (grep {/^dt_/} keys %$h) {

			my ($y, $m, $d) = dt_y_m_d ($h -> {$key});

			$h -> {$key . '_year'}       = $y;

			$h -> {$key . '_month'}      = $m;

			$h -> {$key . '_day'}        = $d;

			$h -> {$key . '_month_name'} = $i18n -> {months} -> [$m - 1];

		}
	
	}

}

################################################################################

sub dt_y_m_d {

	$_[0] =~ /^(\d+)\D(\d+)\D(\d+)/ or return ();
		
	return $1 > 1900 ? ($1, $2, $3) : ($3, $2, $1);

}

################################################################################

sub dt_iso {

	my @ymd = map {split /\D+/} @_;
	
	@ymd = reverse @ymd if $ymd [0] < 1000;
		
	return sprintf ('%04d-%02d-%02d', @ymd);

}

################################################################################

sub dt_dmy {

	my @dmy = map {split /\D+/} @_;
	
	@dmy = reverse @dmy if $dmy [2] < 1000;
	
	my $c = substr $i18n -> {_format_d}, 2, 1; 
	
	$c ||= '.';
	
	return sprintf ("\%02d${c}\%02d${c}\%02d", @dmy);

}

################################################################################

sub dt_add {

	my ($dt, $delta) = @_;
	
	my $was_iso = $dt =~ /^\d\d\d\d\-\d\d\-\d\d/;
	
	my $was_hms = $dt =~ /(\d+):(\d+):(\d+)$/;
	
	my @hms = $was_hms ? ($1, $2, $3) : ();

	my @delta = split /\s+/, $delta;
	
	my $what = 'Days';
	
	$delta [-1] =~ /^[A-Za-z]/ and $what = pop @delta;
	
	my $want_24 = ($what =~ s{24}{});
	
	if ($what =~ /^H/i) {
		
		$what = 'DHMS'; 	@delta = (0, $delta [0], 0, 0);
	
	}
	elsif ($what =~ /^M/i) {
		
		$what = 'DHMS';		@delta = (0, 0, $delta [0], 0);
	
	}
	elsif ($what =~ /^S/i) {
		
		$what = 'DHMS';		@delta = (0, 0, 0, $delta [0]);
	
	}
	
	require Date::Calc;
	
	my @ymd = dt_y_m_d ($dt);

	my $want_hms = $what =~ /HMS$/;
	
	if ($want_hms) { 
		
		@hms > 0 or @hms = (0, 0, 0);
		
		if ($hms [0] == 24) {
		
			$hms [0] = 0;
			
			@ymd = Date::Calc::Add_Delta_Days (@ymd, 1);
		
		}
	
	} else {	
		
		@hms = ();
	
	}

	my @dt = &{"Date::Calc::Add_Delta_$what"} (@ymd, @hms, @delta);

	return @dt if wantarray;
	
	if ($want_hms && $want_24 && $dt [3] == 0) {
	
		@dt [0 .. 2] = Date::Calc::Add_Delta_Days (@dt [0 .. 2], -1);
		
		$dt [3] = 24;

	}

	$dt = $was_iso ? dt_iso (@dt [0 .. 2]) : dt_dmy (@dt [0 .. 2]);

	$dt .= sprintf (' %02d:%02d:%02d', @dt [3 .. 5]) if $want_hms;

	return $dt;

}

################################################################################

sub dt_add_workdays {

	my ($dt, $workdays) = @_;
	
	my ($y, $m, $d) = Add_Delta_Days (dt_y_m_d ($dt), 1);
	
	$workdays --;
	
	my %years = ();
	
	my $dow = Day_of_Week ($y, $m, $d);
	
	while (1) {

		my $year = $years {$y};

		unless ($year) {
		
			$year = {};
		
			sql ($conf -> {systables} -> {holidays} => [['dt BETWEEN ? AND ?' => ["$y-01-01", "$y-12-31"]]], sub {
			
				$year -> {dt_iso ($i -> {dt})} = 1;
		
			});
			
			$years {$y} = $year;
			
		}

		next if (!%$year ? ($dow > 5) : $year -> {dt_iso ($y, $m, $d)});
				
		(-- $workdays) > 0 or last;
	
	}
	continue {

		($y, $m, $d) = Add_Delta_Days ($y, $m, $d, 1);
		
		$dow ++;
		
		$dow <= 7 or $dow = 1;

	}
	
	return dt_iso ($y, $m, $d);

}

################################################################################

sub cal_month {

	my ($_year, $_month) = @_;
	
	my $month = {
	
		year  => $_year,
		month => $_month,
		weeks => [],
		days  => [],
		
	};
	
	my $day_of_week   = Day_of_Week ($_year, $_month, 1);
	
	my $week_of_month = 1;

	foreach my $i (1 .. Date::Calc::Days_in_Month ($_year, $_month)) {

		my $day = {
		
			year          => $_year,
			month         => $_month,
			day           => $i,
			iso           => sprintf ('%04d-%02d-%02d', $_year, $_month, $i),
			day_of_week   => $day_of_week,
			week_of_month => $week_of_month,
			
		};
		
		$month -> {days}  -> [$i - 1] = $day;
		
		$month -> {weeks} -> [$week_of_month - 1] -> [$day_of_week - 1] = $day;
				
		next if ++ $day_of_week <= 7;
		
		$day_of_week = 1;
		
		$week_of_month ++;
			
	}

	return $month;

}

################################################################################

sub cal_quarter {

	my ($_year, $_quarter) = @_;
	
	my $first_month = 1 + 3 * ($_quarter - 1);
	
	my $quarter = {
	
		year    => $_year,
		
		quarter => $_quarter,
		
		months  => [map {cal_month ($_year, $_)} ($first_month .. $first_month + 2)],
		
		lines   => [],		
	
	};
	
	push @{$quarter -> {lines}}, {type => 'start_quarter', quarter => $quarter};
	
	foreach my $i (0 .. 5) {
	
		my @line = map {$quarter -> {months} -> [$_] -> {weeks} -> [$i]} (0 .. 2);
		
		last if 0 == grep {$_} @line;
		
		push @{$quarter -> {lines}}, \@line;
	
	}
	
	push @{$quarter -> {lines}}, {type => 'finish_quarter', quarter => $quarter};
	
	Scalar::Util::weaken ($quarter -> {lines} -> [$_] -> {quarter}) foreach (-1, 0);

	return $quarter;

}

################################################################################

sub cal_year {

	my ($_year) = @_;
	
	my $year = {
	
		year     => $_year,
		
		quarters => [map {cal_quarter ($_year, $_)} (1 .. 4)],
	
	};
	
	$year -> {lines} = [map {@{$_ -> {lines}}} @{$year -> {quarters}}];
	
	return $year;
	
}

1;