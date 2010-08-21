no warnings;

################################################################################

sub memory_usage {

    my $processes = $main::winmgmts_cimv2_object -> ExecQuery ("select * from Win32_Process where ProcessId=$$");

    foreach my $proc (Win32::OLE::in ($processes)) {    

        return $proc -> {WorkingSetSize};

    }

};

################################################################################

BEGIN {

	require Win32::OLE;

	$main::winmgmts_cimv2_object ||= Win32::OLE -> GetObject ('winmgmts:\\\\.\\root\\cimv2');
	
	loading_log 'Win32 OLE';

}

1;
