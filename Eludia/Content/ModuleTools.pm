no warnings;

################################################################################

sub require_content ($) {

	require_fresh ("Content/$_[0]");

}

################################################################################

sub require_config {

	__profile_in ('require.config');
	
	require_fresh ('Config');
		
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

		tie %tables, Eludia::Tie::FileDumpHash, {conf => $conf, path => \&_INC, package => __PACKAGE__};

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
		
	__profile_in ("require.scripts.model" => {label => $dir}); 

	my $tables = {};

	foreach my $dir (@_) {

		foreach my $file_name (list_of_files_in_the_directory $dir . '/Model') {

			$file_name =~ /\.pm$/ or next;

			$tables -> {$`} ||= $DB_MODEL -> {tables} -> {$`};

		}
	
	}
	
	$model_update -> assert (
											
		default_columns => $DB_MODEL -> {default_columns},
						
		tables => $tables,

	);	

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

		my $size = -s $path;

		my $md5 = _file_md5 ($path);
		
		my $yet = sql_select_hash ("SELECT * FROM $conf->{systables}->{__update_exec_log} WHERE name = ? AND size = ? AND md5 = ?", $name, $size, $md5);

		if ($yet) {
		
			if ($yet -> {is_ok}) {

				warn "$fn was already shot $yet->{dt_from}..$yet->{dt_to}, going to delete it\n";

				unlink $path;

			}
			else {
			
				die "$fn is known to fail at $yet->{dt_to} with the message $yet->{err}\n";
			
			}		
		
		}
		else {
		
			__profile_in ("require.scripts.update.$name"); 
			
			my $id_log = sql_do_insert ($conf -> {systables} -> {__update_exec_log} => {
				fake    => 0,
				name    => $name,
				size    => $size,
				md5     => $md5,
				dt_from => dt_iso (),
				is_ok   => 0,			
			});

			do $path;
			
			my $ts = dt_iso ();

			if (my $err = $@ || $!) {
			
				sql_do ("UPDATE $conf->{systables}->{__update_exec_log} SET dt_to = ?, err = ? WHERE id = ?", $ts, $@, $id_log);

				die $err;

			}
						
			sql_do ("UPDATE $conf->{systables}->{__update_exec_log} SET dt_to = ?, is_ok = 1 WHERE id = ?", $ts, $id_log);

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
	
	my @dirs = grep {-d} _INC ();
	
	require_model_scripts (@dirs);
	
	require_update_scripts ($_) foreach (@dirs);
		
	__profile_out ('require.scripts'); 
	
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

	my @inc = _INC ();

	my @file_names = grep {-f} map {"${_}/$local_file_name.pm"} @inc;

	my $is_need_reload_module;

	@file_names = map {
	
		my $last_recorded_time = $INC_FRESH_BY_PATH {$_};

		my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks) = stat ($_);
		
		my $last_modified_iso = dt_iso ($mtime);

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
		
		open (S, "<:encoding(UTF-8)", $file_name);
		my $src = qq {# line 1 "$file_name"\n use utf8; };
		$src .= $_ while (<S>);
		$src .= "; 1;";
		
		eval $src; die $@ if $@;

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
		exists &$full_sub_name    ? $full_sub_name :
		exists &$sub_name         ? $sub_name : 
		exists &$default_sub_name ? $default_sub_name : 
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
