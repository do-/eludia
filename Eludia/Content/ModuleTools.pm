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

sub require_presentation ($) {

	require_fresh ("${_PACKAGE}Presentation::$_[0]");

}

################################################################################

sub require_both ($) {

	require_content      $_[0];
	require_presentation $_[0];

}

################################################################################

sub require_config {
	
	require_fresh ($_PACKAGE . 'Config');
		
	fill_in ();

}

################################################################################

sub get_item_of_ ($) {

	$_[0] or die "get_item_of_: empty type";
	
	require_content ($_[0]);
	
	return call_for_role ('get_item_of_' . $_[0]);
	
}

################################################################################

sub require_model {

	my $core_was_ok = $model_update -> {core_ok};

	sql_assert_core_tables ();
	
	our $DB_MODEL ||= {

		default_columns => {
			id   => {TYPE_NAME  => 'int', _EXTRA => 'auto_increment', _PK => 1},
			fake => {TYPE_NAME  => 'bigint'},
		},

	};
	
	if (!exists $DB_MODEL -> {tables}) {

		my %tables = ();

		tie %tables, Eludia::Tie::FileDumpHash, {conf => $conf, path => \&_INC, package => current_package ()};

		$DB_MODEL -> {tables} = \%tables;

	}
	
	$core_was_ok or require_scripts ();

}

################################################################################

sub reverse_systables {

	return if $conf -> {systables_reverse};

	foreach my $key (keys %{$conf -> {systables}}) {
	
		my $value = $conf -> {systables} -> {$key};
		
		next if $key eq $value;
	
		$conf -> {systables_reverse} -> {$value} = $key;
	
	}					

}

################################################################################

sub list_of_files_in_the_directory ($) {

	opendir (DIR, $_[0]) or die "Ñan't opendir $_[0]: $!";
	
	my @file_names = readdir (DIR);
	
	closedir DIR;
	
	return @file_names;

}

################################################################################

sub require_scripts_of_type ($) {

	my ($script_type) = @_;

	my $__last_update = get_last_update ();
	
	my $__time = 0;
	
	my $postfix = '/' . ucfirst $script_type;
		
	foreach my $dir (grep {-d} map {$_ . $postfix} _INC ()) {

		my $time = time;
		
		my @scripts = ();
		my $name2def = {};

		foreach my $file_name (list_of_files_in_the_directory $dir) {
				
			$file_name =~ /\.p[lm]$/ or next;
			
			my $script = {name => $`};
			
			if (-f "$dir/core") {
			
				reverse_systables ();
				
				$script -> {name} = $conf -> {systables_reverse} -> {$script -> {name}} || $script -> {name};

			}

			$script -> {path} = "$dir/$file_name";
						
			my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $last_modified, $ctime, $blksize, $blocks) = stat ($script -> {path});
						
			($script -> {last_modified} = $last_modified) > $__last_update or next;
			
			$__time = $last_modified if $__time < $last_modified;
			
			push @scripts, $script;
						
			$name2def -> {$script -> {path}} = $script -> {last_modified};

		}
		
		if (@scripts == 0) {
		
			__log_profilinig ($time, "   $dir/.* <= " . localtime_to_iso ($__last_update));
			
			next;
			
		}

		my $checksum_kind = $script_type . '_scripts';

		my ($needed_scripts, $new_checksums) = checksum_filter ($checksum_kind, '', $name2def);
	
		if (%$needed_scripts == 0) {
		
			__log_profilinig ($time, "   require_scripts_of_type $script_type: all scripts in $dir are filtered by 'checksums' (which are, in fact, timestamps).");
			
			next;
			
		}

		foreach my $script (sort {$a -> {last_modified} <=> $b -> {last_modified}} grep {$needed_scripts -> {$_ -> {path}}} @scripts) {
		
			my $time = time ();
					
			if ($script_type eq 'model') {

				$model_update -> assert (
					
					prefix => 'application model#',
						
					default_columns => $DB_MODEL -> {default_columns},
						
					tables => {$script -> {name} => $DB_MODEL -> {tables} -> {$script -> {name}}},
						
				);
						
			}
			else {
			
				do $script -> {path};

				die $@ if $@;

			}

			$time = __log_profilinig ($time, "     $script->{path} fired");
											
		}

		checksum_write ($checksum_kind, $new_checksums);

		__log_profilinig ($time, "   require_scripts_of_type $script_type done in $dir");

	}
	
	return $__time;

}

################################################################################

sub require_scripts {

	return if $_REQUEST {__don_t_require_scripts};
	
	my $time = time;
	
	my $file_name;
	
	foreach my $dir (reverse @$PACKAGE_ROOT) {
	
		$file_name = "$dir/Config.pm";
		
		last if -f $file_name;
	
	}
	
	$file_name or die "Config.pm not found in @{[ join ',', @$PACKAGE_ROOT ]}\n";

	open (CONFIG, $file_name) || die "can't open $file_name: $!";

	flock (CONFIG, LOCK_EX);
	
	my $__last_update = get_last_update ();

	my $__time = 0;
	
	foreach my $kind ('model', 'updates') {
	
		my $time = require_scripts_of_type $kind;
		
		$__time > $time or $__time = $time;
	
	}

	set_last_update ($__time) if $__time > $__last_update;

	flock (CONFIG, LOCK_UN);

	close (CONFIG);

	__log_profilinig ($time, "  require_scripts done");
	
	$_REQUEST {__don_t_require_scripts} = 1;

}

################################################################################

sub localtime_to_iso {

	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime ($_[0]);
	
	return sprintf ('%04d-%02d-%02d %02d:%02d:%02d', 1900 + $year, 1 + $mon, $mday, $hour, $min, $sec);
	
}

################################################################################

sub _INC {

	my $type_prefix = $_REQUEST {type} =~ /^(\w+?)_/ ? $1 : '';
	
	my %prefixes = $_SUBSET -> {name} eq '*' ? ('*' => 1) : (map {$_ => 1} ('', $_[0], $_SUBSET -> {name}, $type_prefix));

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

sub require_fresh_message {

	my ($file_name) = @_;

	my $message = $file_name;

	$message =~ s{\\}{/}g;

	$message =~ s{.*?/(lib|GenericApplication)/}{};
	
	return $message;
	
}

################################################################################

sub last_modified_time_if_refresh_is_needed {

	my ($file_name) = @_;
	
	my $last_recorded_time = $INC_FRESH_BY_PATH {$file_name};
	
	my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks) = stat ($file_name);
	
	return $mtime if $mtime > $last_recorded_time;
	
	if ($preconf -> {core_debug_profiling}) {

		my $last_modified_iso = localtime_to_iso ($mtime);
	
		my $message = require_fresh_message ($file_name) .

			($last_recorded_time == $mtime ? " ==" : 
			
				' : ' . localtime_to_iso ($last_recorded_time) . " >");

		$time = __log_profilinig ($time, "   $message $last_modified_iso");

	}
	
	return undef;

}

################################################################################

sub require_fresh {

	local $time = time;

	my ($module_name) = @_;	

	my $local_file_name = $module_name;

	$local_file_name =~ s{(::)+}{\/}g;

	my $type = $';

	$local_file_name =~ s{^(.+?)\/}{\/};
	
	my $old_type = $_REQUEST {type};
	
	$_REQUEST {type} = $type     if $type !~ /^(menu|subset)/;

	my @inc = _INC ();

	$_REQUEST {type} = $old_type;

	my @file_names = grep {-f} map {"${_}$local_file_name.pm"} @inc;

	@file_names > 0 or return "Module $module_name not found in " . (join '; ', @inc) . "\n";

	(grep {last_modified_time_if_refresh_is_needed ($_)} @file_names) > 0 or return;

	foreach my $file_name (reverse @file_names) {

		delete $INC_FRESH_BY_PATH {$file_name};

		my $last_modified = last_modified_time_if_refresh_is_needed ($file_name);

		if ($type eq 'menu') {

			(tied %{$DB_MODEL -> {tables}}) -> {cache} = {};

			require_scripts () if $db;

		}

		my $src = '';

		open (S, $file_name);

		while (my $line = <S>) {

$line = Encode::decode ('windows-1251', $line);

			if ($_OLD_PACKAGE) {
				$line =~ s{package\s+$_OLD_PACKAGE}{package $_NEW_PACKAGE}g;
				$line =~ s{$_OLD_PACKAGE\:\:}{$_NEW_PACKAGE\:\:}g;
			}

			$src .= $line;

			$line =~ /^sub (\w+)_$type \{ # / or next;

			my $sub   = $1;
			my $label = $';
			$label =~ s{[\r\n]+$}{}gsm;

			my $action = $sub =~ /^(do|validate)_/ ? $' : ''; 

			$_ACTIONS -> {_actions} -> {$type} -> {$action} = $label;

		}

		close (S);

		eval qq{# line 1 "$file_name"\n $src \n; 1;\n};

		die "$module_name: " . $@ if $@;

		$INC_FRESH {$module_name} = $INC_FRESH_BY_PATH {$file_name} = $last_modified;

		if ($preconf -> {core_debug_profiling}) {

			my $message = require_fresh_message ($file_name);

			$time = __log_profilinig ($time, "   $message -> " . localtime_to_iso ($last_modified));

		}
	
	}
        	
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
	
		$_REQUEST {__benchmarks_selected} = 0;
	
		my $result = &$name_to_call (@_);

		if ($preconf -> {core_debug_profiling} > 1) {

			my $id = sql_select_id ($conf->{systables}->{__benchmarks} => {fake => 0, label => $sub_name});

			my $benchmarks_table = sql_table_name ($conf->{systables}->{__benchmarks});

			sql_do (
				"UPDATE $benchmarks_table SET cnt = cnt + 1, ms = ms + ?, selected = selected + ?  WHERE id = ?",
				int(1000 * (time - $time)),
				$_REQUEST {__benchmarks_selected},
				$id,
			);

			
			sql_do (
				"UPDATE $benchmarks_table SET  mean = ms / cnt, mean_selected = selected / cnt WHERE id = ?",
				$id,
			);
			
		}
		elsif ($preconf -> {core_debug_profiling} == 1) {
			__log_profilinig ($time, ' ' . $name_to_call);
		}
		
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
