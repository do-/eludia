columns => {
	id          => {TYPE_NAME => 'bigint', _EXTRA => 'auto_increment', _PK => 1},
	table_name  => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
	column_name => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
	id_from     => {TYPE_NAME => 'int'},
	id_to       => {TYPE_NAME => 'int'},
},

keys => {
	id_to => 'id_to',
},
