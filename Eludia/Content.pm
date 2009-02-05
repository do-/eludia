no warnings;

use Eludia::Content::ModuleTools;
use Eludia::Content::Handler;

#############################################################################

sub defer {

	my ($sub, $params, $options) = @_;
	
	$model_update -> assert (
	
		tables => {
	
			__deferred => {
	
				columns => {
					fake          => {TYPE_NAME => 'bigint'},
					id            => {TYPE_NAME => 'int', _EXTRA => 'auto_increment', _PK => 1},
					sub           => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
					params        => {TYPE_NAME => 'longtext'},
					label         => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
				},
				
			},

			__deferred_hot => {
	
				columns => {
					fake          => {TYPE_NAME => 'bigint'},
					id            => {TYPE_NAME => 'int'},
					in_progress   => {TYPE_NAME => 'int', NULLABLE => 0, COLUMN_DEF => 0},
				},
				
			},

			__deferred_log => {
	
				columns => {
					fake          => {TYPE_NAME => 'bigint'},
					id            => {TYPE_NAME => 'int', _EXTRA => 'auto_increment', _PK => 1},
					id___deferred => {TYPE_NAME => 'bigint'},
					error         => {TYPE_NAME => 'longtext'},
					dt_start      => {TYPE_NAME => 'datetime'},
					dt_finish     => {TYPE_NAME => 'datetime'},
				},
				
				keys => {
					id___deferred => 'id___deferred',
				},
				
			},
			
		},
		
		core_voc_replacement_use => $conf -> {core_voc_replacement_use}
		
	);
	
	my $id = sql_do_insert (__deferred => {
		fake          => 0,
		'sub'         => $sub,
		params        => Dumper ($params),
		label         => $options -> {label},
	});
	
	sql_do ('INSERT INTO __deferred_hot (id) VALUES (?)', $id);

}

#############################################################################

sub check_deferred {

	my ($options) = @_;
	
	my $package = __PACKAGE__;

	$options -> {pidfile} ||= '/var/run/defer_' . $package;

warn "[deferred $package] Starting process, pidfile = '$options->{pidfile}'\n";
	
	unless (-f $options -> {pidfile}) {
		open  (PID, '>' . $options -> {pidfile}) || die "can't write to $options->{pidfile}: $!";
		close  PID;
	}
	
	open  (PIDFILE, $options -> {pidfile}) || die "can't open $options->{pidfile}: $!";
	flock (PIDFILE, LOCK_SH);
	
	my ($old_pid) = <PIDFILE>;
	
	if ($old_pid) {

warn "[deferred $package] Old pid = $old_pid found, killing it...\n";

		`kill -9 $old_pid`

	};

	my $ids = sql_select_ids ('SELECT id FROM __deferred_hot WHERE in_progress > 0');
	
	if ($ids ne '-1') {

warn "[deferred $package] Pending tasks found ($ids), purging it...\n";

		sql_do ("UPDATE __deferred_log SET dt_finish = NOW(), error = ? WHERE id IN ($ids)", 'Timeout exceeded');
		sql_do ('UPDATE __deferred_hot SET in_progress = 0');

	}
		
	open  (PID, '>' . $options -> {pidfile}) || die "can't write to $options->{pidfile}: $!";
	print  PID $$;
	close  PID;

	flock (PIDFILE, LOCK_UN);
	close (PIDFILE);	
	
	$options -> {cnt} ||= 1;
	
warn "[deferred $package] Now will try to execute $options->{cnt} call(s)\n";

	foreach (1 .. $options -> {cnt}) {
	
		my $cnt = sql_select_scalar ('SELECT COUNT(*) FROM __deferred_hot');

warn "[deferred $package]  There is(are) $cnt calls...\n";

		$cnt or last;
	
		my $ord = 0 + int (rand () * $cnt);

warn "[deferred $package]  Random order: $ord...\n";

		my $id = sql_select_scalar ("SELECT id FROM __deferred_hot ORDER BY id LIMIT $ord, 1");

warn "[deferred $package]  Its id=$id\n";

		sql_do ('UPDATE __deferred_hot SET in_progress = ? WHERE id = ?', $$, $id);

		my $id_log = sql_do_insert (__deferred_log => {id___deferred => $id});

		sql_do ('UPDATE __deferred_log SET dt_start = NOW() WHERE id = ?', $id_log);

		my $deferred = sql (__deferred => $id);

warn "[deferred $package]  " . Dumper ($deferred);

		eval "my $deferred->{params}; $deferred->{sub} (\@\$VAR1);";

warn "[deferred $package]  " . ($@ ? $@ : "ok.\n");

		sql_do ('UPDATE __deferred_log SET dt_finish = NOW(), error = ? WHERE id = ?', $@ || undef, $id_log);

		$@ or sql_do ('DELETE FROM __deferred_hot WHERE id = ?', $id);

	}
	
	unlink $options -> {pidfile};

}

#############################################################################

sub fake_select {
	
	return {
		type    => 'input_select',
		name    => 'fake',
		values  => [
			{id => '0,-1', label => 'Все'},
			{id => '-1', label => 'Удалённые'},
		],
		empty   => 'Активные',
	}
	
}

#############################################################################

sub ids {

	my ($ar, $options) = @_;
	
	$options -> {field} ||= 'id';
	$options -> {empty} ||= '-1';
	$options -> {idx}   ||= {};
	
	my $ids = $options -> {empty};
	my $idx = $options -> {idx};
	
	foreach my $i (@$ar) {

		my $id = $i -> {$options -> {field}};
		
		if (ref $idx eq HASH && $id) {
			$idx -> {$id} = $i;
		}
		elsif (ref $idx eq ARRAY && $id > 0) {
			$idx -> [$id] = $i;
		}
		
		$id > 0 or next;
		$ids .= ',';
		$ids .= $id;

	}
	
	return wantarray ? ($ids, $idx) : $ids;

}

#############################################################################

sub is_off {
	
	my ($options, $value) = @_;
	
	return 0 unless $options -> {off};
	
	if ($options -> {off} eq 'if zero') {
		return ($value == 0);
	}
	elsif ($options -> {off} eq 'if not') {
		return !$value;
	}
	else {
		return $options -> {off};
	}

}

################################################################################

sub async ($@) {

	my ($sub, @args) = @_;

	eval { &$sub (@args); };
	
	print STDERR $@ if $@;

}

################################################################################

sub b64u_freeze {

	b64u_encode (
		$Storable::VERSION ? 
			Storable::freeze ($_[0]) : 
			Dumper ($_[0])
	);
	
}

################################################################################

sub b64u_thaw {

	my $serialized = b64u_decode ($_[0]);
	
	if ($Storable::VERSION) {
		return Storable::thaw ($serialized);
	}
	else {
		my $VAR1;
		eval $serialized;
		return $VAR1;
	}
	
}

################################################################################

sub b64u_encode {
	my $s = MIME::Base64::encode ($_[0]);
	$s =~ y{+/=}{-_.};
	$s =~ s{[\n\r]}{}gsm;
	return $s;
}

################################################################################

sub b64u_decode {
	my $s = $_ [0];
	$s =~ y{-_.}{+/=};
	return MIME::Base64::decode ($s);
}

################################################################################

sub add_totals {

	my ($ar, $options) = @_;

	my @ar = ({_root => -1}, @$ar, {_root => 1});	
	
	$options -> {no_sum} .= ',id,label';
	$options -> {no_sum} = { map {$_ => 1} split /\,/, $options -> {no_sum}};
	
	unless ($options -> {fields}) {

		my $field = {name => '_root'};

		if (defined $options -> {position} && $options -> {position} == 0) {
			$field -> {top} = 1;
		}
		else {
			$field -> {bottom} = 1;
		}

		$options -> {fields} = [$field];

	}	
	
	my @totals_top    = ();
	my @totals_bottom = ();
	
	foreach my $field (@{$options -> {fields}}) {
		$field -> {top} or $field -> {bottom} ||= 1;
		push @totals_top,    {};
		push @totals_bottom, {};
		$options -> {no_sum} -> {$field -> {name}} = 1;
	};
	
	my @result = ();
	
	my $is_topped = 0;
	
	my $inserted = 0;
	
	for (my $i = 1; $i < @ar; $i++) {
	
		my $prev = $ar [$i - 1];
		my $curr = $ar [$i];
		
		my $first_change = -1;
		
		for (my $j = 0; $j < @{$options -> {fields}}; $j++) {
			my $name = $options -> {fields} -> [$j] -> {name};
			next if $prev -> {$name} eq $curr -> {$name};
			$first_change = $j;
			last;
		}

		if ($first_change > -1) {
						
			for (my $j = @{$options -> {fields}} - 1; $j >= $first_change; $j--) {

				my $field = $options -> {fields} -> [$j];

				$field -> {bottom} or next;

				if ($curr -> {_root} || !$prev -> {_root}) {

					$totals_bottom [$j] -> {is_total} = 1 + $j;
					$totals_bottom [$j] -> {def}      = $field;
					$totals_bottom [$j] -> {data}     = $prev;
					$totals_bottom [$j] -> {label}    = 'Итого';

					push @result, $totals_bottom [$j];
					
					$inserted ++;

				}

				$totals_bottom [$j] = {};

			}

			for (my $j = $first_change; $j < @{$options -> {fields}}; $j++) {

				my $field = $options -> {fields} -> [$j];

				$field -> {top} or next;

				$totals_top [$j] = {
					is_total => -(1 + $j),
					def      => $field,
					data     => $curr,
					label    => 'Итого',
				};

				if ($prev -> {_root} || !$curr -> {_root}) {

					push @result, $totals_top [$j];

					$inserted ++;

					$is_topped = 1;

				}

			}
									
		}

		foreach my $key (keys %$curr) {
			next if $options -> {no_sum} -> {$key};
			my $value = $curr -> {$key};
			next if $value !~ /^[\-\+]?\d+(\.\d+)?/;
			next if $value == 0;
			next if $value =~ /^\d\d\d\d\-\d\d\-\d\d/;
			foreach my $sum (@totals_bottom) { $sum -> {$key} += $value}
			next unless $is_topped;
			foreach my $sum (@totals_top)    { $sum -> {$key} += $value}
		}

		push @result, $curr;

	}

	@$ar = grep {!$_ -> {_root}} @result;
	
	return $inserted;
	
}

################################################################################

sub __log_profilinig {

	my $now = time ();
	
	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime ($now);
	$year += 1900;
	$mon ++; 

	printf STDERR "Profiling [%04d-%02d-%02d %02d:%02d:%02d:%03d $$] %20.10f ms %s\n", 
		$year,
		$mon,
		$mday,
		$hour,
		$min,
		$sec,
		int (1000 * ($now - int $now)),
		1000 * ($now - $_[0]), 
		$_[1] 
		
		if $preconf -> {core_debug_profiling} > 0;
	
	return $now;

}

################################################################################

sub select_subset { return {} }

################################################################################

sub get_user {

	return if $_REQUEST {type} eq '_static_files';

	my $time = time;
	
	$_REQUEST {__suggest} or sql_do_refresh_sessions ();

	$time = __log_profilinig ($time, ' <refresh_sessions>');

	my $user = undef;

	if ($_REQUEST {__login}) {
		$user = sql_select_hash ("SELECT * FROM $conf->{systables}->{users} WHERE login = ? AND password = PASSWORD(?) AND fake <> -1", $_REQUEST {__login}, $_REQUEST {__password});
		$user -> {id} or undef $user;
	}
	
	my $peer_server = undef;

	if ($r -> headers_in -> {'User-Agent'} =~ m{^Eludia/.*? \((.*?)\)}) {

		$peer_server = $1;

		my $local_sid = sql_select_scalar ("SELECT id FROM $conf->{systables}->{sessions} WHERE peer_id = ? AND peer_server = ?", $_REQUEST {sid}, $peer_server);

		unless ($local_sid) {
		
			my $user = peer_query ($peer_server, {__whois => $_REQUEST {sid}});
			
			my $role = $conf -> {peer_roles} -> {$peer_server} -> {$user -> {role}} || $conf -> {peer_roles} -> {$peer_server} -> {''};
			
			$role or die ("Peer role $$user{role} is undefined for the server $peer_server\n");
			
			my $id_role = sql_select_scalar ("SELECT id FROM $conf->{systables}->{roles} WHERE name = ?", $role);

			$id_role or die ("Role not found: $role\n");

			my $id_user = 
			
				sql_select_scalar ("SELECT id FROM $conf->{systables}->{users} WHERE IFNULL(peer_id, 0) = ? AND peer_server = ?", 0 + $user -> {id}, $peer_server) ||
				
				sql_do_insert ($conf->{systables}->{users}, {
					fake        => -128,
					peer_id     => $user -> {id},
					peer_server => $peer_server,
				});
				
			sql_do ("UPDATE $conf->{systables}->{users} SET label = ?, id_role = ?, mail = ?  WHERE id = ?", $user -> {label}, $id_role, $user -> {mail}, $id_user);
			
			while (1) {
				$local_sid = int (time * rand);
				last if 0 == sql_select_scalar ("SELECT COUNT(*) FROM $conf->{systables}->{sessions} WHERE id = ?", $local_sid);
			}

			sql_do ("DELETE FROM $conf->{systables}->{sessions} WHERE id_user = ?", $id_user);
			
			sql_do ("INSERT INTO $conf->{systables}->{sessions} (id, id_user, peer_id, peer_server) VALUES (?, ?, ?, ?)", $local_sid, $id_user, $_REQUEST {sid}, $peer_server);
					
		}
		
		$_REQUEST {sid} = $local_sid;
		
	}	

	$user ||= sql_select_hash (<<EOS, $_REQUEST {sid}) if $_REQUEST {sid};
		SELECT
			$conf->{systables}->{users}.*
			, $conf->{systables}->{roles}.name AS role
			, $conf->{systables}->{roles}.label AS role_label
			, $conf->{systables}->{sessions}.id_role AS session_role
			, $conf->{systables}->{sessions}.ip
			, $conf->{systables}->{sessions}.tz_offset
			, $conf->{systables}->{sessions}.ip_fw
			, $conf->{systables}->{sessions}.id_role AS session_id_role
		FROM
			$conf->{systables}->{sessions}
			, $conf->{systables}->{users}
			, $conf->{systables}->{roles}
		WHERE
			$conf->{systables}->{sessions}.id_user = $conf->{systables}->{users}.id
			AND $conf->{systables}->{users}.id_role = $conf->{systables}->{roles}.id
			AND $conf->{systables}->{sessions}.id = ?
			AND $conf->{systables}->{users}.fake <> -1
EOS

	my $session = {
		id      => $_REQUEST {sid},
		ip      => $user -> {ip},
		ip_fw   => $user -> {ip_fw},
		id_role => $user -> {session_id_role},
	};
	
	if ($session -> {ip}) {	
		$session -> {ip}    eq $ENV {REMOTE_ADDR}          or return undef;
		$session -> {ip_fw} eq $ENV {HTTP_X_FORWARDED_FOR} or return undef;	
	}	
	elsif ($user && $user -> {id}) {
		sql_do (
			"UPDATE $conf->{systables}->{sessions} SET ip = ?, ip_fw = ? WHERE id = ?",
			$ENV {REMOTE_ADDR},
			$ENV {HTTP_X_FORWARDED_FOR}, $_REQUEST {sid},
		);
	}
	
	if ($user && $user -> {id} && $session -> {id_role}) {
		$user -> {session_role_name} = sql_select_scalar ("SELECT name FROM $conf->{systables}->{sessions}, $conf->{systables}->{roles} WHERE $conf->{systables}->{sessions}.id_role = $conf->{systables}->{roles}.id AND $conf->{systables}->{sessions}.id = ?", $_REQUEST {sid});
	}

	if ($user && $user -> {session_role}) {
		$user -> {id_role} = $user -> {session_role};
		$user -> {role} = $user -> {session_role_name};
	}

	if ($user && $_REQUEST {role} && ($conf -> {core_multiple_roles} || $preconf -> {core_multiple_roles})) {

		my $id_role = sql_select_scalar (<<EOS, $user -> {id}, $_REQUEST {role});
			SELECT
				roles.id
			FROM
				roles,
				map_roles_to_users
			WHERE
				map_roles_to_users.id_user = ?
				AND roles.id=map_roles_to_users.id_role
				AND roles.name = ?
EOS
		
		$user -> {role} = $_REQUEST {role} if ($id_role);
		
		if ($id_role) {

			my $id_session = sql_select_scalar ("SELECT id FROM $conf->{systables}->{sessions} WHERE id_user = ? AND id_role = ?", $user -> {id}, $id_role);

			if ($id_session) {
				$_REQUEST {sid} = $id_session;
			} else {
				while (1) {
					$_REQUEST {sid} = int (time () * rand ());
					last if 0 == sql_select_scalar ("SELECT COUNT(*) FROM $conf->{systables}->{sessions} WHERE id = ?", $_REQUEST {sid});
				}
				sql_do ("INSERT INTO $conf->{systables}->{sessions} (id, id_user, id_role) VALUES (?, ?, ?)", $_REQUEST {sid}, $user -> {id}, $id_role);
				sql_do_refresh_sessions ();
			}

			delete $_REQUEST {role};

			$user -> {redirect} = 1;
		}
	}

	$user -> {label} ||= $user -> {name} if $user;
	
	$user -> {peer_server} = $peer_server;
		
	return $user -> {id} ? $user : undef;

}

################################################################################

sub is_recyclable {

	my ($table_name) = @_;
	
	return 0 if $table_name eq $conf -> {systables} -> {log};
	return 0 if $table_name eq $conf -> {systables} -> {sessions};
	
	if (ref $conf -> {core_recycle_ids} eq ARRAY) {
		$conf -> {core_recycle_ids} = {map {$_ => 1} @{$conf -> {core_recycle_ids}}}
	}

	return 1 if $conf -> {core_recycle_ids} == 1 || $conf -> {core_recycle_ids} -> {$table_name};
	return 0;

}

################################################################################

sub interpolate {
	my $template = $_[0];
	my $result = '';
	my $code = "\$result = <<EOINTERPOLATION\n$template\nEOINTERPOLATION";
	eval $code;
	$result .= $@;
	return $result;
}

################################################################################

sub get_filehandle {

	return ref $apr eq 'Apache2::Request' ? $apr -> upload ($_[0]) -> upload_fh : $apr -> upload ($_[0]) -> fh;	

}

################################################################################

sub esc {

	my ($options) = @_;
	
	$options -> {kind} = 'js';

	redirect (esc_href (), $options);

}

################################################################################

sub redirect {

	my ($url, $options) = @_;

	if (ref $url eq HASH) {
		$url = create_url (%$url);
	}

	if ($_REQUEST {__uri} ne '/' && $url =~ m{^\/\?}) {
		$url =~ s{^\/\?}{$_REQUEST{__uri}\?};
	}

	$options ||= {};
	$options -> {kind} ||= 'http';
	$options -> {kind}   = 'http' if ($_REQUEST {__windows_ce} && $_REQUEST {select});

	if ($options -> {kind} eq 'http' || $options -> {kind} eq 'internal') {

		$r -> status ($options -> {status} || 302);
		$r -> headers_out -> {'Location'} = $url;
		$r -> send_http_header unless (MP2);
		$_REQUEST {__response_sent} = 1;
		return;
		
	}

	if ($options -> {kind} eq 'js') {
	
		$options -> {url} = $url;	
		out_html ({}, draw_redirect_page ($options));
		$_REQUEST {__response_sent} = 1;
		return;
		
	}
	
}

################################################################################

sub log_action_start {

	our $__log_id = $_REQUEST {id};
	our $__log_user = $_USER -> {id};
	
	$_REQUEST {error} = substr ($_REQUEST {error}, 0, 255);
	
	$_REQUEST {_id_log} = sql_do_insert ($conf -> {systables} -> {log}, {
		id_user => $_USER -> {id}, 
		type => $_REQUEST {type}, 
		action => $_REQUEST {action}, 
		ip => $ENV {REMOTE_ADDR}, 
		error => $_REQUEST {error}, 
		ip_fw => $ENV {HTTP_X_FORWARDED_FOR},
		fake => 0,
		mac => (!$preconf -> {core_no_log_mac}) ? get_mac () : '',
	});
		
}

################################################################################

sub log_action_finish {
	
	$_REQUEST {_params} = $_REQUEST {params} = Data::Dumper -> Dump ([\%_OLD_REQUEST], ['_REQUEST']);
	$_REQUEST {_params} =~ s/ {2,}/\t/g;
		
	$_REQUEST {error} = substr ($_REQUEST {error}, 0, 255);
	$_REQUEST {_error}  = $_REQUEST {error};
	$_REQUEST {_id_object} = $__log_id || $_REQUEST {id} || $_OLD_REQUEST {id};
	$_REQUEST {_id_user} = $__log_user || $_USER -> {id};
	
	sql_do_update ($conf -> {systables} -> {log}, ['params', 'error', 'id_object', 'id_user'], {id => $_REQUEST {_id_log}, lobs => ['params']});
	delete $_REQUEST {params};
	delete $_REQUEST {_params};
	
}

################################################################################

sub delete_file {

	unlink $r -> document_root . $_[0];

}

################################################################################

sub download_file_header {

	my ($options) = @_;	

	$r -> status (200);

	$options -> {file_name} =~ s{.*\\}{};
		
	my $type = 
		$options -> {charset} ? $options -> {type} . '; charset=' . $options -> {charset} :
		$options -> {type};

	$type ||= 'application/octet-stream';

	my $path = $r -> document_root . $options -> {path};
	
	my $start = 0;
	
	my $content_length = $options -> {size};
	
	if (!$content_length && $options -> {path}) {
	
		$content_length = -s $r -> document_root . $options -> {path};
	
	}
		
	my $range_header = $r -> headers_in -> {"Range"};

	if ($range_header =~ /bytes=(\d+)/) {
		$start = $1;
		my $finish = $content_length - 1;
		$r -> headers_out -> {'Content-Range'} = "bytes $start-$finish/$content_length";
		$content_length -= $start;
	}

	$r -> content_type ($type);
	$options -> {file_name} =~ s/\?/_/g unless ($ENV {HTTP_USER_AGENT} =~ /MSIE 7/);
	$options -> {no_force_download} or $r -> headers_out -> {'Content-Disposition'} = "attachment;filename=" . $options -> {file_name}; 
	
	if ($content_length > 0) {
		$r -> headers_out -> {'Content-Length'} = $content_length;
		$r -> headers_out -> {'Accept-Ranges'} = 'bytes';
	} 
	
	delete $r -> headers_out -> {'Content-Encoding'};
	
	$r -> send_http_header () unless (MP2);

	$_REQUEST {__response_sent} = 1;
	
	return $start;

}

################################################################################

sub download_file {

	my ($options) = @_;	

	my $path = $r -> document_root . $options -> {path};

	$_REQUEST {__out_html_time} = time;

	my $start = download_file_header (@_);
	
	if (MP2) {
		$r -> sendfile ($path, $start);
	} else {
		open (F, $path) or die ("Can't open file $path: $!");
		seek (F, $start, 0);
		$r -> send_fd (F);
		close F;
	}
	
}

################################################################################

sub upload_files {

	my ($options) = @_;
		
	my @nos = ();
	
	foreach my $k (keys %_REQUEST) {

		$k =~ /^_$options->{name}_(\d+)$/ or next;
		
		$_REQUEST {$k} or next;
		
		push @nos, $1;

	}

	my @result = ();

	my $name = $options -> {name};

	foreach my $no (sort {$a <=> $b} @nos) {
		
		$options -> {name} = "${name}_${no}";
	
		push @result, upload_file ($options);
	
	}
	
	return \@result;

}

################################################################################

sub upload_file {
	
	my ($options) = @_;
	
	my $upload = $apr -> upload ('_' . $options -> {name});
	
	my ($fh, $filename, $file_size, $file_type);

	if (ref $apr eq 'Apache2::Request') {
	
		return undef unless ($upload and $upload -> upload_size > 0);
		
		$fh = $upload -> upload_fh;
		$filename = $upload -> upload_filename;
		$file_size = $upload -> upload_size;
		$file_type = $upload -> upload_type;
		  
	} else {
	
		return undef unless ($upload and $upload -> size > 0);

		$fh = $upload -> fh;
		$filename = $upload -> filename;
		$file_size = $upload -> size;
		$file_type = $upload -> type;

		
	}

	my ($y, $m, $d) = split /-/, sprintf ('%04d-%02d-%02d', Date::Calc::Today);

	$options -> {dir} ||= 'upload/images';

	my $dir = $r -> document_root . "/i/$$options{dir}";

	foreach my $subdir ('', $y, $m, $d) {
		$dir .= "/$subdir" if $subdir;
		-d $dir or mkdir $dir;
	}

	$filename =~ /[A-Za-z0-9]+$/;
	my $path = "/i/$$options{dir}/$y/$m/$d/" . time . '-' . (++ $_REQUEST {__files_cnt}) . "-$$.$&";
	
	my $real_path = $r -> document_root . $path;
	
	open (OUT, ">$real_path") or die "Can't write to $real_path: $!";
	binmode OUT;
		
	my $buffer = '';
	my $file_length = 0;
	while (my $bytesread = read ($fh, $buffer, 1024)) {
		$file_length += $bytesread;
		print OUT $buffer;
	}
	close (OUT);
	
	$filename =~ s{.*\\}{};
	
	return {
		file_name => $filename,
		size      => $file_size,
		type      => $file_type,
		path      => $path,
		real_path => $real_path,
	}
	
}

################################################################################

sub add_vocabularies {

	my ($item, @items) = @_;

	while (@items) {
	
		my $name = shift @items;
		
		my $options = {};
		
		if (@items > 0 && ref $items [0] eq HASH) {
		
			$options = shift @items;
		
		}
		
		$options -> {item} = $item;
		
		my $table_name = $options -> {name} || $name;
		
		$item -> {$name} = sql_select_vocabulary ($table_name, $options);
		
		if ($options -> {ids}) {
			
			ref $options -> {ids} eq HASH or $options -> {ids} = {table => $options -> {ids}};
			
			$options -> {ids} -> {from}  ||= 'id_' . en_unplural ($_REQUEST {type});
			$options -> {ids} -> {to}    ||= 'id_' . en_unplural ($table_name);
			
			$options -> {ids} -> {name}  ||= $options -> {ids} -> {to};
		
			$item -> {$options -> {ids} -> {name}} = [sql_select_col ("SELECT $options->{ids}->{to} FROM $options->{ids}->{table} WHERE fake = 0 AND $options->{ids}->{from} = ?", $item -> {id})];
		
		}
		
	}
	
	return $item;

}

################################################################################

sub set_cookie {

	if (ref $apr eq "${Apache}::Request") {

		eval "require ${Apache}::Cookie";
		my $cookie = "${Apache}::Cookie" -> new ($r, @_);
		$r->err_headers_out->add("Set-Cookie" => $cookie->as_string);		

	}
	else {
		require CGI::Cookie;
		my $cookie = CGI::Cookie -> new (@_);
		$r -> headers_out -> {'Set-Cookie'} = $cookie -> as_string;
	}

}

################################################################################

sub get_mac {

	my ($ip) = @_;	
	$ip ||= $ENV {REMOTE_ADDR};

	my $cmd = $^O eq 'MSWin32' ? 'arp -a' : 'arp -an';
	my $arp = '';
	
	eval {$arp = lc `$cmd`};
	$arp or return '';
	
	foreach my $line (split /\n/, $arp) {

		$line =~ /\($ip\)/ or next;

		if ($line =~ /[0-9a-f]{2}\:[0-9a-f]{2}\:[0-9a-f]{2}\:[0-9a-f]{2}\:[0-9a-f]{2}\:[0-9a-f]{2}/) {
			return $&;
		}
		
	}
	
	return '';

}

################################################################################

sub del {
	
	return () if $_REQUEST {__no_navigation};
	
	my ($data) = @_;

	return () if $data -> {no_del};

	return (
		{
			preset  => 'delete',
			href    => {action => 'delete'},
			target  => 'invisible',
			off     => $data -> {fake} != 0 || !$_REQUEST {__read_only} || $_REQUEST {__popup},
		},		
		{
			preset  => 'undelete',
			href    => {action => 'undelete'},
			target  => 'invisible',
			off     => $data -> {fake} >= 0 || !$_REQUEST {__read_only} || $_REQUEST {__popup} || $conf -> {core_undelete_to_edit},
		},
		{
			preset  => 'undelete',
			href    => create_url() . "&__edit=1",
			off     => $data -> {fake} >= 0 || !$_REQUEST {__read_only} || $_REQUEST {__popup} || !$conf -> {core_undelete_to_edit},
		},
	);

}

################################################################################

sub dt_iso {

	my @ymd = map {split /\D+/} @_;
	
	@ymd = reverse @ymd if $ymd [0] < 1000;
		
	return sprintf ('%04d-%02d-%02d', @ymd);

}

################################################################################

sub dt_dmy {

	my @dmy = map {split /\D+/} @_;
	
	@dmy = reverse @dmy if $dmy [2] < 1000;
	
	my $c = substr $i18n -> {_format_d}, 2, 1; 
	
	$c ||= '.';
	
	return sprintf ("\%02d${c}\%02d${c}\%02d", @dmy);

}

################################################################################

sub fill_in {

   	$conf -> {lang} ||= 'RUS';   	

   	$conf -> {i18n} ||= {};

   	fill_in_button_presets (

   		ok => {
   			icon    => 'ok',
   			label   => 'ok',
   			hotkey  => {code => ENTER, ctrl => 1},
   			confirm => $conf -> {core_no_confirm_submit} ? undef : 'confirm_ok',
   		},
   		
   		cancel => {
   			icon   => 'cancel',
   			label  => 'cancel',
   			hotkey => {code => ESC},
   			confirm => confirm_esc,
   			preconfirm => 'is_dirty',
   		},

   		edit => {
   			icon   => 'edit',
   			label  => 'edit',
   			hotkey => {code => F4},
   		},

   		choose => {
   			icon   => 'choose',
   			label  => 'choose',
   			hotkey => {code => ENTER, ctrl => 1},
   		},

   		'close' => {
   			icon   => 'ok',
   			label  => 'close',
   			hotkey => {code => ESC},
   		},
   		
   		back => {
			icon => 'back', 
			label => 'back', 
			hotkey => {code => F11 },
		},

   		next => {
			icon => 'next',
			label => 'next',
   			hotkey => {code => F12},
		},

   		delete => {
   			icon    => 'delete',
   			label   => 'delete',
   			hotkey  => {code => DEL, ctrl => 1},
   			confirm => 'confirm_delete',
   		},

   		undelete => {
   			icon    => 'create',
   			label   => 'undelete',
   			confirm => 'confirm_undelete',
   		},

   	);
   	
   	fill_in_i18n ('RUS', {
   		_charset                 => 'windows-1251',
   		_calendar_lang           => 'ru',
   		_format_d		 => '%d.%m.%Y',
   		_format_dt		 => '%d.%m.%Y  %k:%M',
		Exit                     => 'Выход',
		toolbar_pager_empty_list => 'список пуст',		
		toolbar_pager_of         => ' из ',
		confirm_ok               => 'Сохранить данные?',
		confirm_delete           => 'Удалить эту запись, вы уверены?',
		confirm_undelete         => 'Восстановить эту запись, вы уверены?',
		confirm_esc              => 'Уйти без сохранения данных?',
		ok                       => 'применить', 
		cancel                   => 'вернуться', 
		choose                   => 'выбрать', 
		delete                   => 'удалить', 
		undelete                 => 'восстановить', 
		edit                     => 'редактировать', 
		'close'                  => 'закрыть',
		back                     => '&lt;&lt; назад',
		'next'                   => 'продолжить &gt;&gt;',		
		User                     => 'Пользователь',
		not_logged_in		 => 'не определён',
		Print                    => 'Печать',
		F1                       => 'F1: Справка',
		Select                   => 'Выбрать',
		yes                      => 'Да', 
		no                       => 'Нет', 
		name                     => 'имя', 
		password                 => 'пароль', 
		log_on                   => 'готово', 
		today                    => 'Сегодня', 
		confirm_open_vocabulary  => 'Открыть окно редактирования справочника?',
		confirm_close_vocabulary => 'Вы выбрали',
		session_terminated       => 'Сессия завершена',
		save_or_cancel           => 'Пожалуйста, сначала сохраните данные (Ctrl-Enter) или отмените ввод (Esc)',
		infty                    => '&infin;', 
		voc                      => ' справочник...',
		wrong_month              => 'Некорректно задан месяц',
		wrong_day                => 'Некорректно задан день',
		wrong_hour               => 'Некорректно заданы часы',
		wrong_min                => 'Некорректно заданы минуты',
		wrong_sec                => 'Некорректно заданы секунды',
		hta_confirm              => 'Вы обратились к WEB-приложению по прямому адресу, как к публичному сайту. При этом окно браузера содержит панели, не нужные для работы, а настройки безопасности могут оказаться несовместимыми с логикой программы. Для более удобной работы с WEB-приложением мы рекомендуем установить на вашей рабочей станции специальный файл (HTML Application). Выполнить установку?',
		months			 => [qw(
			января
			февраля
			марта
			апреля
			мая
			июня
			июля
			августа
			сентября
			октября
			ноября
			декабря
		)],
   	});
   	
   	fill_in_i18n ('ENG', {
   		_charset                 => 'windows-1252',
   		_calendar_lang           => 'en',
   		_format_d		 => '%d.%m.%Y',
   		_format_dt		 => '%d.%m.%Y  %k:%M',
		Exit                     => 'Exit',
		toolbar_pager_empty_list => 'empty list',		
		toolbar_pager_of         => ' of ',
		confirm_ok               => 'Commit changes?',
		confirm_esc              => 'Cancel changes?',
		confirm_delete           => 'Delete record, are you sure?',
		confirm_undelete         => 'Restore record, are you sure',
		ok                       => 'ok', 
		cancel                   => 'cancel', 
		choose                   => 'choose', 
		delete                   => 'delete', 
		edit                     => 'edit', 
		'close'                  => 'close',
		back                     => '&lt;&lt; back',
		'next'                   => 'next &gt;&gt;',
		User                     => 'User',
		not_logged_in		 => 'not logged in',
		Print                    => 'Print',
		F1                       => 'F1: Help',
		Select                   => 'Select',
		yes                      => 'Yes', 
		no                       => 'No', 
		name                     => 'name', 
		password                 => 'password', 
		log_on                   => 'log on', 
		confirm_open_vocabulary  => 'Open the vocabulary window?',
		confirm_close_vocabulary => 'Your choice is',
		session_terminated       => 'Logged off',
		save_or_cancel           => 'Please save your data (Ctrl-Enter) or cancel pending input (Esc)',
		infty                    => '&infin;', 
		voc                      => ' vocabulary...',
		today                    => 'Today', 
		wrong_month              => 'Invalid month',
		wrong_day                => 'Invalid day',
		wrong_hour               => 'Invalid hours',
		wrong_min                => 'Invalid minutes',
		wrong_sec                => 'Invalid seconds',
		months			 => [qw(
			january
			february
			march
			april
			may
			june
			july
			august
			september
			october
			november
			december
		)],
   	});
	
   	fill_in_i18n ('FRE', {
   		_charset                 => 'windows-1252',
   		_calendar_lang           => 'fr',
   		_format_d		 => '%d/%m/%Y',
   		_format_dt		 => '%d/%m/%Y  %k:%M',
		Exit                     => 'Dйconnexion',
		toolbar_pager_empty_list => 'liste vide',
		toolbar_pager_of         => ' de ',
		confirm_ok               => 'Sauver des changements?',
		confirm_esc              => 'Quitter sans sauvegarde?',
		confirm_delete           => 'Supprimer cette fiche, vous кtes sыr(e) ?',
		confirm_undelete         => 'Restaurer cette fiche, vous кtes sыr(e) ?',
		ok                       => 'appliquer', 
		cancel                   => 'annuler', 
		choose                   => 'choisir', 
		delete                   => 'supprimer', 
		edit                     => 'rediger', 
		'close'                  => 'fermer',
		back                     => '&lt;&lt; pas prйcйdent',
		'next'                   => 'suite &gt;&gt;',
		User                     => 'Utilisateur',
		not_logged_in		 => 'indйfini',
		Print                    => 'Imprimer',
		F1                       => 'F1: Aide',
		Select                   => 'Sйlection',
		yes                      => 'Oui', 
		no                       => 'Non', 
		name                     => 'nom', 
		password                 => 'mot de passe', 
		log_on                   => 'connecter', 
		confirm_open_vocabulary  => 'Ouvrir le vocabulaire?',
		confirm_close_vocabulary => 'Vous avez choisi',
		session_terminated       => 'Dйconnectй',
		save_or_cancel           => "Veuillez sauvegarder vos donnйes (Ctrl-Enter) ou bien annuler l\\'opйration (Esc)",
		infty                    => '&infin;', 
		voc                      => ' vocabulaire...',
		today                    => "Aujourd'hui", 
		wrong_month              => 'Format de date inconnu',
		wrong_day                => 'Format de date inconnu',
		wrong_hour               => 'Format de date inconnu',
		wrong_min                => 'Format de date inconnu',
		wrong_sec                => 'Format de date inconnu',
		months			 => [qw(
			janvier
			fйvrier
			mars
			avril
			mai
			juin
			juillet
			aoыt
			sйptembre
			octobre
			novembre
			dйcembre
		)],
   	}); 
   	
   	$conf -> {__filled_in} = 1;

}

################################################################################

sub fill_in_i18n {

	my ($lang, $entries) = @_;
   	$conf -> {i18n} ||= {};
   	$conf -> {i18n} -> {$lang} ||= {};
	return if $conf -> {i18n} -> {$lang} -> {_is_filled};
	
	while (my ($key, $value) = each %$entries) {
		$conf -> {i18n} -> {$lang} -> {$key} ||= $value;
	}
	
	$conf -> {i18n} -> {$lang} -> {_page_title} ||= $conf -> {page_title};

	$conf -> {i18n} -> {$lang} -> {_is_filled} = 1;

};

################################################################################

sub fill_in_button_presets {

	my %entries = @_;
   	$conf -> {button_presets} ||= {};
	return if $conf -> {button_presets} -> {_is_filled};
	
	while (my ($key, $value) = each %entries) {
		$conf -> {button_presets} -> {$key} ||= $value;
	}
	
	$conf -> {button_presets} -> {_is_filled} = 1;

};

################################################################################

sub get_ids {

	my ($name) = @_;
	
	$name .= '_';
	
	my @ids = ();
	
	while (my ($key, $value) = each %_REQUEST) {
		$key =~ /$name(\d+)/ or next;
		push @ids, $1;
	}
	
	return @ids;	

}

################################################################################

sub get_page {}

################################################################################

sub json_dump_to_function {

	my ($name, $data) = @_;

	return "\n function $name () {\n return " . $_JSON -> encode ($data) . "\n}\n";

}

################################################################################

sub attach_globals {

	my ($from, $to, @what) = @_;
	
	$from =~ /::$/ or $from .= '::';
	$to   =~ /::$/ or $to   .= '::';

	*{"${to}$_"} = *{"${from}$_"} foreach (@what);

}

################################################################################

sub prev_next_n {

	my ($what, $where, $options) = @_;
	
	$options -> {field} ||= 'id';
	
	my $id = $what -> {$options -> {field}};

	my ($prev, $next) = ();
	
	for (my $i = 0; $i < @$where; $i++) {

		$where -> [$i] -> {$options -> {field}} == $id or next;
		
		$prev = $where -> [$i - 1] if $i;
		$next = $where -> [$i + 1];
		
		return ($prev, $next, $i);
	
	}
	
	return ();

}

################################################################################

sub tree_sort {

	my ($list, $options) = @_;
	
	my $id        = $options -> {id}        || 'id';
	my $parent    = $options -> {parent}    || 'parent';
	my $ord_local = $options -> {ord_local} || 'ord_local';
	my $ord       = $options -> {ord}       || 'ord';
	my $level     = $options -> {level}     || 'level';

	my $idx = {};
	
	my $len = length ('' . (0 + @$list));
		
	my $template = '%0' . $len . 'd';
	
	for (my $i = 0; $i < @$list; $i++) {
	
		$list -> [$i] -> {$ord_local} = sprintf ($template, $i);
		
		$idx -> {$list -> [$i] -> {$id}} = $list -> [$i];
	
	}

	foreach my $i (@$list) {
	
		my @parents_without_ord = ();
	
		$i -> {$ord}   = '';
		$i -> {$level} = 0;
	
		my $j = $i;
		
		while ($j) {
		
		 	if ($j -> {$ord}) {			
				$i -> {$ord}    = $j -> {$ord} . $i -> {$ord};
				$i -> {$level} += $j -> {$level};				
				last;			
			}
		
			$i -> {$ord} = $j -> {$ord_local} . $i -> {$ord};
			
			$i -> {$level} ++;
			
			$parents_without_ord [$level] = $j;
			
			$j = $idx -> {$j -> {$parent}};
		
		}
		
		for (my $level = 1; $level < @parents_without_ord; $level ++) {
		
			$parents_without_ord [$level] -> {$ord} = substr $i -> {$ord}, 0, $len * ($i -> {$level} - $level);
		
		}
	
	}
	
	return [sort {$a -> {$ord} cmp $b -> {$ord}} @$list];

}

################################################################################

sub load_template {

	my ($template_name, $file_name, $options) = @_;
	
	$template_name .= '.htm' unless $template_name =~ /\.\w{2,4}$/;

	my $root = $r -> document_root;	
	
	my $fn = $root . "/templates/$template_name";
	
	my $template = '';
	
	open (T, $fn) or die ("Can't open $fn: $!\n");
	
	binmode T;
	
	if ($template_name =~ /\.pm$/) {

		while (<T>) {
			$template .= $_;
		}

	}
	else {

		while (<T>) {
			s{\\}{\\\\}g;
			s{\@([^\{])}{\\\@$1}g;
			$template .= $_;
		}

	}

	close (T);
	
	return $template;

}

################################################################################

sub fill_in_template {

	return if $_REQUEST {__response_sent};

	my ($template_name, $file_name, $options) = @_;
	
	$options -> {no_print} ||= $_REQUEST {no_print};
	
	my $template = load_template (@_);

	my $result = interpolate ($template);
	
	$result =~ s{\n}{\r\n}gsm;
	
	return $result if ($options -> {no_print});	

	$r -> status (200);
	
	unless ($options -> {skip_headers}) {
	
		$r -> header_out ('Content-Disposition' => "attachment;filename=$file_name");

		if (
			($conf -> {core_gzip} or $preconf -> {core_gzip}) &&
			400 + length $result > $preconf -> {core_mtu} &&
			($r -> headers_in -> {'Accept-Encoding'} =~ /gzip/)
		) {
		
			$r -> content_encoding ('gzip');
							
			my $time = time;
			my $old_size = length $result;
			
			my $z;
			my $x = new Compress::Raw::Zlib::Deflate (-Level => 9, -CRC32 => 1);
			$x -> deflate ($result, $z) ;
			$x -> flush ($z) ;
			$result = "\37\213\b\0\0\0\0\0\0\377" . substr ($z, 2, (length $z) - 6) . pack ('VV', $x -> crc32, length $result);
			$_REQUEST {__is_gzipped} = 1;
			
			my $new_size = length $result;
	
			my $ratio = int (10000 * ($old_size - $new_size) / $old_size) / 100;
			
			__log_profilinig ($time, " <gzip: $old_size -> $new_size, $ratio%>");
	
		}

		$r -> send_http_header ('application/octet-stream');


	}
	
	$r -> print ($result);

	$_REQUEST {__response_sent} = 1;
	
	return $result;

}

################################################################################

sub vb {

	$_REQUEST {__vb_cnt} ++;
	
	my $key = "__vb_$_REQUEST{__vb_cnt}";
	
	exists $_REQUEST {$key} and return $_REQUEST {$key};
	
	my ($code) = @_;
	
	$code =~ /vb\s\=*/ism or $code = "vb = $code";
	
	my $inputs = '';
	my $length = 0;
	
	foreach my $k (keys %_REQUEST) {
		
		next if $k eq '__vb_cnt';
		
		my $v = $_REQUEST {$k};
		
		next if ref $v;
		next if $v eq '';
		next if $v eq 'lang';
		
		$length += length (uri_escape ($v));
		$length += length ($k);
		$length += 2;

		$v =~ s{\'}{&apos;}gsm;
		
		$inputs .= "<input type='hidden' name='$k' value='$v'>";		
		
	}
	
	my $method = $length > 1000 ? 'POST' : 'GET';
	
	out_html ({}, <<EOH);
<html>
	<head>
		<script language="vbscript">
			function vb ()
			  $code
			end function			
		</script>
		<script language="jscript">
			function l () {
				var f = document.forms['f'];
				f.elements['$key'].value = vb ();
				f.submit ();
			}
		</script>
	</head>
	<body onLoad="l()">
		<form name=f method=$method>
			<input type="hidden" name="__no_back" value="1">
			<input type="hidden" name="$key" value="">
			$inputs
		</form>
	</body>
</html>
EOH

	$_REQUEST {__response_sent} = 1;
	
	exit;

}

################################################################################

sub vb_yes {

	my ($message, $title) = @_;
	
	$title ||= '';
	
	return 6 == vb (qq{MsgBox ("$message", 4, "$title")});

}

################################################################################

sub defaults {

	my ($data, $context, %vars) = @_;
		
	my $names = "''";

	foreach my $key (keys %vars) {
	
		ref $vars {$key} or $vars {$key} = {};
		
		$vars {$key} -> {name} ||= $key;
		
		$names .= ",'$vars{$key}->{name}'";
	
	}
		
	my %def = ();
	
	sql_select_loop ("SELECT * FROM $conf->{systables}->{__defaults} WHERE fake = 0 AND context = ? AND name IN ($names)", sub {$def {$i -> {name}} = $i -> {value}}, $context);
	
	if ($data -> {fake} == $_REQUEST {sid}) {
	
		foreach my $key (keys %$data) {
		
			$data -> {$key} or delete $data -> {$key};
		
		}
	
	}
	
	foreach my $key (keys %vars) {
	
		my $name = $vars {$key} -> {name};
	
		if (exists $data -> {$key}) {
		
			if ($data -> {$key} ne $def {$name}) {
			
				sql_select_id ($conf -> {systables} -> {__defaults} => {

					fake    => 0,
					context => $context,
					name    => $name,
					-value  => $data -> {$key},

				}, ['context', 'name']);
			
			}
		
		}
		else {
		
			$data -> {$key} = $def {$name};
		
		}
		
		check_query () if $key eq 'id___query';
	
	}

}

1;
