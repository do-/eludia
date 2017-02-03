
################################################################################

sub do_get___lrt {

	my $data = sql_select_all (
		"SELECT * FROM $conf->{systables}->{__lrt} WHERE id_session = ? AND lrt_id = ? AND is_sent = 0 ORDER BY id",
		$_REQUEST {sid},
		$_REQUEST {lrt_id},
	);

	if (@$data) {
		if ($data -> [-1] -> {href}) {
			sql_do (
				"DELETE FROM $conf->{systables}->{__lrt} WHERE id_session = ? AND lrt_id = ?",
				$_REQUEST {sid},
				$_REQUEST {lrt_id},
			);
		} else {
			my $ids = ids ($data);
			sql_do ("UPDATE $conf->{systables}->{__lrt} SET is_sent = 1 WHERE id IN ($ids)");
		}
	}

	out_json ([map {{label => $_ -> {label}, is_error => $_ -> {is_error} ? \1 : \0, href => $_ -> {href}}} @$data]);

}
