sub draw_embed_cell {

	my ($data, $options) = @_;
	
	$data -> {autostart} ||= 'false';
	$data -> {src_type} ||= 'audio/mpeg';
	$data -> {height} ||= 45;

	return $_SKIN -> draw_embed_cell ($data, $options);

}

1;