################################################################################

sub interpolate {

	my $template = $_[0];

	my $result = '';

	my $code = "\$result = <<EOINTERPOLATION\n$template\nEOINTERPOLATION";

	eval $code;

	$result .= $@;

	warn $@ if $@;

	return $result;

}

################################################################################

sub load_template {

	my ($template_name, $file_name, $options) = @_;
	
	$template_name .= '.htm' unless $template_name =~ /\.\w{2,4}$/;

	my $fn;
	
	my @dirs = map {"$_/templates"} ((map {"$_/Presentation"} _INC ()), $r -> document_root);
	
	foreach my $dir (@dirs) {
	
		my $f = "$dir/$template_name";
		
		-f $f or next;
		
		$fn = $f;
		
		last;
	
	}
	
	$fn or die "$template_name not found in " . (join ', ', @dirs) . "\n";
		
	my $template = '';
	
	open (T, $fn) or die ("Can't open $fn: $!\n");
	
	binmode T;
	
	if ($template_name =~ /\.pm$/) {

		while (<T>) {
			$template .= $_;
		}

	}
	else {

		while (<T>) {
			s{\\}{\\\\}g;
			s{\@([^\{])}{\\\@$1}g;
			$template .= $_;
		}

	}

	close (T);
	
	return $template;

}

################################################################################

sub fill_in_template {

	return if $_REQUEST {__response_sent};

	my ($template_name, $file_name, $options) = @_;
	
	$options -> {no_print} ||= $_REQUEST {no_print};
	
	my $template = load_template (@_);

	my $result = interpolate ($template);
	
	$result =~ s{\n}{\r\n}gsm;
	
	return $result if ($options -> {no_print});	

	$r -> status (200);
	
	unless ($options -> {skip_headers}) {
	
		gzip_if_it_is_needed ($result);
	
		$r -> header_out ('Content-Disposition' => "attachment;filename=$file_name");

		$r -> send_http_header ('application/octet-stream');

	}
	
	$r -> print ($result);

	$_REQUEST {__response_sent} = 1;
	
	return $result;

}

1;