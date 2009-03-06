no warnings;

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

		tie %tables, Eludia::Tie::FileDumpHash, {path => [map {"$_/Model"} @$PACKAGE_ROOT]};

		$DB_MODEL -> {tables} = \%tables;

	}	

}

################################################################################

sub require_scripts_of_type ($) {

	my ($script_type) = @_;

	my $__last_update = get_last_update ();
	
	my $__time = $__time = int (time ());
	
	foreach my $the_path (reverse @$PACKAGE_ROOT) {

		my $time = time;
	
		my $dir = $the_path . '/' . ucfirst $script_type;
	
		-d $dir or next;

		opendir (DIR, $dir) or die "can't opendir $dir: $!";
		my @file_names = readdir (DIR);
		closedir DIR;

		return __log_profilinig ($time, "   require_scripts_of_type $script_type: nothing to do in $the_path") if @file_names == 0;
		
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
		
		my $checksum_kind = $script_type . '_scripts';

		my ($needed_scripts, $new_checksums) = checksum_filter ($checksum_kind, '', $name2def);
	
		return __log_profilinig ($time, "   require_scripts_of_type $script_type: nothing to do in $the_path") if %$needed_scripts == 0;

		@scripts = 
			
			sort {$a -> {last_modified} <=> $b -> {last_modified}} 
			
			grep {$needed_scripts -> {$_ -> {path}}} 
					
			@scripts;

		my @src = ();

		foreach my $script (@scripts) {
		
			my $src = '';
						
			open (SCRIPT, $script -> {path}) or die "Can't open $script->{path}:$!\n";
			while (<SCRIPT>) { $src .= $_; };
			close (SCRIPT);
			
			$src = "\n$script->{name} => {$src}" if $script_type eq 'model';
			
			push @src, $src;
									
		}

		@src = ("\$model_update -> assert (prefix => 'application model#', tables => {@{[ join ',', @src]}})") if $script_type eq 'model';
			
		foreach my $src (@src) { 
			
			warn "# { script start #################################################################\n\n";
			warn $src . "\n\n";
			warn "# } script finish ################################################################\n";

			eval $src; 
			
			die $@ if $@;
			
		}
				
		checksum_write ($checksum_kind, $new_checksums);
			
		__log_profilinig ($time, "   require_scripts_of_type $script_type done in $dir");

	}
	
	set_last_update ($__time);

}

################################################################################

sub require_scripts {
	
	my $time = time;

	my $file_name = $PACKAGE_ROOT -> [-1] . '/Config.pm';

	open (CONFIG, $file_name) || die "can't open $file_name: $!";

	flock (CONFIG, LOCK_EX);

	require_scripts_of_type 'model';

	require_scripts_of_type 'update';

	flock (CONFIG, LOCK_UN);

	close (CONFIG);

	__log_profilinig ($time, "  require_scripts done");

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

	foreach my $path (reverse (@$PACKAGE_ROOT)) {
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
		$need_refresh = $INC_FRESH {$module_name} < $last_modified;
	}

	unless ($need_refresh) {

		$time = __log_profilinig ($time, "    $module_name is old");
		$need_refresh or return;

	}
	
	if ($type eq 'menu' && $db) {
	
		require_scripts ();

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
	
	eval $src; die $@ if $@;
		
	$INC_FRESH {$module_name} = $last_modified;		

	__log_profilinig ($time, "    $module_name reloaded");
        	
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

			my $id = sql_select_scalar ("SELECT id FROM $conf->{systables}->{__benchmarks} WHERE label = ?", $sub_name);
			unless ($id) {
				sql_do_insert ($conf->{systables}->{__benchmarks}, {fake => 0, label => $sub_name});
			}

			sql_do (
				"UPDATE $conf->{systables}->{__benchmarks} SET cnt = cnt + 1, ms = ms + ?, selected = selected + ?  WHERE id = ?",
				int(1000 * (time - $time)),
				$_REQUEST {__benchmarks_selected},
				$id,
			);

			
			sql_do (
				"UPDATE $conf->{systables}->{__benchmarks} SET  mean = ms / cnt, mean_selected = selected / cnt WHERE id = ?",
				$id,
			);
			
		}
		elsif ($preconf -> {core_debug_profiling} == 1) {
			__log_profilinig ($time, ' ' . $name_to_call);
		}
		
		return $result;
		
	}
	else {
		$sub_name    =~ /^(valid|recalcul)ate_/
		or $sub_name eq 'get_menu'
		or $sub_name eq 'select_menu'
		or warn "call_for_role: callback procedure not found: \$sub_name = $sub_name, \$role = $role \n";
	}

	return $name_to_call ? &$name_to_call (@_) : undef;
		
}

################################################################################

sub attach_globals {

	my ($from, $to, @what) = @_;
	
	$from =~ /::$/ or $from .= '::';
	$to   =~ /::$/ or $to   .= '::';

	*{"${to}$_"} = *{"${from}$_"} foreach (@what);

}

1;