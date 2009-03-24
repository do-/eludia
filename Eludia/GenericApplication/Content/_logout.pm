################################################################################

sub select__logout {

	sql_do ("DELETE FROM $conf->{systables}->{sessions} WHERE id = ?", $_REQUEST {sid});
	
	session_access_logs_purge ();

	redirect ('/?type=logon', {kind => 'js', target => '_top', label => $i18n -> {session_terminated}});

}

1;