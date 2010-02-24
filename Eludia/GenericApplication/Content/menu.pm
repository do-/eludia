
################################################################################

sub do_serialize_menu {

	my $content = get_user_subset_menu ();
	
	$content -> {md5} = Digest::MD5::md5_hex (Dumper ($content));

	out_html ({}, $_JSON -> encode ($content));

}

1;