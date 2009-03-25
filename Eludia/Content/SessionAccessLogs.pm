
################################################################################

BEGIN {

	print STDERR " SessionAccessLogs.....................................";
	
	if ($conf -> {core_session_access_logs_dbtable}) {

		require Eludia::Content::SessionAccessLogs::DBTable;
		print STDERR "DBTable, ok.\n";

	} else {

		require Eludia::Content::SessionAccessLogs::File4k;
		print STDERR "DBTable, ok.\n";

	}

}

1;
