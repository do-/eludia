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
				
		prefix => 'defer#',
		
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

1;