sub draw_form_field_dir {

	require File::Find;
	
	my ($options, $data) = @_;

	$options -> {width}  ||= 800;
	$options -> {height} ||= 100;
	
	$options -> {name}   ||= 'dir';
	$options -> {$options -> {name}} ||= $_REQUEST {type} . '/' . $data -> {id};
	
	my $root = $r -> document_root . '/i/upload/dav_';
	
	my $ro_dir = $root . 'ro/' . $options -> {$options -> {name}};
	my $rw_dir = $root . 'rw/' . $options -> {$options -> {name}};

	($options -> {url}) = split /\//, lc $r -> protocol;
	$options -> {url} .= '://';
	$options -> {url} .= $ENV {HTTP_HOST};
	$options -> {url} .= $_REQUEST {__uri};
	$options -> {url} .= 'i/upload/dav_';

	if ($_REQUEST {__read_only}) {
		
		my $ro_dir1 = $ro_dir;
		$ro_dir1 =~ s{/\w+/?$}{};

		unless (-d $ro_dir1) {
			mkdir $ro_dir1;
			chmod 0777, $ro_dir1;
		}
	
		if (-d $rw_dir) {
		
			finddepth (sub {-d $File::Find::name ? rmdir $File::Find::name : unlink $File::Find::name}, $ro_dir);			
			move ($rw_dir, $ro_dir);
		
		}
		elsif (!-d $ro_dir) {
		
			mkdir $ro_dir;
			chmod 0777, $ro_dir;
		
		}		
	
		$options -> {url} .= 'ro/';

	}
	else {
	
		my $rw_dir1 = $rw_dir;
		$rw_dir1 =~ s{/\w+/?$}{};
		unless (-d $rw_dir1) {
			mkdir $rw_dir1;
			chmod 0777, $rw_dir1;
		}

		if (-d $ro_dir) {
		
			finddepth (sub {-d $File::Find::name ? rmdir $File::Find::name : unlink $File::Find::name}, $rw_dir);
			move ($ro_dir, $rw_dir);
		
		}
		elsif (!-d $rw_dir) {
		
			mkdir $rw_dir;
			chmod 0777, $rw_dir;

		}
	
		$options -> {url} .= 'rw/';

	}

	$options -> {url} .= $options -> {$options -> {name}};

	return $_SKIN -> draw_form_field_dir (@_);

}

1;