columns => {

	id_user 	=> {TYPE_NAME  => 'int'},
	id_user_real    => {TYPE_NAME => 'int', off => !$conf -> {core_delegation}},
	id_role 	=> {TYPE_NAME  => 'int'},
	ts      	=> {TYPE_NAME  => 'timestamp'},

	ip 		=> {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
	ip_fw 		=> {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},

	client_cookie 	=> {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
	
	tz_offset	=> {TYPE_NAME => 'tinyint', COLUMN_DEF => 0, 	off => !$preconf -> {core_fix_tz}},

},

keys => {

	ts => 'ts',
	client_cookie => 'client_cookie',

},
