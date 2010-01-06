package Eludia::Tie::FileDumpHash;

sub TIEHASH  {

	my ($package, $options) = @_;
	
	ref $options -> {path} eq CODE or die "Invalid {path} option\n";

	bless $options, $package;

}

sub FETCH {
	
	return $_ [0] -> {cache} -> {$_ [1]} ||= FETCH_ (@_);

}

sub FETCH_ {

	my ($options, $key) = @_;
	
	my $VAR1 = {};
	
	my $sql_types = $options -> {conf} -> {sql_types};

	foreach my $dir (&{$options -> {path}} ($key)) {
	
		$dir .= '/Model';
		
		-d $dir or next;

		my $path = "${dir}/${key}.pm";

		-f $path or next;
		
		my %remarks = ();

		my $VAR;
		open (I, $path) or die "Can't open '$path': $!\n";
		
		my $src = '';
		
		while (my $line = <I>) {
		
			$src .= $line;
			
			if ($line =~ /(\w+)\s*\=\>.*?\#\s*(.*?)\s*$/sm) {
			
				$remarks {$1} = $2;
							
			}
		
		}
		
		eval "package $options->{package};\n \$VAR = {$src}"; die $@ if $@;
		close I;
		
		next if exists $VAR -> {off} && $VAR -> {off};
		
		foreach my $column (values %{$VAR -> {columns}}) {
		
			ref $column or $column = {TYPE => $column};
			
			$column -> {TYPE} or next;
			
			my %options;

			if ($column -> {TYPE} =~ /^\s*(\w+)/) {
			
				$column -> {TYPE_NAME} = $1;
			
				%options = %{$sql_types -> {$1} ||= {TYPE_NAME => $1}};

				$options {FIELD_OPTIONS} -> {type} ||= $1;
			
			}

			if ($column -> {TYPE} =~ /\s*\(\s*(\w+)\s*\)\s*$/) {
			
				$column -> {TYPE_NAME} ||= 'int';

				$options {ref} = $1;
				
				$options {FIELD_OPTIONS} -> {data_source} ||= $1;
			
			}
			
			if ($column -> {TYPE} =~ /\s*\[\s*(\d+)(\s*\,\s*(\d+))?\s*\]\s*$/) {
			
				$options {COLUMN_SIZE} = $1;
				
				$options {FIELD_OPTIONS} -> {size} ||= $1;
				
				if ($3) {
				
					$options {DECIMAL_DIGITS} = $3;
					
					if ($options {FIELD_OPTIONS} -> {picture}) {
					
						my $tail = '#' x $3;
						
						$options {FIELD_OPTIONS} -> {picture} =~ s{\,.*}{,$tail};
					
					}
				
				}
			
			}

			$column = {%$column, %options};

		}
		
		if ($VAR ->{sql}) {

			$VAR -> {sql} =~ s/\s+/ /smg;

			$VAR -> {sql} =~s/^\s+//;
			
		}

		foreach my $column_name (keys %remarks) {
		
			exists $VAR -> {columns} -> {$column_name} or next;
			
			$VAR -> {columns} -> {$column_name} -> {REMARKS} ||= $remarks {$column_name};
			
		}

		foreach my $object (keys (%$VAR)) {

			if (ref $VAR -> {$object} eq HASH) {

				foreach my $key (keys %{$VAR -> {$object}}) {
					$VAR1 -> {$object} -> {$key} ||= $VAR -> {$object} -> {$key};
				}

			} 
			elsif (ref $VAR -> {$object} eq ARRAY) {

				$VAR1 -> {$object} ||= [];
				push @{$VAR1 -> {$object}}, @{$VAR -> {$object}};

			}
			elsif (!ref $VAR -> {$object}) {

				$VAR1 -> {$object} ||= $VAR -> {$object};

			}

		}

		$VAR1 -> {_src} ||= $src;

	}
	
	return $VAR1;

}

1;