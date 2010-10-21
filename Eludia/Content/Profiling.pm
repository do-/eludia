################################################################################

sub __profile_in {

	ref $preconf -> {core_debug_profiling} eq HASH or $preconf -> {core_debug_profiling} = {

		in  => sub {},

		out => sub {

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

		},

	};

	my ($type, $options) = @_;

	$options -> {__time}  = time ();
	$options -> {__type}  = $type;

	push @_PROFILING_STACK, $options;

	$options -> {__level} = @_PROFILING_STACK - 1;

	&{$preconf -> {core_debug_profiling} -> {in}} ($options);

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

		&{$preconf -> {core_debug_profiling} -> {out}} ($old_options, $new_options);
		
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

################################################################################

sub __log_request_profilinig {

	my ($request_time) = @_;

	return unless ($preconf -> {core_debug_profiling} > 2 && $model_update -> {core_ok});

	my $c = $r -> connection; 

	$_REQUEST {_id_request_log} = sql_do_insert ($conf -> {systables} -> {__request_benchmarks}, {
		id_user	=> $_USER -> {id}, 
		ip	=> $ENV {REMOTE_ADDR}, 
		ip_fw	=> $ENV {HTTP_X_FORWARDED_FOR},
		fake	=> 0,
		type	=> $_REQUEST {type},
		mac	=> get_mac (),
		request_time	=> int ($request_time),
		connection_id	=> $c -> id (),
		connection_no	=> $c -> keepalives (),
	});
	
	my $request_benchmarks_table = sql_table_name ($conf -> {systables} -> {__request_benchmarks});

	sql_do ("UPDATE $request_benchmarks_table SET params = ? WHERE id = ?",
		Data::Dumper -> Dump ([\%_REQUEST], ['_REQUEST']), $_REQUEST {_id_request_log}); 

}

################################################################################
	
sub __log_request_finish_profilinig {

	my ($options) = @_;

	return 
		unless ($preconf -> {core_debug_profiling} > 2 && $model_update -> {core_ok}); 

	my $time = time;

	my $request_benchmarks_table = sql_table_name ($conf -> {systables} -> {__request_benchmarks});

	sql_do ("UPDATE $request_benchmarks_table SET application_time = ?, sql_time = ?, response_time = ?, bytes_sent = ?, is_gzipped = ? WHERE id = ?",
		int ($options -> {application_time}), 
		int ($options -> {sql_time}), 
		$options -> {out_html_time} ? int (1000 * (time - $options -> {out_html_time})) : 0, 
		$r -> bytes_sent,
		$options -> {is_gzipped},		 
		$options -> {id_request_log},
	);

}

1;