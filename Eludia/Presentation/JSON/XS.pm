use JSON::XS;

#################################################################################

sub setup_json {

	our $_JSON = JSON::XS -> new -> latin1 (1) -> allow_nonref (1);

}

1;