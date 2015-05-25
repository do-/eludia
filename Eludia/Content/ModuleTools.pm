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

	__profile_in ('require.config');

	unless ($preconf -> {_} -> {site_conf} -> {path}) {

		$preconf -> {_} -> {site_conf} -> {path} = $preconf -> {_} -> {docroot};

		$preconf -> {_} -> {site_conf} -> {path} =~ s{docroot/?$}{conf/httpd.conf};

	}

	-f $preconf -> {_} -> {site_conf} -> {path} or die "Site configuration file not found at '$preconf->{_}->{site_conf}->{path}': $!\n";

	my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $last_modified, $ctime, $blksize, $blocks) = stat ($preconf -> {_} -> {site_conf} -> {path});

	if ($last_modified > $preconf -> {_} -> {site_conf} -> {timestamp}) {

		open (I, $preconf -> {_} -> {site_conf} -> {path}) or die "Can't open $preconf->{_}->{site_conf}->{path}: $!\n";

		my $is_utf;
		if ($i18n -> {_charset}) {
			$is_utf = $i18n -> {_charset} eq 'UTF-8'
		} else {
			if (open (CONF, config_pm_path ())) {
				$is_utf = (join '', (<CONF>)) =~ /^\s*lang\s*=>.*UTF8/m;
				close (CONF);
			}
		}

		my $httpd_conf = join '', (<I>);
		$httpd_conf = Encode::decode('windows-1251', $httpd_conf)
			if $is_utf;


		close (I);

		$httpd_conf =~ m{\<perl\s*\>(.*?)\</perl\s*\>}gism or die "<Perl> section is not found at $preconf->{_}->{site_conf}->{path}";

		my $perl_section = $1;

		$perl_section =~ s{use\s+Eludia::Loader(.*?)\{}{\$preconf_override = \{}sm;

		local $preconf_override = {};

		warn $perl_section;

		eval ($is_utf ? 'use utf8; ' : '') . $perl_section;

		if ($@) {

			warn $@;

		}
		else {

			$preconf = {%$preconf, %$preconf_override};

			sql_disconnect ();
			sql_reconnect ();

			$preconf -> {_} -> {site_conf} -> {timestamp} = $last_modified;

		}

	}

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
			fake => {TYPE_NAME  => 'bigint'},
		},

	};

	if (!exists $DB_MODEL -> {tables}) {

		my %tables = ();

		tie %tables, Eludia::Tie::FileDumpHash, {conf => $conf, path => \&_INC, package => current_package ()};

		$DB_MODEL -> {tables} = \%tables;

	}

	$core_was_ok or require_scripts ();

	__profile_out ('require.model');

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

	my $checksum_kind = $script_type . '_scripts';

	my $is_start_scripts = 1;

	if ($preconf -> {db_store_checksums} && $script_type eq "updates") {

		$is_start_scripts = sql_select_scalar (
			"SELECT id FROM $conf->{systables}->{__checksums} WHERE id_checksum <> '_' AND kind = ?"
			, $checksum_kind
		);
	}

	foreach my $dir (grep {-d} map {$_ . $postfix} _INC ()) {

		__profile_in ("require.scripts.$script_type" => {label => $dir});

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

			if ($script -> {last_modified} > $name2def -> {$script -> {name}}) {
				$name2def -> {$script -> {name}} = $script -> {last_modified};
			}

		}

		if (@scripts == 0) {

			__profile_out ("require.scripts.$script_type");

			next;

		}

		my ($needed_scripts, $new_checksums) = checksum_filter ($checksum_kind, '', $name2def);

		if (!$is_start_scripts && $script_type eq "updates") {

			checksum_write ($checksum_kind, $new_checksums);

			__profile_out ("require.scripts.$script_type");

			next;
		}

		if (%$needed_scripts == 0) {

			__profile_out ("require.scripts.$script_type");

			next;

		}

		@scripts = grep {$needed_scripts -> {$_ -> {name}}} @scripts;

		@scripts = sort {
			$DB_MODEL -> {tables} -> {$a -> {name}} -> {sql}
					cmp $DB_MODEL -> {tables} -> {$b -> {name}} -> {sql}
				|| $a -> {last_modified} <=> $b -> {last_modified}
			} @scripts;

		foreach my $script (@scripts) {

			__profile_in ("require.scripts.$script_type.file", {label => $script -> {path}});

			if ($script_type eq 'model') {

				$model_update -> assert (

					prefix => 'application model#',

					default_columns => $DB_MODEL -> {default_columns},

					tables => {$script -> {name} => $DB_MODEL -> {tables} -> {$script -> {name}}},

				);

			} elsif ($i18n -> {_charset} ne 'UTF-8') {

				$ENV {ELUDIA_SILENT} or warn "\n" . update_script_log_signature ($script) . "starting...\n";

				do $script -> {path};
				die $@ if $@;

				$ENV {ELUDIA_SILENT} or warn update_script_log_signature ($script) . "finished.\n";
			} else {

				my $s = '';

				open (F, $script -> {path}) or die "Can't open $script->{path}: $!\n";
				while (<F>) {$s .= $_};
				close (F);

				eval Encode::decode ($preconf -> {core_src_charset} ||= 'windows-1251', $s);
				die $@ if $@;

			}

			__profile_out ("require.scripts.$script_type.file");

		}

		checksum_write ($checksum_kind, $new_checksums);

		__profile_out ("require.scripts.$script_type");

	}

	return $__time;

}

################################################################################

sub update_script_log_signature {

	my ($script) = @_;

	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime (time);

	$year += 1900;

	$mon ++;

	return sprintf "[%04d-%02d-%02d %02d:%02d:%02d $$ $$script{path}] ", $year, $mon, $mday, $hour, $min, $sec;
}

################################################################################

sub require_scripts {

	return if $_REQUEST {__don_t_require_scripts};

	__profile_in ('require.scripts');

	my $file_name = config_pm_path ();

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

	__profile_out ('require.scripts');

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

sub require_fresh {

	my ($module_name) = @_;

	__profile_in ('require.module' => {label => $module_name});

	my $local_file_name = $module_name;

	$local_file_name =~ s{(::)+}{\/}g;

	my $type = $';

	$local_file_name =~ s{^(.+?)\/}{\/};

	my $old_type = $_REQUEST {type};

	$_REQUEST {type} = $type     if $type !~ /^(menu|subset)/;

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

	my $is_utf;
	if ($i18n -> {_charset}) {
		$is_utf = $i18n -> {_charset} eq 'UTF-8'
	} else {
		if (open (CONF, config_pm_path ())) {
			$is_utf = (join '', (<CONF>)) =~ /^\s*lang\s*=>.*UTF8/m;
			close (CONF);
		}
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

		flock (S, LOCK_SH)
			if ($type eq 'Config');

		while (my $line = <S>) {

			$line = Encode::decode ($preconf -> {core_src_charset} ||= 'windows-1251', $line)
				if $is_utf;

			$src .= $line;

			$line =~ /^sub (\w+)_$type \{ # / or next;

			my $sub   = $1;
			my $label = $';
			$label =~ s{[\r\n]+$}{}gsm;

			my $action = $sub =~ /^(do|validate)_/ ? $' : '';

			$_ACTIONS -> {_actions} -> {$type} -> {$action} = $label;

		}

		flock (S, LOCK_UN)
			if ($type eq 'Config');

		close (S);

		eval qq{# line 1 "$file_name"\n} . ($is_utf ? "use utf8;\n" : "") . qq{$src \n; 1;\n};

		if ($@) {

			$@ =~ s/eval \'.*\'/eval \' \'/s;

			die "$module_name: " . $@;
		}

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

	my $page_type = $_REQUEST {type};

	if ($_REQUEST {__edited_cells_table}) {
		require_content ( $_REQUEST {action_type} )	if $_REQUEST {action_type};

		$page_type = $_REQUEST {action_type} || $_REQUEST {type};
	}

	$default_sub_name =~ s{_$page_type$}{_DEFAULT};

	my $name_to_call =
		defined $$_PACKAGE {$full_sub_name}    ? $full_sub_name :
		defined $$_PACKAGE {$sub_name}         ? $sub_name :
		defined $$_PACKAGE {$default_sub_name} ? $default_sub_name :
		undef;

	if ($name_to_call) {

		__profile_in ("call.$name_to_call");

		my $result = &$name_to_call (@_);

		__profile_out ("call.$name_to_call");

		return $result;

	}
	else {

		!$preconf -> {core_debug_profiling}
		or $sub_name =~ /^(valid|recalcul)ate_/
		or $sub_name =~ /^(get|select)_menu$/
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

################################################################################

sub config_pm_path {

	my $file_name;

	foreach my $dir (reverse @$PACKAGE_ROOT) {

		$file_name = "$dir/Config.pm";

		last if -f $file_name;

	}

	$file_name or die "Config.pm not found in @{[ join ',', @$PACKAGE_ROOT ]}\n";

	return $file_name;

}


1;
