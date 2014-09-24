use Eludia::Content::HTTP::API;

sub handler {

	my ($package, $app, $line) = caller ();

	$app =~ y{\\}{/};

	$app =~ s{/docroot/.*}{/};
	
	check_configuration_and_handle_request_for_application ($app);
	
}

1;