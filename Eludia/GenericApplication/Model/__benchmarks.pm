off => $preconf -> {core_debug_profiling} <= 1,

columns => {
	label    => {TYPE_NAME  => 'varchar', COLUMN_SIZE  => 255},
	cnt      => {TYPE_NAME  => 'bigint' , COLUMN_DEF => 0, NULLABLE => 0},
	ms       => {TYPE_NAME  => 'bigint' , COLUMN_DEF => 0, NULLABLE => 0},
	mean     => {TYPE_NAME  => 'bigint' , COLUMN_DEF => 0, NULLABLE => 0},
	selected => {TYPE_NAME  => 'bigint' , COLUMN_DEF => 0, NULLABLE => 0},
	mean_selected => {TYPE_NAME  => 'bigint' , COLUMN_DEF => 0, NULLABLE => 0},
},

keys => {
	label => 'label',
},
