columns => {
	name    => 'string [255]',
	size    => 'int',
	md5     => 'char [32]',
	dt_from => 'datetime',
	dt_to   => 'datetime',
	is_ok   => 'int = 0',
	err     => 'text',
},

keys => {
	sign    => 'md5,size,name',
},