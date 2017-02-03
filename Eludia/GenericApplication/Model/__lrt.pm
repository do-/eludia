columns => {
	id           => {TYPE_NAME => 'bigint', _EXTRA => 'auto_increment', _PK => 1},
	id_session   => {TYPE_NAME => 'bigint'},
	lrt_id       => 'string',
	label        => 'text',
	is_sent      => 'checkbox',
	is_error     => 'checkbox',
	href         => 'text',
},

keys => {
	ix => 'id_session, is_sent',
},
