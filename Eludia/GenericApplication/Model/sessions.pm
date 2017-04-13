columns => {

	id_user 	=> 'int',
	id_user_real    => 'int',
	id_role 	=> 'int',
	ts      	=> 'timestamp',

	ip 		=> 'string [15]',
	ip_fw 		=> 'string [15]',

	client_cookie 	=> 'string [255]',

},

keys => {
	ts => 'ts',
	client_cookie => 'client_cookie',
},
