################################################################################

sub __profile_print_tree {

	my ($old_options, $new_options) = @_;
	
	my $now = $new_options -> {__time};

	my ($sec, $min, $hour, $day, $mon, $year) = localtime ($now);
				
	my $message = sprintf ("[%04d-%02d-%02d %02d:%02d:%02d:%03d $$] ", $year + 1900, $mon + 1, $day, $hour, $min, $sec, int (1000 * ($now - int $now)));
	
	$message .= '       ' x $old_options -> {__level};
	
	$message .= sprintf ('%6.1f ms ', $new_options -> {__duration});

	$message .= '       ' x (7 - $old_options -> {__level});

	$message .= sprintf ("%-30s ", $old_options -> {__type});
				
	if ($new_options -> {__type} ne $old_options -> {__type}) {
	
		$message .= '[ABORT]';
	
	}
	else {

		my $comment = $new_options -> {label} || $old_options -> {label};
		
		$comment =~ s{\s+}{ }gsm;

		$message .= $comment;

	}
	
	$message .= "\n";

	warn $message;

}

################################################################################

sub __profile_in {

	my ($type, $options) = @_;

	$options -> {__time}  = time ();
	$options -> {__type}  = $type;

	push @_PROFILING_STACK, $options;

	$options -> {__level} = @_PROFILING_STACK - 1;
		
	__profile_handle_event ($type, 0, $options);

}

################################################################################

sub __profile_handle_event {

	my $type = shift;
	my $kind = shift;
	
	ref $preconf -> {core_debug_profiling} eq HASH or $preconf -> {core_debug_profiling} = {};
	
	my $core_debug_profiling = $preconf -> {core_debug_profiling};

	$core_debug_profiling -> {''} ||= ['', 'print_tree'];

	my $type_config;
	
	my $type_verbatim = $type;

	foreach (1 .. 10) {

		$type_config = $core_debug_profiling -> {$type};

		if (!$type_config) {
		
			$type =~ s{\.?\w+$}{};
			
			next;
		
		}

		$core_debug_profiling -> {$type_verbatim} ||= $type_config;

	}
	
	my $name = $type_config -> [$kind] or return;
	
	eval {
	
		&{"__profile_$name"} (@_);
	
	};
	
	warn $@ if $@;

}

################################################################################

sub __profile_out {

	my ($type, $new_options) = @_;

	$new_options -> {__time} = time ();
	
	@_PROFILING_STACK > 0 or warn "Profiling skewed: stack is empty\n";
	
	while (@_PROFILING_STACK) {
	
		my $old_options = pop @_PROFILING_STACK;

		$new_options -> {__type}     = $type;
		
		$new_options -> {__duration} = 1000 * ($new_options -> {__time} - $old_options -> {__time});
				
		__profile_handle_event ($type, 1, $old_options, $new_options);
		
		last if $old_options -> {__type} eq $type;
	
	}

}

################################################################################

sub __log_profilinig {

	my $now = time ();
	
	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime ($now);
	$year += 1900;
	$mon ++; 

	printf STDERR "[%04d-%02d-%02d %02d:%02d:%02d:%03d $$] %7.2f ms %s\n", 
		$year,
		$mon,
		$mday,
		$hour,
		$min,
		$sec,
		int (1000 * ($now - int $now)),
		1000 * ($now - $_[0]), 
		$_[1] 
		
		if $preconf -> {core_debug_profiling} > 0 && !$ENV {ELUDIA_SILENT};
	
	return $now;

}

1;