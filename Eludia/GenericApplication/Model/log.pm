columns => {

	dt		=> {TYPE_NAME => 'timestamp'},

	id_user		=> {TYPE_NAME => 'int'},
	ip		=> {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
	ip_fw		=> {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
	action		=> {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
	params		=> {TYPE_NAME => 'longtext'},
	error		=> {TYPE_NAME => 'longtext'},

	id_object	=> {TYPE_NAME => 'int',                         off => $preconf -> {_} -> {core_log} -> {version} ne 'v1'},
	type		=> {TYPE_NAME => 'varchar', COLUMN_SIZE => 255, off => $preconf -> {_} -> {core_log} -> {version} ne 'v1'},
	params		=> {TYPE_NAME => 'longtext',                    off => $preconf -> {_} -> {core_log} -> {version} ne 'v1'},

	href		=> {TYPE_NAME => 'varchar', COLUMN_SIZE => 255, off => $preconf -> {_} -> {core_log} -> {version} ne 'v2'},
	params		=> {TYPE_NAME => 'text',                        off => $preconf -> {_} -> {core_log} -> {version} ne 'v2'},

	mac		=> {TYPE_NAME => 'varchar', COLUMN_SIZE => 17,  off => $preconf -> {_} -> {core_log} -> {log_mac} == 0},

},