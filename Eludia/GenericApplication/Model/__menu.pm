columns => {
	id_user     => {TYPE_NAME => 'int'},
	name        => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
	is_favorite => {TYPE_NAME => 'int'},
},

keys => {
	id_user => 'id_user',
},