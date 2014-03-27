
columns => {
	id_user         => {TYPE_NAME => 'int', COLUMN_DEF => 0, NULLABLE => 0},
	id_table        => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
	type            => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
	id_col          => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
	width           => {TYPE_NAME => 'int', COLUMN_DEF => 0, NULLABLE => 0},
	height          => {TYPE_NAME => 'int', COLUMN_DEF => 0, NULLABLE => 0},
},

keys => {
	ix => 'id_user,type,id_table,id_col',
},
