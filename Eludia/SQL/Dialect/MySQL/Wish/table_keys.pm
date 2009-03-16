#############################################################################

sub wish_to_clarify_demands_for_table_keys {	

	my ($i, $options) = @_;
	
	$i -> {global_name} = $i -> {name};

	ref $i -> {parts} eq ARRAY or $i -> {parts} = [split /\,/, $i -> {parts}];
	
	foreach my $part (@{$i -> {parts}}) {
	
		$part = lc $part;
		
		$part =~ s{\s}{}gsm;
	
	}

}

################################################################################

sub wish_to_explore_existing_table_keys {

	my ($options) = @_;

	my $existing = {};

	sql_select_loop ("SHOW KEYS FROM $options->{table}", sub {
			
		my $part = $i -> {Column_name};
		
		$part .= '(' . $i -> {Sub_part} . ')' if $i -> {Sub_part};
		
		push @{$existing -> {lc $i -> {Key_name}}}, $part;

	});
	
	return $existing;

}

#############################################################################

sub wish_to_actually_create_table_keys {	

	my ($items, $options) = @_;
	
	sql_do ("ALTER TABLE $options->{table} " . (join ', ', map {"ADD KEY $_->{name} (@{[ join ', ', @{$_ -> {parts}} ]})"} @$items));
	
}

#############################################################################

sub wish_to_actually_alter_table_keys {

	my ($items, $options) = @_;

	sql_do ("ALTER TABLE $options->{table} " . (join ', ', map {"DROP KEY $_->{name}"} @$items));
	
	wish_to_actually_create_table_keys (@_);

}

1;