################################################################################

BEGIN {

	require Eludia::Content::Memory::Dummy;

	if ($^O eq 'MSWin32') {
	
		eval "require Eludia::Content::Memory::MSWin32OLE";

	}
	
	if ($preconf -> {_} -> {memory} -> {first} = memory_usage ()) {
	
		print STDERR ' (' . format_picture ($preconf -> {_} -> {memory} -> {first} >> 20, "### ### ### ### MiB), ok.\n");		
	
	}
	else {
	
		print STDERR "no memory measurement, ok. \n";
	
	}

}

1;