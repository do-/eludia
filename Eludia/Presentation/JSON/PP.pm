use JSON::PP;

#################################################################################

sub setup_json {

	our $_JSON ||= JSON::PP -> new -> allow_nonref (1) -> allow_blessed (1);

}

1;