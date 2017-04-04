columns => {

	id_role     => {TYPE_NAME => 'int'},
	login       => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
	label       => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
	password    => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255, off => 0 +  %{$preconf -> {ldap}}},
	mail        => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255, off => 0 == %{$preconf -> {mail}}},
	
},