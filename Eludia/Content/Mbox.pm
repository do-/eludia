################################################################################

sub mbox_path {

	my ($id_user) = @_;

	return "$preconf->{_}->{docroot}i/_mbox/by_user/$id_user";

}

################################################################################

sub js_im {

	my ($id_user, $code, $options) = @_;
	
	if (ref $id_user eq ARRAY) {
		
		foreach (@$id_user) {js_im ($_, $code, $options)}
		
		return;
	
	}
	
	$options -> {code} ||= $code;
	
	if ($options -> {session}) {
	
		$options -> {session} = Digest::MD5::md5_hex (sql_select_scalar ('SELECT id FROM sessions WHERE id_user = ?', $id_user));
	
	}
	
	if (ref $options -> {expires} eq ARRAY) {
	
		$options -> {expires} -> [$_] ||= 0 foreach (3 .. 5);
		
		$options -> {expires} = Date::Calc::Mktime (@{$options -> {expires}});
	
	}

	setup_json ();
	
	my $content = $_JSON -> encode ($options);
		
	$options -> {name} = Digest::MD5::md5_hex ($content . time () . $$) . '.json';
	
	my $mbox_path = mbox_path ($id_user);
	
	-d $mbox_path or mkdir $mbox_path;

	$options -> {path} = "$mbox_path/$options->{name}";
	
	open (F, ">$options->{path}") or die "Can't open $options->{path}:$!\n";
	
	print F $content;
	
	close (F);
	
	chmod 0777, $options->{path};
	
	mbox_refresh ($id_user, $options);

}

################################################################################

sub do_read__mbox {

	my $fn = mbox_path ($_USER -> {id}) . "/$_REQUEST{id}.json";

	open (F, $fn) or return out_html ({}, '{}');
	
	my $content = <F>;
	
	close (F);

	unlink $fn    or return out_html ({}, '{}');
	
	mbox_refresh ($_USER -> {id});

	out_html ({}, $content);
	
}

################################################################################

sub mbox_refresh {

	my ($id_user, $options) = @_;
	
	my $mbox_path = mbox_path ($id_user);
	
	-d $mbox_path or mkdir $mbox_path;
	
	my $fn = "$preconf->{_}->{docroot}/i/_mbox/$id_user.txt";
	
	open  (IDX, ">$fn") or die "Can't open $fn:$!\n";
	
	flock (IDX, LOCK_EX);
	
	opendir (DIR, $mbox_path) || die "can't opendir $mbox_path: $!";
	
	setup_json ();
	
	my $the_name;

	foreach my $name (readdir (DIR)) {
	
		$name =~ /\.json$/ or next;
		
		if ($name eq $options -> {name}) {
		
			$the_name = $name;
		
			next;
		
		}
		
		my $path = "$mbox_path/$name";
		
		open (F, $path) or die "Can't open $path:$!\n";
		
		my $content = $_JSON -> decode (<F>);
		
		close (F);
		
		if (
			0 == 1
		
			|| (exists $content -> {expires} && $content -> {expires} <  time ()                               )

			|| (exists $content -> {tag}     && $content -> {tag}     eq $options -> {tag}                     )
			
			|| (exists $content -> {session} && $content -> {session} ne Digest::MD5::md5_hex ($_REQUEST {sid}))
			
		) {
		
			unlink $path;
			
			next;
		
		}

		$the_name ||= $name;
	
	}
		
	closedir DIR; 
	
	$the_name =~ s{\.json$}{};

	print IDX $the_name if $the_name;
	
	flock (IDX, LOCK_UN);
	
	close (IDX);

}

1;