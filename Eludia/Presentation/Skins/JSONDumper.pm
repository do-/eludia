package Eludia::Presentation::Skins::JSONDumper;

################################################################################

sub options {
	return {
		no_presentation => 1,
	};
}

################################################################################

sub draw_page {

	my ($_SKIN, $page) = @_;

	$_REQUEST {__content_type} = 'application/octet-stream';

	$r -> headers_out -> {'Content-Disposition'} = "attachment;filename=$_REQUEST{type}_$_REQUEST{id}.jsondump";

	$_JSON -> indent    (1);
	$_JSON -> canonical (1);
	$_JSON -> allow_blessed (1);
	$_JSON -> convert_blessed (1);

	*UNIVERSAL::TO_JSON = sub {
		my $b_obj = B::svref_2object( $_[0] );
		return    $b_obj->isa('B::HV') ? { %{ $_[0] } }
			: $b_obj->isa('B::AV') ? [ @{ $_[0] } ]
			: undef
		;
	};

   	my $dump = $_JSON -> encode ({
		REQUEST => \%_REQUEST,
		USER    => $_USER,
		data    => $page -> {content},								
	});
	
	$dump =~ s/\x0A/\x0D\x0A/g;
							
	return $dump;

}

################################################################################

sub draw_error_page {}

################################################################################

sub draw_redirect_page {}

1;
