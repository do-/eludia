################################################################################

sub delete_file {

	unlink $r -> document_root . $_[0];

}

################################################################################

sub get_filehandle {

	return ref $apr eq 'Apache2::Request' ? $apr -> upload ($_[0]) -> upload_fh : $apr -> upload ($_[0]) -> fh;

}

################################################################################

sub download_file_header {

	my ($options) = @_;

	set_cookie (
		-name => 'download_salt',
		-value => $_REQUEST {__salt},
		-path => '/'
	) if $_REQUEST {__salt};

	$r -> status (200);

	$options -> {file_name} =~ s{.*\\}{};

	my $type =
		$options -> {charset} ? $options -> {type} . '; charset=' . $options -> {charset} :
		$options -> {type};

	$type ||= 'application/octet-stream';

	my $path = $r -> document_root . $options -> {path};

	my $start = 0;

	my $content_length = $options -> {size};

	if (!$content_length && $options -> {path}) {

		$content_length = -s $r -> document_root . $options -> {path};

	}

	my $range_header = $r -> headers_in -> {"Range"};

	if ($range_header =~ /bytes=(\d+)/) {
		$start = $1;
		my $finish = $content_length - 1;
		$r -> headers_out -> {'Content-Range'} = "bytes $start-$finish/$content_length";
		$content_length -= $start;
	}

	$r -> content_type ($type);
	$options -> {file_name} =~ s/\?/_/g unless ($ENV {HTTP_USER_AGENT} =~ /MSIE 7/);

	my $filename = '=' . $options -> {file_name};

	if ($i18n -> {_charset} eq 'UTF-8' || !($ENV {HTTP_USER_AGENT} =~ /MSIE/) || $ENV {HTTP_USER_AGENT} =~ /MSIE (\d+)/ && $1 > 9) {

		$options -> {file_name} = decode ($i18n -> {_charset}, $options -> {file_name})
			unless Encode::is_utf8 ($options -> {file_name});

		$filename = "*=UTF-8''" . uri_escape (encode ('UTF-8', $options -> {file_name}));
	}

	$options -> {no_force_download} or $r -> headers_out -> {'Content-Disposition'} =
		($options -> {inline} ? 'inline' : 'attachment')
		. ';filename'
		. $filename;


	if ($content_length > 0) {
		$r -> headers_out -> {'Content-Length'} = $content_length;
		$r -> headers_out -> {'Accept-Ranges'} = 'bytes';
	}

	delete $r -> headers_out -> {'Content-Encoding'};

	$r -> headers_out -> {'P3P'} = 'CP="IDC DSP COR ADM DEVi TAIi PSA PSD IVAi IVDi CONi HIS OUR IND CNT"';

	send_http_header ();

	$_REQUEST {__response_sent} = 1;

	return $start;

}

################################################################################

sub download_file {

	my ($options) = @_;

	my $path = $r -> document_root . $options -> {path};

	-f $path or $path = $options -> {path};

	-f $path or die "File not found: $path\n";

	$_REQUEST {__out_html_time} = time;

	my $start = download_file_header (@_);

	if (MP2) {
		$r -> sendfile ($path, $start);
	} else {
		open (F, $path) or die ("Can't open file $path: $!");
		seek (F, $start, 0);
		$r -> send_fd (F);
		close F;
	}

	unlink $path if $options -> {'delete'};

}

################################################################################

sub upload_files {

	my ($options) = @_;

	my @nos = ();

	foreach my $k (keys %_REQUEST) {

		$k =~ /^_$options->{name}_(\d+)$/ or next;

		$_REQUEST {$k} or next;

		push @nos, $1;

	}

	my @result = ();

	my $name = $options -> {name};

	foreach my $no (sort {$a <=> $b} @nos) {

		$options -> {name} = "${name}_${no}";

		my $is_multiple_file_field = 1 < 0 + @{$_REQUEST {"_" . $options -> {name} . "[]"}};

		if ($is_multiple_file_field) {

			my $files = upload_file_multiple ($options);

			push @result, @$files;

			next;
		}

		push @result, upload_file ($options);

	}

	return \@result;

}

################################################################################

sub upload_file_multiple {

	my ($options) = @_;

	my $uploads = $apr -> upload_multiple ('_' . $options -> {name});

	$uploads or return undef;

	my @files;
	foreach my $upload (@$uploads) {

		$options -> {upload} = $upload;

		push @files, upload_file ($options);
	}

	delete $options -> {upload};

	return \@files;
}

################################################################################

sub upload_file {

	my ($options) = @_;

	my $is_multiple_file_field = !$options -> {upload}
		&& 1 < 0 + @{$_REQUEST {"_" . $options -> {name} . "[]"}};


	return undef
		if $is_multiple_file_field;

	my $upload = $options -> {upload} || $apr -> upload ('_' . $options -> {name});

	$upload or return undef;

	my ($fh, $filename, $file_size, $file_type) = upload_file_dimensions ($upload);

	unless ($file_size > 0) {

		die "#_$$options{name}#: $i18n->{empty_file}" if $filename;

		return undef;
	}

	my ($path, $real_path) = upload_path ($filename, $options);

	open (OUT, ">$real_path") or die "Can't write to $real_path: $!";
	binmode OUT;

	my $buffer = '';
	my $file_length = 0;
	while (my $bytesread = read ($fh, $buffer, 1024)) {
		$file_length += $bytesread;
		print OUT $buffer;
	}
	close (OUT);

	$filename =~ s{.*\\}{};

	return {
		file_name => $filename,
		size      => $file_size,
		type      => $file_type,
		path      => $path,
		real_path => $real_path,
	}

}

################################################################################

sub upload_path {

	my ($filename, $options) = @_;

	my ($y, $m, $d) = split /-/, sprintf ('%04d-%02d-%02d', Date::Calc::Today);

	$options -> {dir} ||= 'upload/images';

	my $dir = $preconf -> {_} -> {docroot} . "/i/$$options{dir}";

	foreach my $subdir ('', $y, $m, $d) {

		$dir .= "/$subdir" if $subdir;

		-d $dir or mkdir $dir;

	}

	my $ext = $filename =~ /[A-Za-z0-9]+$/ ? ".$&" : '';

	my $path = "/i/$$options{dir}/$y/$m/$d/" . time . '-' . (++ $_REQUEST {__files_cnt}) . "-$$" . $ext;

	return ($path, $preconf -> {_} -> {docroot} . $path);

}

1;