columns => {

	id            => {TYPE_NAME => 'bigint', _PK    => 1},

	id_user       => {TYPE_NAME => 'int'},
	id_user_real  => {TYPE_NAME => 'int', off => !$conf -> {core_delegation}},
	id_role       => {TYPE_NAME => 'int'},
	ts            => {TYPE_NAME => 'timestamp'},

	ip            => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
	ip_fw         => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},

	client_cookie => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},

	peer_server   => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255, off => 0 == %{$conf    -> {peer_roles}}},
	peer_id       => {TYPE_NAME => 'int',                         off => 0 == %{$conf    -> {peer_roles}}},

	tz_offset     => {TYPE_NAME => 'tinyint', COLUMN_DEF => 0, 	off => !$preconf -> {core_fix_tz}},

},

keys => {

	ts => 'ts',

},
