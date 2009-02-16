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
	
	my ($options) = @_;
	
	if ($options -> {no_db}) {
		$options -> {_db} = $db;
		$db = undef;
	}
	
	delete $INC {$_PACKAGE . '/Config.pm'};
	my $module_name = $_PACKAGE . 'Config';
	delete $INC_FRESH {$module_name};
	require_fresh ($module_name);

	if ($options -> {no_db}) {
		$db = $options -> {_db};
	}

}

################################################################################

sub get_item_of_ ($) {

	$_[0] or die "get_item_of_: empty type";
	
	require_content ($_[0]);
	
	return call_for_role ('get_item_of_' . $_[0]);
	
}

################################################################################

sub require_fresh {

	my $time = time;

	my ($module_name, $fatal) = @_;	

	check_systables ();
	
	my $file_name = $module_name;
	$file_name =~ s{(::)+}{\/}g;

	my $inc_key = $file_name . '.pm';

	$file_name =~ s{^(.+?)\/}{\/};
	
	my $found = 0;
	my $the_path = '';

	foreach my $path (reverse (@$PACKAGE_ROOT)) {
		my $local_file_name = $path . $file_name . '.pm';
		-f $local_file_name or next;
		$file_name = $local_file_name;
		$found = 1;
		$the_path = $path;
		$the_path =~ s{[\\\/]*(Content|Presentation)}{};
		last;
	}
	
	my $is_config = $file_name =~ /Config\.pm$/ ? 1 : 0;

	$found or return "File not found: $file_name\n";
	
	my $need_refresh = $preconf -> {core_spy_modules} || !$INC {$inc_key};
	
	my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $last_modified, $ctime, $blksize, $blocks);
	
	if ($need_refresh) {
		($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $last_modified, $ctime, $blksize, $blocks) = stat ($file_name);
		my $last_load = $INC_FRESH {$module_name} + 0;
		$need_refresh = $last_load < $last_modified;
	}

	if ($need_refresh) {
	
		my $src = '';
			
		my $type = '';
			
		if ($file_name =~ /(\w+)\.pm$/) {
			
			$type = $1;
			
		}
			
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

			my $action = 
				$sub =~ /^do_/         ? $' : 
				$sub =~ /^validate_/   ? $' : 
				$sub eq 'get_item_of'  ? '' : 
				$sub eq 'select'       ? '' :
				undef;						
					
			$_ACTIONS -> {_actions} -> {$type} -> {$action} ||= $label;

		}
			
		close (S);
		
		eval $src;
			
		die $@ if $@;

		if ($is_config) {
			check_systables ();
			sql_assert_core_tables ();
		}

		if (
			$is_config
			&& $DB_MODEL
			&& !exists $DB_MODEL -> {tables}
		) {
			my %tables = ();
			tie %tables, Eludia::Tie::FileDumpHash, {path => [map {"$_/Model"} @$PACKAGE_ROOT]};
			$DB_MODEL -> {tables} = \%tables;
			$DB_MODEL -> {splitted} = 1;
		}

		if (
			$db && (
				!$CONFIG_IS_LOADED || (
					$last_modified > 0 + sql_select_scalar (
						"SELECT unix_ts FROM $conf->{systables}->{__required_files} WHERE file_name = ?",
						$module_name
					)
				)
			)
		) {
				
			my $__last_update = sql_select_scalar ("SELECT unix_ts FROM $conf->{systables}->{__last_update}");
			my $__time = int(time ());

			if ($DB_MODEL && !$DB_MODEL -> {splitted}) {

				open  (CONFIG, $file_name) || die "can't open $file_name: $!";
				flock (CONFIG, LOCK_EX);
				
				eval {
					$model_update -> assert (%$DB_MODEL,core_voc_replacement_use => $conf -> {core_voc_replacement_use});
				};
				
				flock (CONFIG, LOCK_UN);
				close (CONFIG);
				
				die $@ if $@;

			}
			elsif (-d "$the_path/Model") {

				eval {

					opendir (DIR, "$the_path/Model") || die "can't opendir $the_path/Model: $!";
					my @scripts = readdir (DIR);
					closedir DIR;

					foreach my $script (@scripts) {

						$script =~ /\.p[lm]$/ or next;
						my $name = $`;

						my $script_path = "$the_path/Model/$script";

						($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $last_modified, $ctime, $blksize, $blocks) = stat ($script_path);

						if ($last_modified <= $__last_update) {
							next;
						}
						
						$__time = $last_modified if $__time < $last_modified;

						open  (SCRIPT, $script_path) || die "can't lock $script_path: $!";
						flock (SCRIPT, LOCK_EX);

						my ($__new_last_update, $pid) = sql_select_array ("SELECT unix_ts, pid FROM $conf->{systables}->{__last_update}");

						if ($__new_last_update > $__last_update) {

print STDERR "[$$]  Oops, [$pid] bypassed us. Unlocking $name...\n";

							flock (SCRIPT, LOCK_UN);
							close (SCRIPT);
print STDERR "[$$]  $name unlocked.\n";

							$__last_update = -1;
							last;

						}

print STDERR "[$$]  Altering $name...\n";

						my %db_model = %$DB_MODEL;
						$db_model {no_checksums} = 1;

						my $src = "\$db_model {tables} = {$name => {";
						while (<SCRIPT>) {
							$src .= $_;
						}
						$src .= '}}';
												
print STDERR "[$$]  $src\n";
						
						eval $src;

						$db_model {tables} -> {$name} -> {src} = $src;
						
						if ($@) {
							flock (SCRIPT, LOCK_UN);
							close (SCRIPT);
							die $@;
						}
						
print STDERR "[$$] " . Dumper (\%db_model);

						eval {
							$model_update -> assert (%db_model,core_voc_replacement_use => $conf -> {core_voc_replacement_use});
						};                                         
						
print STDERR "[$$]  OK, now unlocking $name...\n";

						flock (SCRIPT, LOCK_UN);
						close (SCRIPT);
						
						die $@ if $@;
						
print STDERR "[$$] OK, $name is up to date\n";

					}
																			

				};
				
				die $@ if $@;

			}

			if (-d "$the_path/Updates") {

				eval {

					my $__last_update = sql_select_scalar ("SELECT unix_ts FROM $conf->{systables}->{__last_update}");
					my $__time = int(time ());

					opendir (DIR, "$the_path/Updates") || die "can't opendir $the_path/Updates: $!";
					my @scripts = readdir (DIR);
					closedir DIR;

					foreach my $script (@scripts) {

						$script =~ /\.p[lm]$/ or next;

						my $script_path = "$the_path/Updates/$script";

						my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $last_modified, $ctime, $blksize, $blocks) = stat ($script_path);

						if ($last_modified <= $__last_update) {
							next;
						}						

						$__time = $last_modified if $__time < $last_modified;

print STDERR "[$$] Found new ($last_modified) update script '$script'. Locking $script.\n";

						open  (SCRIPT, $script_path) || die "can't lock $script_path: $!";
						flock (SCRIPT, LOCK_EX);
						
						my ($__new_last_update, $pid) = sql_select_array ("SELECT unix_ts, pid FROM $conf->{systables}->{__last_update}");

						if ($__new_last_update > $__last_update) {

print STDERR "[$$]  Oops, [$pid] bypassed us. Unlocking $name...\n";

							flock (SCRIPT, LOCK_UN);
							close (SCRIPT);
print STDERR "[$$]  $name unlocked.\n";

							$__last_update = -1;
							last;

						}

print STDERR "[$$]  Executing $script...\n";

						my $src = '';
						while (<SCRIPT>) {
							$src .= $_;
						}

print STDERR "[$$] $src";
						
						eval $src;

print STDERR "[$$]  Unlocking $script...\n";

						flock (SCRIPT, LOCK_UN);
						close (SCRIPT);

						die $@ if $@;
						
print STDERR "[$$] OK, $script is over and out.\n";

					}

				};
				
				die $@ if $@;

			}			
		
			if ($__last_update > -1) {
				$__last_update or sql_do ("INSERT INTO $conf->{systables}->{__last_update} (unix_ts) VALUES (?)", int(time));
				sql_do ("UPDATE $conf->{systables}->{__last_update} SET unix_ts = ?, pid = ?", $__time, $$);
			}

			if ($db && $db -> ping) {
				sql_do ("DELETE FROM $conf->{systables}->{__required_files} WHERE file_name = ?", $module_name);
				sql_do ("INSERT INTO $conf->{systables}->{__required_files} (file_name, unix_ts) VALUES (?, ?)", $module_name, int(time));
			}

		};
			
		$INC_FRESH {$module_name} = $last_modified;
		
	}

        if ($@) {
		$_REQUEST {error} = $@;
		print STDERR "require_fresh: error load module $module_name: $@\n";
        }
        else {
        	our $CONFIG_IS_LOADED ||= 1 if $is_config && $db;
        }
        
	$time = __log_profilinig ($time, "    $module_name reloaded") if $db;

        return $@;
	
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