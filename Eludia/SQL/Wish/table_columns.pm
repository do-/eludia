#############################################################################

sub __adjust_column_dimension {

	my ($new, $key, $value) = @_;
	
	$new -> {$key} >= $value or $new -> {$key} = $value;

}

#############################################################################

sub __adjust_column_dimensions_for_char {

	my ($old, $new) = @_;
	
	__adjust_column_dimension ($new, COLUMN_SIZE => $old -> {COLUMN_SIZE});

}

#############################################################################

sub __adjust_column_dimensions_for_decimal {

	my ($old, $new) = @_;

	__adjust_column_dimension ($new, DECIMAL_DIGITS => $old -> {DECIMAL_DIGITS});
			
	__adjust_column_dimension ($new, COLUMN_SIZE    => $old -> {COLUMN_SIZE} + ($new -> {DECIMAL_DIGITS} - $old -> {DECIMAL_DIGITS}));

}

#############################################################################

sub __adjust_column_dimensions {

	my ($old, $new, $options) = @_;

	(my $type = $old -> {TYPE_NAME}) eq $new -> {TYPE_NAME} or return;
	
	if    ($type =~ $options -> {char})    { __adjust_column_dimensions_for_char    ($old, $new) }
	elsif ($type eq $options -> {decimal}) { __adjust_column_dimensions_for_decimal ($old, $new) }

}

#############################################################################

sub wish_to_adjust_options_for_table_columns {

	my ($options) = @_;
	
	$options -> {key} = ['name'];

}

#############################################################################

sub wish_to_schedule_cleanup_for_table_columns {}

1;