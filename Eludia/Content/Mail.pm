use Net::SMTPS;

################################################################################

sub __log {

	my $now = time;
	
	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime ($now);
	$year += 1900;
	$mon ++; 

	printf STDERR "send_mail [%04d-%02d-%02d %02d:%02d:%02d:%03d %5d] %5.1f ms %s\n", 
		$year,
		$mon,
		$mday,
		$hour,
		$min,
		$sec,
		int (1000 * ($now - int $now)),		
		$$,
		1000 * ($now - $_[0]), 
		$_[1]
	;

	return $now;

}

################################################################################

sub send_mail {

	my ($options) = @_;
	
	my $time = time;
	
	my $to = $options -> {to};
	
	ref $to eq ARRAY or $to = [$to];
	
	my $signature = ' [' . $options . ']: ';
	$signature   .= $options -> {subject};
	$signature   .= " / $options->{href}" if $options -> {href};

	$time = __log ($time, " $signature" . Dumper ($options));
	
	my @to_char = ();
	my @to_num  = ();
	
	foreach my $i (@$to) {
	
		if (!ref $i && $i =~ /^\-?[1-9]\d*$/) {
			push @to_num, $i;
		}
		else {
			push @to_char, $i;
		}
	
	}
	
	if (@to_num > 0) {
	
		my $ids = join ',', @to_num;
		
		sql_select_loop ("SELECT id, label, mail FROM $conf->{systables}->{users} WHERE id IN ($ids)", sub {
		
			$time = __log ($time, " $signature: $i->{id} -> $i->{mail}<$i->{label}>");
			push @to_char, $i;
		
		});
	
	}
	
	my @to = ();
	
	foreach my $i (@to_char) {

		ref $i eq HASH or $i = {mail => $i};

		if ($i -> {mail} eq '') {
			$time = __log ($time, " $signature: empty mail address for $i->{label}, skipping");
		}
		elsif ($i -> {mail} !~ /\@/) {
			$time = __log ($time, " $signature: invalid mail address ($i->{mail}) for $i->{label}, skipping");
		}
		else {
			push @to, encode_mail_address ($i, $options);
		}

	}
	
	if (@to == 0) {	
		$time = __log ($time, " $signature: no valid mail addresses found, returning");
		return;	
	}

	$time = __log ($time, " $signature: thus, our address list is " . join (', ', @to));

		##### Deferred delivery

	if ($preconf -> {mail} -> {defer} && !$options -> {no_defer}) {

		$options -> {no_defer} = 1;
		$options -> {to} = \@to;
		defer ('send_mail', [$options], {label => $signature});
		return;
	
	}
	
		##### From address

	$preconf -> {mail} -> {from} -> {mail} ||= $preconf -> {mail} -> {from} -> {address};
	$options -> {from}                     ||= $preconf -> {mail} -> {from};	
	$from                                    = encode_mail_address ($options -> {from}, $options);
	
		##### Message subject

	my $subject = encode_mail_header ($options -> {subject}, $options -> {header_charset});

		##### Message body
	
	$options -> {body_charset} ||= 'windows-1251';
	$options -> {content_type} ||= 'text/plain';
	
	if ($options -> {href}) {	
		my $server_name = $preconf -> {mail} -> {server_name} || $ENV{HTTP_HOST};
		$options -> {href} =~ /^http/ or $options -> {href} = ($server_name =~ /^http/ ? $server_name : "http://$server_name") . $options -> {href};
	}

	if ($options -> {template}) {
		our $DATA = $options -> {data} if $options -> {data};
		$DATA -> {href} = $options -> {href};
		$options -> {text} = fill_in_template ($options -> {template}, '', {no_print => 1});
		undef $DATA if $options -> {data};
	}
	elsif ($options -> {href}) {
		$options -> {href} = "<br><br><a href='$$options{href}'>$$options{href}</a>" if $options -> {content_type} eq 'text/html';
		$options -> {text} .= "\n\n" . $options -> {href};
	}
	
	my $text = encode_base64 (Encode::encode ($options -> {body_charset}, $options -> {text}) . "\n" . $original_to);
	
	my $is_child = 0;
	
	unless ($^O eq 'MSWin32' || $INC {'FCGI.pm'} || $_REQUEST {__skin} eq 'STDERR') {

		$SIG {'CHLD'} = "IGNORE";

		eval {$db -> disconnect};
	
		defined (my $child_pid = fork) or die "Cannot fork: $!\n";

		if ($child_pid) {
			sql_reconnect ();
			return $child_pid;
		}
		
		$is_child = 1;
		
	}
		
		##### connecting...

	my $repeat = 10;
	
	my $smtp = undef;
	
	$time = __log ($time, " $signature: last message before connecting...");

	while ($repeat) {

		$repeat--;

		$smtp = Net::SMTPS -> new ($preconf -> {mail} -> {host}, %{$preconf -> {mail} -> {options}});

		$smtp or next;
		
		if ($preconf -> {mail} -> {user}) {
		
			require Authen::SASL;
		
			$smtp -> auth ($preconf -> {mail} -> {user}, $preconf -> {mail} -> {password}) or die "SMTP AUTH error: " . $smtp -> code . ' ' . $smtp -> message;
			
		}
		
		last if $smtp;

	}	

	unless (defined $smtp) {	
	
		$time = __log ($time, " $signature: CAN'T CONNECT TO $preconf->{mail}->{host}! Giving up.");
		
		if ($is_child) {
			CORE::exit (0);
		}
		else {
			return;
		}
		
	}

	$time = __log ($time, " $signature: connected to $preconf->{mail}->{host}, ready to send mail");

	$smtp -> mail ($options -> {from} -> {mail});

	my @real_to = @to;

	if ($preconf -> {mail} -> {to}) {

		my $mail_to = $preconf -> {mail} -> {to};

		ref $mail_to eq ARRAY or $mail_to = [$mail_to];

		@real_to = map {ref $_ eq HASH ? ($_ -> {mail} || $_ -> {address}) : $_} @$mail_to;

	}
	
	foreach my $to (@real_to) {
			
		next if $smtp -> recipient ($to, {Notify => ['FAILURE', 'DELAY'], SkipBad => 0});
		
		$smtp -> quit;
		
		$SIG {__DIE__} = 'DEFAULT';
		
		die ("The mail address '$to' is rejected by the SMTP server $preconf->{mail}->{host}\n");
	
	}

	$smtp -> data ();

		##### sending main message
		
	$to = join ",\t", @to;

	$smtp -> datasend (<<EOT);
From: $from
Return-Path: $from
To: $to
Subject: $subject
Content-type: multipart/mixed;
	Boundary="0__=4CBBE500DFA7329E8f9e8a93df938690918c4CBBE500DFA7329E"
Content-Disposition: inline

--0__=4CBBE500DFA7329E8f9e8a93df938690918c4CBBE500DFA7329E
Content-Type: $$options{content_type}; charset="$$options{body_charset}"
Content-Transfer-Encoding: base64

$text
EOT

		##### sending attach

	$options -> {attach} = [$options -> {attach}] if ($options -> {attach} && ref $options -> {attach} ne ARRAY);

	foreach my $attach (@{$options -> {attach}}) {

		if (-f $attach -> {real_path}) {

			my $type = $attach -> {type};
			$type ||= 'application/octet-stream';

			my $fn   = $attach -> {file_name};
			$fn ||= $attach -> {real_path};
			$fn =~ s{.*[\\\/]}{};

			$smtp -> datasend (<<EOT);
--0__=4CBBE500DFA7329E8f9e8a93df938690918c4CBBE500DFA7329E
Content-type: $type;
	name="$fn"
Content-Disposition: attachment; filename="$fn"
Content-transfer-encoding: base64

EOT

			my $buf = '';
			open (FILE, $attach -> {real_path}) or die "Can't open $attach->{real_path}: $!";
			binmode (FILE);
			while (read (FILE, $buf, 60*57)) {
				$smtp -> datasend (encode_base64 ($buf));
			}
			close (FILE);

			if ($attach -> {delete_after_send}) {
			
				unlink $attach -> {real_path} || warn "Can't unlink $attach->{real_path}: $!\n";
				
			}

		}

	}

	$smtp -> datasend (<<EOT);

--0__=4CBBE500DFA7329E8f9e8a93df938690918c4CBBE500DFA7329E--
EOT

	$smtp -> dataend ();
	$smtp -> quit;

	$time = __log ($time, " $signature: done with sending mail");
		
	unless ($^O eq 'MSWin32' || $INC {'FCGI.pm'} || $_REQUEST {__skin} eq 'STDERR') {
		$db -> disconnect;
		CORE::exit (0);
	}

}

################################################################################

sub encode_mail_address {

	my ($s, $options) = @_;
	
	ref $s or return $s;
	
	return encode_mail_header ($s -> {label}, $options -> {header_charset}) . " <$s->{mail}>";

}

################################################################################

sub encode_mail_header {

	my ($s, $charset) = @_;

	$charset ||= 'windows-1251';
	
	if ($charset eq 'windows-1251') {
		$s =~ y{ÀÁÂÃÄÅ¨ÆÇÈÉÊËÌÍÎÏĞÑÒÓÔÕÖ×ØÙÚÛÜİŞßàáâãäå¸æçèéêëìíîïğñòóôõö÷øùúûüışÿ}{áâ÷çäå³öúéêëìíîïğòóôõæèãşûıÿùøüàñÁÂ×ÇÄÅ£ÖÚÉÊËÌÍÎÏĞÒÓÔÕÆÈÃŞÛİßÙØÜÀÑ};
		$charset = 'koi8-r';
	}

	$s = '=?' . $charset . '?B?' . encode_base64 (Encode::encode ($charset, $s)) . '?=';
	$s =~ s{[\n\r]}{}g;
	return $s;	
	
}

1;
