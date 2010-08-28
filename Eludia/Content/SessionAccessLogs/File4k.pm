################################################################################

sub session_access_log_directory () {

	"$preconf->{_}->{docroot}session_access_logs";

}

################################################################################

sub session_access_log_filename () {

	session_access_log_directory . "/$_REQUEST{sid}.4k";

}

################################################################################

sub session_access_logs_purge {
	
	my %session = ();
	
	my $directory = session_access_log_directory;

	opendir (DIR, $directory) or die "Can't opendir $directory:$!\n";

	while (my $file_name = readdir (DIR)) { 

		$file_name =~ /\.4k$/ and $session {$`} = \$directory;
		
	}
	
	closedir (DIR);
	
	sql_select_loop ("SELECT id FROM $conf->{systables}->{sessions}", sub {
	
		delete $session {$i -> {id}};
		
	});
	
	foreach (keys %session) { eval {
	
		unlink "$directory/$_.4k";
		
	}}
	
}

################################################################################

sub session_access_log_get {
	
	my $buf;
	
	open (F, session_access_log_filename) or return undef;
	
	seek (F, ($_[0] - 1) << 12, 0);
	
	read (F, $buf, 4096);

	close (F);
	
	return $buf =~ / / ? $` : $buf;

}

################################################################################

sub session_access_log_append {

	my ($href) = @_;

	my $filename = session_access_log_filename;
	
	open (F, ">>$filename") or die "Can't append to $filename:$!";
	
	print F $href;
	
	my $no = (tell F) >> 12;
	
	close (F);
	
	return $no;

}

################################################################################

sub session_access_log_set {

	my ($href) = @_;

	$href =~ s{^https?\://}{};
	
	if ($href =~ /[\/\?]/) {
		
		$href = $& . $';
	
	}
		
	foreach my $key (qw(
		_salt
		salt
		sid
		id___query
		__next_query_string
	)) {
	
		$href =~ s{\&?${key}=[\d\.]+}{}g;
	
	}
	
	$href = substr $href, 0, 4095;

	$href .= (' ' x (4095 - length $href));
	
	$href .= "\015";
	
	my $filename = session_access_log_filename;
	
	-f $filename or return session_access_log_append ($href);
	
	my $size = -s $filename;
	
	if ($size % 4096) {
	
		unlink $filename;
		
		return session_access_log_append ($href);		
	
	}
	
	my $max = $size >> 12;
	
	my $min = $max > 16 ? $max - 16 : 1;
	
	my $n;
	
	my $buf;
	
	open (F, "$filename") or die "Can't read $filename:$!";

	for (my $i = $max; $i >= $min; $i --) {
	
		seek (F, ($i - 1) << 12, 0);

		read (F, $buf, 4096);
		
		$buf eq $href or next;
		
		$n = $i;
		
		last;
	
	}
	
	close (F);
	
	return $n ? $n : session_access_log_append ($href);

}

1;