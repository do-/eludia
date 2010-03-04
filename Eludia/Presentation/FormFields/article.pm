sub draw_form_field_article {

	my ($field, $data) = @_;

	$field -> {value} ||= $data -> {$field -> {name}};

	return $_SKIN -> draw_form_field_article (@_);

}

1;