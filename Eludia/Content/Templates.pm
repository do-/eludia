################################################################################

sub interpolate {

	my $template = $_[0];

	my $result = '';

	my $code = "use utf8; \$result = <<EOINTERPOLATION\n$template\nEOINTERPOLATION";

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
			Encode::from_to ($_, 'windows-1251', 'utf-8');
			s{\\}{\\\\}g;
			s{\@([^\{])}{\\\@$1}g;
			s{windows-1251}{utf-8}g;
			$template .= $_;
		}

	}

	close (T);
		
	return $template;

}

################################################################################

sub adjust_template_filename {
	
	my ($file_name ) = @_;
	
	return $file_name if !$conf -> {report_date_in_filename};
		
	my $generation_date = sprintf ("%04d-%02d-%02d_%02d-%02d", Date::Calc::Today_and_Now);
	my ($name, @extensions) = split /\./, $file_name;
	$file_name = join '.', ($name . "_($generation_date)", @extensions);
	
	return $file_name;
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
	
	$file_name = Encode::encode ("windows-1251", $file_name);
	
	$file_name =~ y{¨¸}{Åå};
	$file_name =~ s{[^0-9A-za-zÀ-ßà-ÿ\.]+}{_}g;

	unless ($options -> {skip_headers}) {

		gzip_if_it_is_needed (\$result);

		$file_name = adjust_template_filename ($file_name);

		$r -> header_out ('Content-Disposition' => "attachment;filename=$file_name");

		$r -> send_http_header ('application/octet-stream');

	}

	$r -> print (Encode::encode_utf8($result));

	$_REQUEST {__response_sent} = 1;
	
	return $result;

}

1;
