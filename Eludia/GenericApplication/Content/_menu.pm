sub do_click__menu {

	my $dt = dt_iso (Date::Calc::Today);
	
	sql_do ('UPDATE __menu_clicks SET cnt = cnt + 1 WHERE id = ?',
	
		sql_select_id (__menu_clicks => {
			-fake        => 0,
			id_user      => $_USER -> {id},
			name         => $_REQUEST {_name},
			dt           => $dt,
			cnt          => 0,
		}, ['id_user', 'name', 'dt'])	
	
	);

}

sub do_check__menu {
	
	sql_select_id (__menu => {
		-fake        => 0,
		id_user      => $_USER -> {id},
		name         => $_REQUEST {_name},
		-is_favorite => 1,
	}, ['id_user', 'name']);

}

sub do_uncheck__menu {
	
	sql_do ('UPDATE __menu SET is_favorite = ? WHERE id_user = ? AND name = ?', 0, $_USER -> {id}, $_REQUEST {_name});

}

1;