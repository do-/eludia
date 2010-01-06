columns => {

	id_role     => {TYPE_NAME => 'int'},
	subset      => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
	login       => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
	label       => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
	password    => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255, off => 0 +  %{$preconf -> {ldap}}},
	mail        => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255, off => 0 == %{$preconf -> {mail}}},

	peer_server => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255, off => 0 == %{$conf    -> {peer_roles}}},
	peer_id     => {TYPE_NAME => 'int',                         off => 0 == %{$conf    -> {peer_roles}}},
	
},