package Eludia::Tie::FileDumpHash;

sub TIEHASH  {

	my ($package, $options) = @_;
	
	ref $options -> {path} eq CODE or die "Invalid {path} option\n";

	bless $options, $package;

}

sub FETCH {
	
	return $_ [0] -> {cache} -> {$_ [1]} ||= FETCH_ (@_);

}

sub FIRSTKEY {

	my ($options) = @_;
	
	$options -> {LIST} = {};

	foreach my $dir (reverse grep {-d} map {"$_/Model"} &{$options -> {path}} ()) {
	
		opendir (DIR, $dir) || die "can't opendir $dir: $!";
								
		foreach (readdir (DIR)) {
		
			/\.pm$/ or next;
			
			$options -> {LIST} -> {$`} = 1;
		
		}
								
		closedir DIR;			
	
	}
	
	each %{$options -> {LIST}};

}

sub NEXTKEY {
		
	each %{$_ [0] -> {LIST}};

}

sub FETCH_ {

	my ($options, $key) = @_;
	
	my $VAR1 = {};
	
	my $sql_types = $options -> {conf} -> {sql_types};
	
	my @dirs = reverse &{$options -> {path}} ($key);

	my $__the_dir = ${"$options->{package}::__the_dir"} || '';
	
	push @dirs, $__the_dir
		unless grep {$_ eq $__the_dir} @dirs;

	foreach my $dir (@dirs) {
	
		$dir .= '/Model';

		-d $dir or next;
		
		my $name = $key;
		
		if (-f "$dir/core") {
		
			&{"$options->{package}::reverse_systables"} ();
				
			$name = ${"$options->{package}::conf"} -> {systables_reverse} -> {$key} || $name;
		
		}

		my $path = "${dir}/${name}.pm";

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
		
		eval qq{package $options->{package};\n# line 0 "$path"\n \$VAR = {$src}}; die $@ if $@;
		close I;
		
#		next if exists $VAR -> {off} && $VAR -> {off};
		
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
		
			my $value = $VAR -> {$object};

			if (ref $value eq HASH) {

				foreach my $key (keys %$value) {
				
					my $v = $value -> {$key};
					
					ref $v ne HASH or !exists $v -> {off} or !$v -> {off} or next;

					$VAR1 -> {$object} -> {$key} ||= $v;

				}

			} 
			elsif (ref $value eq ARRAY) {

				$VAR1 -> {$object} ||= [];

				push @{$VAR1 -> {$object}}, @$value;

			}
			elsif (!ref $value) {

				$VAR1 -> {$object} ||= $value;

			}

		}

		$VAR1 -> {_src} ||= $src;

	}
	
	return $VAR1;

}

1;