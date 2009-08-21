#############################################################################

sub wish_to_actually_create_views {

	my ($items, $options) = @_;
	
	foreach my $i (@$items) {
	
		sql_do ("CREATE OR REPLACE VIEW $i->{name} ($i->{columns}) AS $i->{sql}");
		
	}

}

1;