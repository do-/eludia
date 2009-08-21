#############################################################################

sub wish_to_clarify_demands_for_tables {	

	my ($i, $options) = @_;
		
	my %def = (

		name => $i -> {name},

	);
	
	my %columns = %{$i -> {columns}};
	
	while (my ($k, $v) = each %columns) {
	
		$v -> {_PK} or next;
		
		$def {pk} = {name => $k, %$v};
		
		last;
	
	}
	
	%$i = %def;

}

################################################################################

sub wish_to_explore_existing_tables {

	my ($options) = @_;

	my $existing = {};

	sql_select_loop (
		
		q {
			SELECT 
				table_name 
			FROM 
				information_schema.tables 
			WHERE 
				table_catalog = db_name()
				AND table_type = 'BASE TABLE'
		},
		
		sub {

			$existing -> {lc $i -> {table_name}} = {};

		},

	);

	return $existing;

}

#############################################################################

sub wish_to_update_demands_for_tables {

	my ($old, $new, $options) = @_;

	foreach my $i ($old, $new) {
			
		%$i = map {$_ => $i -> {$_}} qw (name);

	}

}

#############################################################################

sub wish_to_schedule_modifications_for_tables {}

#############################################################################

sub wish_to_actually_create_tables {

	my ($items, $options) = @_;
	
	foreach my $i (@$items) {
	
		$i -> {pk} -> {_EXTRA} =~ s{auto_increment}{IDENTITY};
		
		sql_do (qq {CREATE TABLE $i->{name} ($i->{pk}->{name} $i->{pk}->{TYPE_NAME} $i->{pk}->{_EXTRA} PRIMARY KEY)});
		
	}

}

1;