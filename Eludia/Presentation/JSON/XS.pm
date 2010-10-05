use JSON::XS;

#################################################################################

sub setup_json {

	our $_JSON = JSON::XS -> new -> allow_nonref (1);

}

1;