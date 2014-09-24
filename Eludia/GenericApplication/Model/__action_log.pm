columns => {
	id          => {TYPE_NAME => 'bigint', _EXTRA => 'auto_increment', _PK => 1},
	id_log      => {TYPE_NAME => 'bigint'},
	pid         => {TYPE_NAME => 'bigint'},
	id_session  => {TYPE_NAME => 'bigint'},
	ts          => {TYPE_NAME => 'timestamp'},
	params_hash => {TYPE_NAME => 'text'},
	return_url  => {TYPE_NAME => 'text'},
	redirect_alert => {TYPE_NAME => 'text'},
},

keys => {
	ix => 'id_session',
},
