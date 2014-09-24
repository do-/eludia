columns => {
	dt          => {TYPE_NAME => 'timestamp'},

	id_user     => {TYPE_NAME => 'int'},
	id_user_real=> {TYPE_NAME => 'int', off => !$conf -> {core_delegation}},
	ip          => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
	ip_fw       => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
	action      => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
	params      => {TYPE_NAME => 'longtext'},
	error       => {TYPE_NAME => 'longtext'},

	id_object   => {TYPE_NAME => 'int',                         off => $preconf -> {_} -> {core_log} -> {version} ne 'v1'},
	type        => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255, off => $preconf -> {_} -> {core_log} -> {version} ne 'v1'},

	params      => {
		TYPE_NAME => $preconf -> {_} -> {core_log} -> {version} eq 'v1' ? 'longtext' : 'text',
		off       => $preconf -> {_} -> {core_log} -> {version} ne 'v1' && $preconf -> {_} -> {core_log} -> {version} ne 'v2',
	},

	href        => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255, off => $preconf -> {_} -> {core_log} -> {version} ne 'v2'},

	mac         => {TYPE_NAME => 'varchar', COLUMN_SIZE => 17,  off => $preconf -> {_} -> {core_log} -> {log_mac} == 0},

},