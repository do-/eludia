off => !$conf -> {core_store_table_order},

columns => {
	parent        => {TYPE_NAME => 'int'},
	id_user       => {TYPE_NAME => 'int', COLUMN_DEF => 0, NULLABLE => 0},
	type          => 'string',
	dump          => {TYPE_NAME => 'longtext'},
	label         => 'string',
	order_context => 'string',
	id_table      => 'string',
},

keys => {
	ix => 'id_user,type,label,order_context',
},
