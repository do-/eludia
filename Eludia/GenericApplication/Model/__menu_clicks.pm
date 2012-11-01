columns => {
	id_user     => {TYPE_NAME => 'int'},
	name        => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
	dt          => {TYPE_NAME => 'date'},
	cnt         => {TYPE_NAME => 'int'},
},

keys => {
	id_user => 'id_user,dt',
},