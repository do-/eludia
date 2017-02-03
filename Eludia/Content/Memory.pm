################################################################################

BEGIN {

	require Eludia::Content::Memory::Dummy;

	if ($^O eq 'MSWin32') {
	
		if (!$ENV {MOD_PERL}) {

			eval "require Eludia::Content::Memory::MSWin32OLE";

		}	

	}
	else {

		eval "require Proc::ProcessTable";

		if ($INC {'Proc/ProcessTable.pm'}) {

			eval "require Eludia::Content::Memory::ProcessTable";

		}
		else {

			eval "require Eludia::Content::Memory::PS";

		}

	}
	
	if ($preconf -> {_} -> {memory} -> {first} = memory_usage ()) {
	
		if (exists $preconf -> {core_memory_limit} && $preconf -> {_} -> {memory} -> {first} > $preconf -> {core_memory_limit} << 20) {
		
			loading_log sprintf ("\n\n* * * PANIC! Memory limit of %s MiB exceeded: have %s MiB. Loading failed.\n", $preconf -> {core_memory_limit}, $preconf -> {_} -> {memory} -> {first} >> 20);
			
			exit;
		
		}
	
		loading_log ' (' . format_picture ($preconf -> {_} -> {memory} -> {first} >> 20, "### ### ### ### MiB), ok.\n");		
	
	}
	else {
	
		loading_log "no memory measurement, ok. \n";
	
	}

}

1;