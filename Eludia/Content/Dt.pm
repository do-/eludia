################################################################################

sub dt_y_m_d {

	$_[0] =~ /^(\d+)\D(\d+)\D(\d+)/ or return ();
		
	return $1 > 1900 ? ($1, $2, $3) : ($3, $2, $1);

}

################################################################################

sub dt_iso {

	my @ymd = @_;
	
	@ymd > 0 or @ymd = (time);
	
	@ymd > 1 or @ymd = split /\D/, $ymd [0];
		
	if (@ymd <= 2) {

		my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime ($ymd [0]);
		
		splice @ymd, 0, 1, ($year + 1900, $mon + 1, $mday, $hour, $min, $sec);
		
		if (@ymd == 7) {
		
			my $l = length $ymd [-1];
			
			if ($l < 6) {
			
				$ymd [-1] .= '0' x (6 - $l);
			
			}
			elsif ($l > 6) {
			
				$ymd [-1] = substr $ymd [-1], 0, 6;
				
			}			
		
		}
		
	}

	my $f = 
		@ymd == 3 ? '%04d-%02d-%02d' :
		@ymd == 6 ? '%04d-%02d-%02d %02d:%02d:%02d' :
		@ymd == 7 ? '%04d-%02d-%02d %02d:%02d:%02d.%06d' :
		die "Wrong dt_iso params: " . Dumper (\@_);
	
	if ($ymd [0] <= 31) {
		(my $y = $ymd [2]) > 31 or die "Wrong dt_iso params: " . Dumper (\@_);
		$ymd [2] = $ymd [0];
		$ymd [0] = $y;
	}
		
	return sprintf ($f, @ymd);

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

1;