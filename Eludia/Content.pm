no warnings;

use Eludia::Content::Auth;
use Eludia::Content::Dt;
use Eludia::Content::ModuleTools;
use Eludia::Content::Mbox;
use Eludia::Content::Handler;
use Eludia::Content::HTTP;
use Eludia::Content::Validators;
use Eludia::Content::Templates;
use Eludia::Content::Tie;
use Eludia::Content::Profiling;
use Eludia::Content::Watchdog;

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
					$totals_bottom [$j] -> {label}    = '�����';

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
					label    => '�����',
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

sub get_ids {

	my ($name) = @_;

	$name .= '_';

	my @ids = ();

	while (my ($key, $value) = each %_REQUEST) {
		$key =~ /$name(\-?\d+)/ or next;
		push @ids, $1;
	}

	return @ids;

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

sub merge_cells {

	my $options = shift;

	my @result;

	my $last_dump;

	foreach my $cell (@_) {

		my $dump = Dumper ($cell);

		if ($last_dump eq $dump) {

			$result [-1] -> {colspan} ||= 1;

			$result [-1] -> {colspan} ++;

		}
		else {

			push @result, Storable::dclone $cell;

			$last_dump = $dump;

		}

	}

	return @result;

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

################################################################################

sub user_agent {

	my $src = $r -> headers_in -> {'User-Agent'};

	my $result = {};

	if ($src =~ /MSIE (\d+\.\d+)/) {

		$result -> {msie} = $1;

	}

	if ($src =~ /Trident\/\d\..*rv:(\d+\.\d+)/) {

		$result -> {msie} = $1;

	}

	if ($src =~ /Windows NT (\d+\.\d+)/) {

		$result -> {nt} = $1;

	}

	if ($src =~ /MSOffice/i || $src =~ /Microsoft Office/ || $src =~ /Microsoft-WebDAV-MiniRedir/i) {

		$result -> {msoffice} = 1;

	}

	return $result;

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

sub get_user_subset_menu {

	my $content = {

		user => {

			label  => $_USER -> {label},

			subset => $_REQUEST {__subset} || $_USER -> {subset},

		},

		__subsets => $_SUBSET -> {items},

		__menu    => select_menu (),

	};

	return $content;

}


################################################################################

sub check_dbl_click_start {

	return
		if !$preconf -> {core_dbl_click_protection}
			|| substr($_REQUEST {type}, 0, 1) eq '_'
			|| $r -> headers_in -> {'X-Requested-With'} eq 'XMLHttpRequest'
			|| $_REQUEST {action} eq 'download';

	my $ids = sql_select_ids ("SELECT id FROM $conf->{systables}->{sessions}");

	sql_do ("DELETE FROM $conf->{systables}->{__action_log} WHERE id_session NOT IN ($ids) OR ts < DATE_SUB(NOW(), INTERVAL ? MINUTE)",
		$preconf -> {core_dbl_click_protection} + 0 || 2
	);

	my %r = (%_REQUEST_VERBATIM);

	my $params = Digest::MD5::md5_hex (Dumper (\%r));

	my $action_log = sql_select_hash (<<EOS, $_REQUEST {sid}, $params);
		SELECT
			*
		FROM
			$conf->{systables}->{__action_log}
		WHERE
			id_session = ?
		AND
			params_hash = ?
EOS

	if (!$action_log -> {id}) {
		sql_do ("INSERT INTO $conf->{systables}->{__action_log} (id_session, id_log, pid, params_hash, redirect_alert) VALUES (?, ?, ?, ?, ?)",
			$_REQUEST {sid},
			$_REQUEST {_id_log},
			$$,
			$params,
			$_REQUEST {__redirect_alert}
		);

		$_REQUEST {_id___action_log} = sql_last_insert_id ();

		return;
	}

	if ($action_log -> {return_url}) {

		redirect ($action_log -> {return_url}, {kind => 'js', label => $action_log -> {redirect_alert}});

		return;

	}

	my $n = 20;

	while (--$n) {

		my $is_request_done = sql_select_scalar ('SELECT LENGTH(' . ($preconf -> {_} -> {core_log} -> {version} ne 'v1' ? 'href' : 'params') . ") FROM $conf->{systables}->{log} WHERE id = ?", $action_log -> {id_log});

		if (!$is_request_done && $ENV {FCGI_ROLE}) {

			my $process_name = $0;

			my $duplicate_process_name = `ps h -p $action_log->{pid} -o cmd`;
			chomp ($duplicate_process_name);

			last
				if $process_name ne $duplicate_process_name;

		} else {

			last;

		}

		sleep (1);


	}

	if ($n < 19) {

		my $action_log = sql_select_hash ("SELECT * FROM $conf->{systables}->{__action_log} WHERE id = ?", $action_log -> {id});

		if ($action_log -> {return_url}) {

			redirect ($action_log -> {return_url}, {kind => 'js', label => $action_log -> {redirect_alert}});

			return;

		}

	}

	redirect ($_REQUEST {action} eq 'delete' ? esc_href () :
		{
			action => '',
			__last_scrollable_table_row => $_REQUEST {__last_scrollable_table_row},
		},
		{kind => 'js', label => $n == 0 ? $i18n -> {duplicate_request_isnt_done} : $i18n -> {duplicate_request}}
	);


}

################################################################################

sub check_dbl_click_finish {

	return
		unless $preconf -> {core_dbl_click_protection};


	sql_do ("UPDATE $conf->{systables}->{__action_log} SET return_url = ? WHERE id = ?", $_ [0], $_REQUEST {_id___action_log});


}


1;