################################################################################

BEGIN {

	require Eludia::Content::Memory::Dummy;

	if ($^O eq 'MSWin32') {
	
		eval "require Eludia::Content::Memory::MSWin32OLE";

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
		
			print STDERR sprintf ("\n\n* * * PANIC! Memory limit of %s MiB exceeded: have %s MiB. Loading failed.\n", $preconf -> {core_memory_limit}, $preconf -> {_} -> {memory} -> {first} >> 20);
			
			exit;
		
		}
	
		print STDERR ' (' . format_picture ($preconf -> {_} -> {memory} -> {first} >> 20, "### ### ### ### MiB), ok.\n");		
	
	}
	else {
	
		print STDERR "no memory measurement, ok. \n";
	
	}

}

1;