use Net::SMTP;

################################################################################

sub send_mail {

	my ($options) = @_;
	
	warn "send_mail: " . Dumper ($options);
	
	my $to = $options -> {to};
	
		##### Multiple recipients
	
	if (ref $to eq ARRAY) {
		foreach (@$to) {
			$options -> {to} = $_;
			send_mail ($options);
			delete $options -> {href};
		}
		
		return;
	
	}
	
		##### To address
		
	if (!ref $to && $to > 0) {
		$to = sql_select_hash ("SELECT label, mail FROM $conf->{systables}->{users} WHERE id = ?", $to);
	}

	my $original_to;
	if ($preconf -> {mail} -> {to}) {
		$original_to = '' . Dumper ($to);
		$to = $preconf -> {mail} -> {to};
	}

	my $real_to = $to;	
	if (ref $to eq HASH) {
		$real_to = $to -> {mail};
		$to = encode_mail_header ($to -> {label}, $options -> {header_charset}) . "<$real_to>";
	}
	
	unless ($real_to =~ /\@/) {
		warn "send_mail: INVALID MAIL ADDRESS '$real_to'\n";
		return;
	}
	
		##### From address

	$options -> {from} ||= $preconf -> {mail} -> {from};
	my $from = $options -> {from};
	if (ref $from eq HASH) {
		$from -> {mail} ||= $from -> {address};
		$from = encode_mail_header ($from -> {label}, $options -> {header_charset}) . "<" . $from -> {mail} . ">";
	}

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
	
	my $text = encode_base64 ($options -> {text} . "\n" . $original_to);
	
	unless ($^O eq 'MSWin32') {
		defined (my $child_pid = fork) or die "Cannot fork: $!\n";
		return $child_pid if $child_pid;
	}
		
		##### connecting...

	my $repeat = 10;
	
	my $smtp = undef;
	
	while ($repeat) {

		$repeat--;

		$smtp = Net::SMTP -> new ($preconf -> {mail} -> {host}, %{$preconf -> {mail} -> {options}});

		$smtp or next;
		
		if ($preconf -> {mail} -> {user}) {
		
			require Authen::SASL;
		
			$smtp -> auth ($preconf -> {mail} -> {user}, $preconf -> {mail} -> {password}) or die "SMTP AUTH error: " . $smtp -> code . ' ' . $smtp -> message;
			
		}
		
		last if $smtp;


	}	

	unless (defined $smtp) {
		warn "Can't connect to $preconf->{mail}->{host}\n";
		return;
	}

#	$smtp -> mail ($ENV{USER});
	$smtp -> mail ($options -> {from} -> {address});
	$smtp -> to ($real_to);
	$smtp -> data ();

		##### sending main message

	$smtp -> datasend (<<EOT);
From: $from
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
			while (read (FILE, $buf, 60*57)) {
				$smtp -> datasend (encode_base64 ($buf));
			}
			close (FILE);

		}

	}

	$smtp -> datasend (<<EOT);

--0__=4CBBE500DFA7329E8f9e8a93df938690918c4CBBE500DFA7329E--
EOT

	$smtp -> dataend ();
	$smtp -> quit;
		
	unless ($^O eq 'MSWin32') {
		CORE::exit (0);
	}

}

################################################################################

sub encode_mail_header {

	my ($s, $charset) = @_;

	$charset ||= 'windows-1251';
	
	if ($charset eq 'windows-1251') {
		$s =~ y{ÀÁÂÃÄÅ¨ÆÇÈÉÊËÌÍÎÏĞÑÒÓÔÕÖ×ØÙÚÛÜİŞßàáâãäå¸æçèéêëìíîïğñòóôõö÷øùúûüışÿ}{áâ÷çäå³öúéêëìíîïğòóôõæèãşûıÿùøüàñÁÂ×ÇÄÅ£ÖÚÉÊËÌÍÎÏĞÒÓÔÕÆÈÃŞÛİßÙØÜÀÑ};
		$charset = 'koi8-r';
	}

	$s = '=?' . $charset . '?B?' . encode_base64 ($s) . '?=';
	$s =~ s{[\n\r]}{}g;
	return $s;	
	
}

1;
