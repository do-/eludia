#############################################################################

sub wish_to_adjust_options_for_tables {

	my ($options) = @_;
	
	$options -> {key} = ['name'];

	$options -> {default_storage_engine} = $preconf -> {db_default_storage_engine};

}

#############################################################################

sub wish_to_clarify_demands_for_tables {

	my ($i, $options) = @_;
		
	my %def = (

		name    => $i -> {name},
		
		REMARKS => $i -> {REMARKS} || $i -> {label},

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
		
		q {select table_name, table_comment from information_schema.tables where table_schema=database()}, 
		
		sub {

			$existing -> {$i -> {table_name}} = {
			
				name    => $i -> {table_name},
			
				REMARKS => length $i -> {table_comment} ? $i -> {table_comment} : undef,
				
			};
					
		},

	);

	return $existing;

}

#############################################################################

sub wish_to_update_demands_for_tables {

	my ($old, $new, $options) = @_;

	foreach my $i ($old, $new) {
			
		%$i = map {$_ => $i -> {$_}} qw (name REMARKS);

	}

}

#############################################################################

sub wish_to_schedule_modifications_for_tables {

	my ($old, $new, $todo, $options) = @_;

	push @{$todo -> {comment}}, $new;

}

#############################################################################

sub wish_to_actually_comment_tables {

	my ($items, $options) = @_;
	
	foreach my $i (@$items) {
	
		($i -> {REMARKS} ||= '') =~ s{'}{''}g; #'

		sql_do (qq {ALTER TABLE $i->{name} COMMENT '$i->{REMARKS}'});
		
	}

}

#############################################################################

sub wish_to_actually_create_tables {

	my ($items, $options) = @_;
	
	foreach my $i (@$items) {	
		
		sql_do (qq {CREATE TABLE $i->{name} ($i->{pk}->{name} INT $i->{pk}->{_EXTRA} PRIMARY KEY)} . ($options -> {default_storage_engine} ? qq { ENGINE=$options->{default_storage_engine}} : ''));
		
	}
	
	wish_to_actually_comment_tables ([grep {$_ -> {REMARKS}} @$items], $options);

}

1;