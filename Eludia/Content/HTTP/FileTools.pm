################################################################################

sub print_as_data_uri {

	my ($path) = @_;	

	open (FILE, $path) or die "$!";

	binmode FILE;

	my $buf;
	
	my $is_virgin = 1;

	while (read (FILE, $buf, 60*57)) {
	
		if ($is_virgin) {
			print 'image/';
			print $buf =~ /^GIF/ ? 'gif' : $buf =~ /^.PNG/ ? 'png' : 'jpeg';
			print ';base64,';
		}

		print MIME::Base64::encode_base64 ($buf, '');
		
		$is_virgin = 0;

	}	

	close FILE;

}

################################################################################

sub download_file_header {

	my ($options) = @_;	

	$r -> status (200);

	$options -> {file_name} =~ s{.*\\}{};
		
	my $type = 
		$options -> {charset} ? $options -> {type} . '; charset=' . $options -> {charset} :
		$options -> {type};

	$type ||= 'application/octet-stream';

	my $path = $options -> {path};
	
	my $start = 0;
	
	my $content_length = $options -> {size};
	
	if (!$content_length && $options -> {path}) {
	
		$content_length = -s $options -> {path};
	
	}
		
	my $range_header = $r -> headers_in -> {"Range"};

	if ($range_header =~ /bytes=(\d+)/) {
		$start = $1;
		my $finish = $content_length - 1;
		$r -> headers_out -> {'Content-Range'} = "bytes $start-$finish/$content_length";
		$content_length -= $start;
	}

	$r -> content_type ($type);
	
	if ($options -> {file_name} && !$options -> {no_force_download}) {
		$options -> {file_name} =~ s/\?/_/g unless ($ENV {HTTP_USER_AGENT} =~ /MSIE 7/);
		$r -> headers_out -> {'Content-Disposition'} = "attachment;filename=" . uri_escape ($options -> {file_name});
	}

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

	my $path = $options -> {path};
	
	-f $path or die "File not found: $path\n";

	my $start = download_file_header (@_);
	
	if (MP2) {
		$r -> sendfile ($path, $start);
	} else {
		open (F, $path) or die ("Can't open file $path: $!");
		seek (F, $start, 0);
		$r -> send_fd (F);
		close F;
	}
	
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
	
		push @result, upload_file ($options);
	
	}
	
	return \@result;

}

################################################################################

sub upload_file {
	
	my ($options) = @_;
	
	my $upload = $apr -> upload ('_' . $options -> {name});
	
	$upload or return undef;

	my ($fh, $filename, $file_size, $file_type) = upload_file_dimensions ($upload);
	
	$file_size > 0 or return undef;
	
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

	my $dir = $r -> document_root . "/i/$$options{dir}";

	foreach my $subdir ('', $y, $m, $d) {

		$dir .= "/$subdir" if $subdir;

		-d $dir or mkdir $dir;

	}

	$filename =~ /[A-Za-z0-9]+$/;
	
	my $path = "/i/$$options{dir}/$y/$m/$d/" . time . '-' . (++ $_REQUEST {__files_cnt}) . "-$$.$&";
	
	return ($path, $r -> document_root . $path);

}

1;