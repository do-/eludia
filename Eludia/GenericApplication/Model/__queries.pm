off => !$conf -> {core_store_table_order},

columns => {
	parent      => {TYPE_NAME => 'int'},
	id_user     => {TYPE_NAME => 'int', COLUMN_DEF => 0, NULLABLE => 0},
	type        => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
	dump        => {TYPE_NAME => 'longtext'},
	label       => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
	order_context     => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
},

keys => {
	ix => 'id_user,type,label,order_context',
},
