#############################################################################

sub wish_to_actually_create_views {

	my ($items, $options) = @_;
	
	foreach my $i (@$items) {
	
		sql_do ("IF EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_NAME = '$i->{name}') DROP VIEW $i->{name}");

		sql_do ("CREATE VIEW [$i->{name}] ($i->{columns}) AS $i->{sql}");

	}

}

1;