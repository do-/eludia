#############################################################################

sub wish_to_clarify_demands_for_tables {	

	my ($i, $options) = @_;

	my %def = (

		name    => $i -> {name},
		
		REMARKS => $i -> {REMARKS} || $i -> {label},

	);

	$def {name} =~ /^_/ or $def {name} = uc $def {name};
	
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
				user_tables.table_name
				, user_tab_comments.comments 
			FROM 
				user_tables 
				LEFT JOIN user_tab_comments ON user_tables.table_name = user_tab_comments.table_name
		}, 
		
		sub {
		
			$existing -> {$i -> {table_name}} = {
			
				name    => $i -> {table_name},
			
				REMARKS => $i -> {comments},
				
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

		sql_do (qq {COMMENT ON TABLE "$i->{name}" IS '$i->{REMARKS}'});
		
	}

}

#############################################################################

sub wish_to_actually_create_tables {

	my ($items, $options) = @_;
	
	foreach my $i (@$items) {

		my %name = map {$_ => sql_mangled_name ($_ . $i -> {name})} qw {pk seq trigger};

		sql_do (qq {CREATE TABLE "$i->{name}" ($i->{pk}->{name} NUMBER (10, 0) CONSTRAINT "$name{pk}" PRIMARY KEY)});
		
		$i -> {pk} -> {_EXTRA} =~ /auto_increment/ or next;
				
		sql_do (qq {CREATE SEQUENCE "$name{seq}" NOCACHE START WITH 1 INCREMENT BY 1 MINVALUE 1});

		sql_do (qq {
				CREATE TRIGGER "$name{trigger}" BEFORE INSERT ON "$i->{name}"
				FOR EACH ROW
				WHEN (new.$i->{pk}->{name} IS NULL)
				BEGIN
					SELECT "$name{seq}".nextval INTO :new.$i->{pk}->{name} FROM DUAL;
				END;		
		});

		sql_do (qq {ALTER TRIGGER "$name{trigger}" COMPILE});

		sql_do (qq {ALTER TABLE "$i->{name}" ENABLE ALL TRIGGERS});

	}
	
	wish_to_actually_comment_tables ([grep {$_ -> {REMARKS}} @$items], $options);

}

1;