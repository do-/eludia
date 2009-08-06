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
		
		q {
		
			SELECT 
				pg_class.relname
				, pg_description.description
			FROM 
				pg_namespace
				LEFT JOIN pg_class ON (
					pg_class.relnamespace = pg_namespace.oid
					AND pg_class.relkind = 'r'
				)
				LEFT JOIN pg_description ON pg_description.objoid = pg_class.oid
			WHERE
				pg_namespace.nspname = current_schema()
		
		}, 
		
		sub {
		
			$existing -> {$i -> {relname}} = {
			
				name => $i -> {relname}, 
				
				REMARKS => $i -> {description}
				
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
	
		$i -> {REMARKS} =~ s{'}{''}g; #'

		sql_do (qq {COMMENT ON TABLE $i->{name} IS '$i->{REMARKS}'});

	}

}

#############################################################################

sub wish_to_actually_create_tables {

	my ($items, $options) = @_;
	
	foreach my $i (@$items) {

		my %name = map {$_ => 'OOC_' . Digest::MD5::md5_base64 ($_ . $i -> {name})} qw {pk seq trigger};
		
		if ($i -> {pk} -> {_EXTRA} =~ /auto_increment/) {
		
			$i -> {pk} -> {TYPE_NAME} = $i -> {pk} -> {TYPE_NAME} eq 'bigint' ? 'bigserial' : 'serial';

		}

		sql_do (qq {CREATE TABLE $i->{name} ($i->{pk}->{name} $i->{pk}->{TYPE_NAME} PRIMARY KEY)});

	}

	wish_to_actually_comment_tables ([grep {$_ -> {REMARKS}} @$items], $options);

}

1;