#############################################################################

sub wish_to_adjust_options_for_table_columns {

	my ($options) = @_;
	
	$options -> {key} = ['name'];

}

#############################################################################

sub wish_to_clarify_demands_for_table_columns {	

	my ($i, $options) = @_;
	
	$i -> {REMARKS} ||= delete $i -> {label};

	exists $i -> {NULLABLE} or $i -> {NULLABLE} = $i -> {name} eq 'id' ? 0 : 1;

	exists $i -> {COLUMN_DEF} or $i -> {COLUMN_DEF} = undef;

	$i -> {TYPE_NAME} = uc $i -> {TYPE_NAME};

	if ($i -> {TYPE_NAME} eq 'NUMERIC') {
		
		$i -> {TYPE_NAME} = 'DECIMAL';
		
	}

	if ($i -> {TYPE_NAME} eq 'DECIMAL') {
	
		$i -> {COLUMN_SIZE}    ||= 10;
		
		$i -> {DECIMAL_DIGITS} ||= 0;
		
	}

	if ($i -> {TYPE_NAME} =~ /VARCHAR$/) {

		$i -> {COLUMN_SIZE} ||= 255;

	}

	if (!$i -> {NULLABLE} && !defined $i -> {COLUMN_DEF} && $i -> {name} ne 'id') {
	
		$i -> {COLUMN_DEF} = 
		
			$i -> {TYPE_NAME} =~ /INT$/     ? 0 : 
			$i -> {TYPE_NAME} eq 'DECIMAL'  ? 0 : 
			$i -> {TYPE_NAME} eq 'DATETIME' ? '1970-01-01' : 
			''
		
	}

	if (defined $i -> {COLUMN_DEF}) {

		$i -> {COLUMN_DEF} .= '';
		
	}

}

################################################################################

sub wish_to_explore_existing_table_columns {

	my ($options) = @_;

	my $existing = {};
	
	my $sql = sql_select_scalar (q {SELECT sql FROM sqlite_master WHERE type = 'table' AND name = ?}, $options -> {table});
	
	if ($sql =~ /CREATE\s+TABLE\s+\w+\s*\((.*)\)\s*$/smi) {

		$sql = $1;

	}
	
	my @tokens = split /(\,|(?<!\\)\')/, $sql;

	my @fields = ();

	my $is_literal = 0;
	
	foreach my $token (@tokens) {

		if (!@fields) {

			push @fields, $token;

			next;

		}

		if ($token eq "\'") {

			$is_literal = 1 - $is_literal;

			$fields [-1] .= $token;

			next;

		}

		if ($is_literal) {

			$fields [-1] .= $token;

			next;

		}

		if ($fields [-1] =~ /\([^\)]*$/sm) {

			$fields [-1] .= $token;

			next;

		}

		push @fields, $token;

	}
	
	foreach my $field (@fields) {

		$field =~ /^\s*(\w+)\s+/ or next;

		my $name = lc $1;

		$existing -> {$name} = my $r = {name => $name, SQL => $'};
		
		if ($r -> {SQL} =~ /^\s*(\w*)\s*/sm) {
		
			$r -> {TYPE_NAME} = uc $1;
			
			if ($' =~ /\((.*?)\)/) {
			
				($r -> {COLUMN_SIZE}, $r -> {DECIMAL_DIGITS}) = map {0 + $_} split /\,/, $1;
			
			}
			
		}
		
		$r -> {NULLABLE} = $r -> {SQL} =~ /NOT\s+NULL/ism ? 0 : 1;
		
		if ($r -> {SQL} =~ /DEFAULT\s\'(.*)\'/ism) {
		
			$r -> {COLUMN_DEF} = $1;

			$r -> {COLUMN_DEF} =~ s{\\\'}{\'}gsm;
		
		}

	}

	return $existing;

}

#############################################################################

sub __genereate_sql_fragment_for_column {

	my ($i) = @_;
	
	if (!$i -> {SQL}) {

		$i -> {SQL} = $i -> {TYPE_NAME} . (

			$i -> {TYPE_NAME} eq 'DECIMAL' ? " ($i->{COLUMN_SIZE}, $i->{DECIMAL_DIGITS})" :

			$i -> {TYPE_NAME} =~ /CHAR$/ ? " ($i->{COLUMN_SIZE})" :

			'');

		$i -> {SQL} .= $i -> {NULLABLE} ? '' : ' NOT NULL';

		if (defined $i -> {COLUMN_DEF}) {

			$i -> {COLUMN_DEF} =~ s{'}{''}g; #';

			$i -> {SQL} .= " DEFAULT '$i->{COLUMN_DEF}'";

		}

	}

	%$i = map {$_ => $i -> {$_}} qw (name SQL);

}

#############################################################################

sub wish_to_update_demands_for_table_columns {

	my ($old, $new, $options) = @_;
	
	__genereate_sql_fragment_for_column ($_) foreach ($old, $new);

	if ($new -> {name} eq 'id') {
	
		%$new = %$old;
	
	}

}

#############################################################################

sub wish_to_schedule_modifications_for_table_columns {

	my ($old, $new, $todo, $options) = @_;

	push @{$todo -> {create}}, $new;

}

#############################################################################

sub wish_to_actually_create_table_columns {	

	my ($items, $options) = @_;

	my %cols = %{wish_to_explore_existing_table_columns ($options)};
	
	my $column_names = join ', ', keys %cols;

	foreach my $i (@$items) {

		__genereate_sql_fragment_for_column ($i);
		
		$cols {$i -> {name}} = $i;

	}
	
	my @keys = sql_select_col ("SELECT sql from sqlite_master WHERE type = 'index' AND tbl_name = ?");
		
	sql_do ("CREATE TEMP TABLE __buffer AS SELECT * FROM $options->{table}");

	sql_do ("DROP TABLE $options->{table}");
	
	my $defs = '';
	
	my @timestamp_names;
	
	while (my ($name, $def) = each %cols) {
	
		push @timestamp_names, $name if $sql =~ /\s*TIMESTAMP/i;
	
		$defs .= ', ' if $defs;
	
		$defs .= "$name $def->{SQL}";
	
	}
	
	sql_do ("CREATE TABLE $options->{table} ($defs)");

	sql_do ("INSERT INTO $options->{table} ($column_names) SELECT $column_names FROM __buffer");
	
	sql_do ("DROP TABLE __buffer");

	sql_do ($_) foreach @keys;
	
	foreach my $name (@timestamp_names) {
	
		foreach my $event ('insert', 'update') {
		
			sql_do (qq {

				CREATE TRIGGER $options->{table}_${name}_timestamp_${event}_trigger AFTER ${event} ON $options->{table}
					BEGIN
						UPDATE $options->{table} SET ${name} = NOW() WHERE oid = new.oid;
					END;

			});

		}

	}

	sql_do ("VACUUM");

}

1;