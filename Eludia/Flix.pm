################################################################################
#
# (flix_mirror ($a) cmp flix_mirror ($b)) === - ($b cmp $a)
#

sub flix_mirror {

	my ($s) = @_;
	
	my $result = '';
	
	for (my $i = 0; $i < length $s; $i ++) {
	
		$result .= chr (255 - ord (substr ($s, $i, 1)));
	
	}
	
	return $result;

}

################################################################################
#
# (flix_encode_field ($a) cmp flix_encode_field ($b)) === ($a <=> $b) for numbers
#

sub flix_encode_field {

	my ($s, $options) = @_;
	
	defined $s or $s = $options -> {null};
	defined $s or $s = ['-Inf'];

	if (ref $s eq ARRAY) {
		return '0' if $s -> [0] =~ /^\-/;
		return '9';
	}
	
	if ($s !~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/) {
		return '8' . $s;
	}
	else {
	
		if ($s == 0) {
			return '4';
		}
		elsif ($s == 1) {
			return '6';
		}
		elsif ($s == -1) {
			return '2';
		}
		else {
		
			my ($mant, $exp) = split /e\+?/, sprintf ('%e', $s);
			
			$exp  += 0;
			$mant += 0;
			
			my $result = 
				$exp >= 0 && $mant > 0 ? '7' :
				$exp <  0 && $mant > 0 ? '5' :
				$exp >= 0 && $mant < 0 ? '1' :
				                         '3' ;
			
			unless ($exp * $mant < 0) {
				$result .= (length $exp) - 1;
				$result .= $exp;				
			}
			else {
				$result .= flix_mirror ((length $exp) - 1);
				$result .= flix_mirror ($exp);				
			}

			if ($mant > 0) {
				$result .= $mant;
			}
			else {
				$result .= flix_mirror ($mant);
			}
			
		}
	
	}

}

################################################################################

sub flix_encode_record {

	my ($record, $fields) = @_;
	
	my $result = '';
	
	foreach my $field (@$fields) {
	
		ref $field eq HASH or $field => {name => $field};
		
		my $value = flix_encode_field ($record -> {$field -> {name}}, $field) . chr (0);
		
		$value = flix_mirror ($value) if $field -> {desc};
		
		$result .= $value;
	
	}
	
	return $result;

}

################################################################################

sub flix_reindex_record {

	my ($table, $id) = @_;
	
	my $flix_keys = $DB_MODEL -> {tables} -> {$table} -> {flix_keys};
	
	my @keys = keys %$flix_keys;
	
	return if @keys == 0;
	
	my $record = sql_select_hash ($table, $id);
	
	my @values = map {flix_encode_record ($record, $flix_keys -> {$_})} @keys;
	
	sql_do ('UPDATE ' . $table . ' SET ' . (join ', ', map {" $_ = ? "} @keys) . ' WHERE id = ?', @values, $id);

}

1;