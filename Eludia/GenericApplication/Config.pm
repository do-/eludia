################################################################################

sub fill_in {

	return if $conf -> {__filled_in};
	
	check_systables ();

	our $number_format ||= Number::Format -> new (%{$conf -> {number_format}});

   	fill_in_things (core_modules =>
   		
		json                 => 1,
		mail                 => 1,
		math_fixed_precision => 1,
		memory               => 1,
		queries              => 1,
		uri_escape           => 1,
		zlib                 => 1,
   	
	);

   	fill_in_things (sql_types =>
   	
		int      => {TYPE_NAME => 'int', FIELD_OPTIONS => {type => 'string'}},

		money    => {TYPE_NAME => 'decimal', COLUMN_SIZE => 10, DECIMAL_DIGITS => 2, FIELD_OPTIONS => {type => 'string', picture => '### ### ### ###,##'}},

		string   => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
   		
		checkbox => {TYPE_NAME => 'tinyint', NULLABLE => 0, COLUMN_DEF  =>  0 },
   		
		radio    => {TYPE_NAME => 'tinyint', NULLABLE => 0, COLUMN_DEF  => -1 },

		select   => {TYPE_NAME => 'int'},

		suggest  => {TYPE_NAME => 'int'},
   		
		text     => {TYPE_NAME => 'text'},

		ref      => {TYPE_NAME => 'int'},

   	);
   	
   	$preconf -> {auth} -> {sessions} -> {timeout}          ||= ($conf -> {auth} -> {sessions} -> {timeout} || 30);

   	$preconf -> {auth} -> {sessions} -> {cookie} -> {name} ||= ($conf -> {auth} -> {sessions} -> {cookie} -> {name} || 'sid');
   	
   	if (my $mc = $preconf -> {auth} -> {sessions} -> {memcached}) {
   	
   		require Cache::Memcached::Fast;
   		
   		$mc -> {connection} = new Cache::Memcached::Fast ($mc);
   	
   	}

   	$conf -> {__filled_in} = 1;

}

################################################################################

sub fill_in_things {

	my ($name, %entries) = @_;
	
   	my $h = ($conf -> {$name} ||= {});
   	
	return if $h -> {_is_filled};
	
	while (my ($key, $value) = each %entries) {
	
		$h -> {$key} ||= $value;
		
	}
	
	$h -> {_is_filled} = 1;

};

1;