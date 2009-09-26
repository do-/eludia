################################################################################

BEGIN {

	print STDERR " check_internal_module_memory..................";

	require Eludia::Content::Memory::Dummy;

	if ($^O eq 'MSWin32') {
	
		eval "require Eludia::Content::Memory::MSWin32OLE";

	}
	else {
	
		print STDERR " not yet implemented for this platform, sorry... ";
	
	}
	
	print STDERR ' (' . format_picture (($preconf -> {_} -> {memory} -> {first} = memory_usage ()) >> 20, "### ### ### ### MiB)\n");

}

1;