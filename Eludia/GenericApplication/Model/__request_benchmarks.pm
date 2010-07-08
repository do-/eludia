off => $preconf -> {core_debug_profiling} <= 2,

columns => {

	id_user	=> {TYPE_NAME => 'int'},
	dt	=> {TYPE_NAME => 'timestamp'},
	params	=> {TYPE_NAME => 'longtext'},
	ip =>     {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
	ip_fw =>  {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
	type =>   {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
	mac    => {TYPE_NAME  => 'varchar', COLUMN_SIZE => 17},

	connection_id		=> {TYPE_NAME => 'int'},
	connection_no		=> {TYPE_NAME => 'int'},

	request_time		=> {TYPE_NAME => 'int'},
	application_time	=> {TYPE_NAME => 'int'},
	sql_time		=> {TYPE_NAME => 'int'},
	response_time		=> {TYPE_NAME => 'int'},
	
	bytes_sent		=> {TYPE_NAME => 'int'},
	is_gzipped		=> {TYPE_NAME => 'tinyint'}, 

},

