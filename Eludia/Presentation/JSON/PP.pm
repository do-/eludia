use JSON::PP;

#################################################################################

sub setup_json {

	our $_JSON = $i18n -> {_charset} eq 'UTF-8' ?
		JSON::PP -> new -> allow_nonref (1) -> allow_blessed (1) :
		JSON::PP -> new -> latin1 (1) -> allow_nonref (1);


}

1;