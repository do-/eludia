no warnings;

################################################################################

sub current_package {
	
	my ($_package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller (1);

	if ($subroutine =~ /^(\w+)\:\:/) {
	
		return $1;
	
	}
	else {
	
		return __PACKAGE__;
	
	}
	
}

################################################################################

sub require_content ($) {

	require_fresh ("${_PACKAGE}Content::$_[0]");

}

################################################################################

sub require_config {

	__profile_in ('require.config');
	
	require_fresh ($_PACKAGE . 'Config');
		
	fill_in ();

	__profile_out ('require.config');

}

################################################################################

sub get_item_of_ ($) {

	$_[0] or die "get_item_of_: empty type";
	
	require_content ($_[0]);
	
	return call_for_role ('get_item_of_' . $_[0]);
	
}

################################################################################

sub require_model {

	__profile_in ('require.model');

	my $core_was_ok = $model_update -> {core_ok};

	sql_assert_core_tables ();
	
	our $DB_MODEL ||= {

		default_columns => {
			id   => {TYPE_NAME  => 'int', _EXTRA => 'auto_increment', _PK => 1},
			fake => {TYPE_NAME  => 'int'},
		},

	};
		
	my %tables = ();

	if (!exists $DB_MODEL -> {tables}) {

		tie %tables, Eludia::Tie::FileDumpHash, {conf => $conf, path => \&_INC, package => current_package ()};

		$DB_MODEL -> {tables} = \%tables;
		
	}

	$core_was_ok or require_scripts ();
	
	__profile_out ('require.model');

}

################################################################################

sub list_of_files_in_the_directory ($) {

	opendir (DIR, $_[0]) or die "Can't opendir $_[0]: $!";
	
	my @file_names = readdir (DIR);
	
	closedir DIR;
	
	return @file_names;

}

################################################################################

sub require_model_scripts {

	my ($dir) = @_;
	
	$dir .= '/Model';
	
	__profile_in ("require.scripts.model" => {label => $dir}); 

	foreach my $file_name (list_of_files_in_the_directory $dir) {
				
		$file_name =~ /\.pm$/ or next;
			
		my $name = $`;		
		
		__profile_in ("require.scripts.model.$name"); 

		$model_update -> assert (
											
			default_columns => $DB_MODEL -> {default_columns},
						
			tables => {$name => $DB_MODEL -> {tables} -> {$name}},

		);

		__profile_out ("require.scripts.model.$name"); 

	}			

	__profile_out ("require.scripts.model"); 

}

################################################################################

sub _file_md5 {

	my ($path) = @_;

	open (my $fh, $path) or die "Can't open $path: $!\n";

    	binmode ($fh);

    	my $r = Digest::MD5 -> new -> addfile ($fh) -> hexdigest;

	return $r;

}

################################################################################

sub is_update_script_shot {

	my ($fn, $dir, $shot_dir) = @_;

	my @suspects = grep {0 == substr ($_, $fn)} list_of_files_in_the_directory $shot_dir;

	@suspects > 0 or return ();
	
	my $size = -s "$dir/$fn";
	
	@suspects = grep {$size == -s "$shot_dir/$_"} @suspects;

	@suspects > 0 or return ();
	
	my $md5 = _file_md5 ("$dir/$fn");
	
	return reverse sort grep {$md5 eq _file_md5 ("$shot_dir/$_")} @suspects;

}

################################################################################

sub require_update_scripts {

	my ($dir) = @_; $dir =~ y{\\}{/};
	
	$dir .= '/Updates';	
	
	-d $dir or return;
	
	__profile_in ("require.scripts.update" => {label => $dir}); 

	my $shot_dir = $dir . '/_shot';
	
	-d $shot_dir or mkdir $shot_dir or die "Can't create $shot_dir: $!\n";
	
	foreach my $fn (list_of_files_in_the_directory $dir) {
	
		$fn =~ /\.pl$/ or next;
		
		my $name = $`;

		my $path = "$dir/$fn";
	
		my @previous = is_update_script_shot ($fn, $dir, $shot_dir);

		if (@previous) {
		
			warn "$fn was already shot: " . (join ', ', @previous) . "; will delete it\n";
			
			unlink $path;
		
		}
		else {
		
			__profile_in ("require.scripts.update.$name"); 
			
			my $code = "";

			open (I, $path) or die "Can't read $path: $!\n";
			$code .= $_ while (<I>);	
			close (I);

			eval $code; 

			die $@ if $@;			
			
			my $ts = localtime_to_iso (time); 
			
			$ts =~ s{\D+}{_}g;
			
			$fn =~ s{\.pl$}{\.$ts\.pl};
			
			File::Copy::move ($path, "$shot_dir/$fn");

			__profile_out ("require.scripts.update.$name"); 

		}

	}

	__profile_out ("require.scripts.update"); 

}

################################################################################

sub require_scripts {
	
	__profile_in ('require.scripts'); 
	
	foreach my $dir (grep {-d} _INC ()) {
	
		require_model_scripts  ($dir);
		
		require_update_scripts ($dir);
		
	}

	__profile_out ('require.scripts'); 
	
}

################################################################################

sub localtime_to_iso {

	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime ($_[0]);
	
	return sprintf ('%04d-%02d-%02d %02d:%02d:%02d', 1900 + $year, 1 + $mon, $mday, $hour, $min, $sec);
	
}

################################################################################

sub _INC {

	my $type_prefix = $_REQUEST {type} =~ /^(\w+?)_/ ? $1 : '';
	
	my %prefixes = ('*' => 1);

	my @prefixes = sort keys %prefixes;
	
	my $cache_key = join ',', @prefixes;
	
	my $cache = $preconf -> {_} -> {inc} ||= {};
	
	$cache -> {$cache_key} and return @{$cache -> {$cache_key}};
	
	my @result = ();
	
	foreach my $dir (reverse @$PACKAGE_ROOT) {

		my %result = ($dir => 1);

		if (-d ($dir . '/_')) {
	
			foreach my $prefix (@prefixes) {

				if ($prefix eq '*') {

					$result {$_} ||= 1 foreach grep {-d && !/\.$/} map {"${dir}/${_}"} list_of_files_in_the_directory $dir;

				}
				else {

					my $specific = "${dir}/_${prefix}";

					-d $specific and $result {$specific} ||= 1;

				}

			}
		
		}
		
		push @result, sort {length $b <=> length $a} keys %result;

	}

	$cache -> {$cache_key} = \@result;

	return @result;

}

################################################################################

sub require_fresh {

	my ($module_name) = @_;	

	__profile_in ('require.module' => {label => $module_name}); 

	my $local_file_name = $module_name;

	$local_file_name =~ s{(::)+}{\/}g;

	my $type = $';

	$local_file_name =~ s{^(.+?)\/}{\/};
	
	my $old_type = $_REQUEST {type};
	
	$_REQUEST {type} = $type     if $type ne 'menu';

	my @inc = _INC ();

	$_REQUEST {type} = $old_type;

	my @file_names = grep {-f} map {"${_}$local_file_name.pm"} @inc;

	my $is_need_reload_module;

	@file_names = map {
	
		my $last_recorded_time = $INC_FRESH_BY_PATH {$_};

		my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks) = stat ($_);
		
		my $last_modified_iso = localtime_to_iso ($mtime);

		$is_need_reload_module ||= $mtime > $last_recorded_time;

		{file_name => $_, mtime => $mtime, last_modified_iso => $last_modified_iso};

	} @file_names;

	unless ($is_need_reload_module) {
	
		__profile_out ('require.module');
		
		return;

	}

	foreach my $file (reverse @file_names) {
	
		__profile_in ('require.file'); 
			
		my ($file_name, $mtime, $last_modified_iso) = ($file -> {file_name}, $file -> {mtime}, $file -> {last_modified_iso});

		delete $INC_FRESH_BY_PATH {$file_name};

		if ($type eq 'menu') {

			(tied %{$DB_MODEL -> {tables}}) -> {cache} = {};

			require_scripts () if $db;

		}

		my $src = '';

		open (S, $file_name);

		while (my $line = <S>) {

$line = Encode::decode ($preconf -> {core_src_charset} ||= 'windows-1251', $line);

			$src .= $line;

			$line =~ /^sub (\w+)_$type \{ # / or next;

			my $sub   = $1;
			my $label = $';
			$label =~ s{[\r\n]+$}{}gsm;

			my $action = $sub =~ /^(do|validate)_/ ? $' : ''; 

			$_ACTIONS -> {_actions} -> {$type} -> {$action} = $label;

		}

		close (S);

		eval qq{# line 1 "$file_name"\n use utf8; $src \n; 1;\n};

		die "$module_name: " . $@ if $@;

		$INC_FRESH {$module_name} = $INC_FRESH_BY_PATH {$file_name} = $mtime;

		__profile_out ('require.file' => {label => "$file_name -> $last_modified_iso"});
	
	}
	
	__profile_out ('require.module'); 
        	
}

################################################################################

sub call_from_file {

	my ($path, $sub_name, @params) = @_;

	my @result;

	foreach my $try (0, 1) {

		eval {@result = &$sub_name (@params)};

		$@ =~ /^Undefined subroutine/ or last;

 		require $path;
 
		delete $INC {$path};
 
	}

	return wantarray ? @result : $result [0];

}

################################################################################

sub call_for_role {

	my $sub_name = shift;

	my $time;
	
	if ($preconf -> {core_debug_profiling}) {
		$time = time;
	}

	my $role = $_USER ? $_USER -> {role} : '';	

	my $full_sub_name = $sub_name . '_for_' . $role;

	my $default_sub_name = $sub_name;
	$default_sub_name =~ s{_$_REQUEST{type}$}{_DEFAULT};

	my $name_to_call = 
		exists $$_PACKAGE {$full_sub_name}    ? $full_sub_name :
		exists $$_PACKAGE {$sub_name}         ? $sub_name : 
		exists $$_PACKAGE {$default_sub_name} ? $default_sub_name : 
		undef;

	if ($name_to_call) {
	
		__profile_in ("call.$name_to_call");
		
		my $result = &$name_to_call (@_);
	
		__profile_out ("call.$name_to_call");
		
		return $result;

	}
	else {
		
		$sub_name    =~ /^(valid|recalcul)ate_/	or $sub_name =~ /^(get|select)_menu$/
		
			or warn "call_for_role: callback procedure not found: \$sub_name = $sub_name, \$role = $role \n";
		
		return undef;
		
	}

}

################################################################################

sub attach_globals {

	my ($from, $to, @what) = @_;
	
	$from =~ /::$/ or $from .= '::';
	$to   =~ /::$/ or $to   .= '::';

	*{"${to}$_"} = *{"${from}$_"} foreach (@what);

}

1;
