off => !$conf -> {core_session_access_logs_dbtable},

columns => {
	id         => {TYPE_NAME => 'bigint', _EXTRA => 'auto_increment', _PK => 1},
	id_session => {TYPE_NAME => 'bigint'},
	ts         => {TYPE_NAME => 'timestamp'},
	no         => {TYPE_NAME => 'int'},
	href       => {TYPE_NAME => 'text'},
},

keys => {
	ix => 'id_session,no',
	ix2 => 'id_session,href(255)',
},
