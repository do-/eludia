################################################################################

sub do_flush__benchmarks {

	my $benchmarks_table = sql_table_name ($conf->{systables}->{__benchmarks});

	sql_do ("TRUNCATE TABLE $benchmarks_table");
	
}

################################################################################

sub select__benchmarks {

	my $q = '%' . $_REQUEST {q} . '%';

	my $start = $_REQUEST {start} + 0;
	
	my $order = order ('mean DESC',
		ms            => 'ms  DESC',
		cnt           => 'cnt DESC',
		selected      => 'selected  DESC',
		mean_selected => 'mean_selected DESC',
		label         => 'label',
	);

	my $benchmarks_table = sql_table_name ($conf->{systables}->{__benchmarks});

	my ($_benchmarks, $cnt)= sql_select_all_cnt (<<EOS, $q);
		SELECT
			*
		FROM
			$benchmarks_table
		WHERE
			(label LIKE ?)
		ORDER BY
			$order
		LIMIT
			$start, $$conf{portion}
EOS

	return {
		_benchmarks => $_benchmarks,
		cnt         => $cnt,
		portion     => $$conf{portion},
	};
	
}

1;