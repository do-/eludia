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

	sql_assert_core_tables ();
	
	our $DB_MODEL ||= {

		default_columns => {
			id   => {TYPE_NAME  => 'int', _EXTRA => 'auto_increment', _PK => 1},
			fake => {TYPE_NAME  => 'bigint'},
		},

	};
	
	if (!exists $DB_MODEL -> {tables}) {

		my %tables = ();

		tie %tables, Eludia::Tie::FileDumpHash, {conf => $conf, path => \&INC};

		$DB_MODEL -> {tables} = \%tables;

	}	

}

################################################################################

sub require_scripts_of_type ($) {

	my ($script_type) = @_;

	my $__last_update = get_last_update ();
	
	my $__time = 0;
	
	my $is_updated;
	
	foreach my $the_path (INC ()) {

		my $time = time;
	
		my $dir = $the_path . '/' . ucfirst $script_type;
	
		-d $dir or next;

		opendir (DIR, $dir) or die "can't opendir $dir: $!";
		my @file_names = readdir (DIR);
		closedir DIR;

		if (@file_names == 0) {
		
			__log_profilinig ($time, "   require_scripts_of_type $script_type: $dir is empty") ;
			
			next;
			
		}
		
		my @scripts = ();
		my $name2def = {};

		foreach my $file_name (@file_names) {
				
			$file_name =~ /\.p[lm]$/ or next;
			
			my $script = {name => $`};

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

		@scripts = 
			
			sort {$a -> {last_modified} <=> $b -> {last_modified}} 
			
			grep {$needed_scripts -> {$_ -> {path}}} 
					
			@scripts;

		my @src = ();

		foreach my $script (@scripts) {
		
			my $src = '';
			
			if ($script_type eq 'model') {

				$src = Dumper ($DB_MODEL -> {tables} -> {$script -> {name}});
				$src =~ s{^\$VAR1 =}{$script->{name} =>};
				$src =~ s{;\s*$}{}sm;

			}
			else {

				open  (SCRIPT, $script -> {path}) or die "Can't open $script->{path}:$!\n";
				while (<SCRIPT>) { $src .= $_; };
				close (SCRIPT);

			}

			push @src, $src;
									
		}

		@src = ("\$model_update -> assert (prefix => 'application model#', default_columns => \$DB_MODEL -> {default_columns}, tables => {@{[ join ',', @src]}})") if $script_type eq 'model';
			
		foreach my $src (@src) { 
			
			warn "# { script start #################################################################\n\n";
			warn $src . "\n\n";
			warn "# } script finish ################################################################\n";

			eval $src; 
			
			die $@ if $@;
			
			$is_updated = 1;
			
		}
				
		checksum_write ($checksum_kind, $new_checksums);
			
		__log_profilinig ($time, "   require_scripts_of_type $script_type done in $dir");

	}
	
	return $__time;

}

################################################################################

sub require_scripts {
	
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

}

################################################################################

sub localtime_to_iso {

	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime ($_[0]);
	
	return sprintf ('%04d-%02d-%02d %02d:%02d:%02d', 1900 + $year, 1 + $mon, $mday, $hour, $min, $sec);
	
}

################################################################################

sub INC {

	my ($prefix) = split /_/, $_REQUEST {type};
	
	my @result = ();
	
	foreach my $dir (reverse @$PACKAGE_ROOT) {
	
		my $default = $dir . '/_';
	
		if (-d $default) {
					
			my $specific = $dir . '/_' . $prefix;
			
			-d $specific and push @result, $specific;

			push @result, $default;
		
		}
		else {
		
			push @result, $dir;
		
		}
	
	}

	return @result;

}

################################################################################

sub require_fresh {

	my $time = time;

	my ($module_name) = @_;	
	
	my $file_name = $module_name;
	
	$file_name =~ s{(::)+}{\/}g;
	
	my $type = $';

	my $inc_key = $file_name . '.pm';

	$file_name =~ s{^(.+?)\/}{\/};
	
	my $found = 0;

	foreach my $path (INC ()) {
		my $local_file_name = $path . $file_name . '.pm';
		-f $local_file_name or next;
		$file_name = $local_file_name;
		$found = 1;
		last;
	}
	
	$found or return "File not found: $file_name\n";
	
	my $need_refresh = !$INC {$inc_key};
	
	my $last_modified;
		
	if ($need_refresh) {
		my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks) = stat ($file_name);
		$last_modified = $mtime;
		$need_refresh = ($INC_FRESH {$module_name} < $last_modified);
	}

	unless ($need_refresh) {
	
		if ($preconf -> {core_debug_profiling}) {
	
			my $last_modified_iso = localtime_to_iso ($last_modified);
			
			my $message = $module_name;
			
			$message =~ s{\w+::(\w)\w*::(\w+)$}{$2 ($1)};
	
			$message .=

				$INC_FRESH {$module_name} == $last_modified ? " == $last_modified_iso" :

					' : ' . localtime_to_iso ($INC_FRESH {$module_name}) . " > $last_modified_iso)";

			$time = __log_profilinig ($time, '   ' . $message);

		}				
		
		return;

	}
	
	if ($type eq 'menu') {
	
		(tied %{$DB_MODEL -> {tables}}) -> {cache} = {};
	
		require_scripts () if $db;

	}
			
	my $src = '';
				
	open (S, $file_name);

	while (my $line = <S>) {

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
				
		$_ACTIONS -> {_actions} -> {$type} -> {$action} ||= $label;

	}
		
	close (S);
	
	eval qq{# line 1 "$file_name"\n $src \n; 1;\n};
		
	die "$module_name: " . $@ if $@;
		
	$INC_FRESH {$module_name} = $last_modified;		

	if ($preconf -> {core_debug_profiling}) {
				
		my $message = $module_name;
			
		$message =~ s{\w+::(\w)\w*::(\w+)$}{$2 ($1)};
	
		$time = __log_profilinig ($time, "   $message -> " . localtime_to_iso ($last_modified));

	}
        	
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
