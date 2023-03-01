################################################################################

sub draw_form_field_multi_select {

	my ($options, $data) = @_;

	return $_SKIN -> draw_form_field_multi_select (@_)
		if $options -> {ds} && $_SKIN -> can('draw_form_field_multi_select');

	local $_REQUEST {select} = undef
		if $options -> {href} =~ m/\bmulti_select=1\b/;

	check_href ($options);

	my $label = $options -> {label};
	$label =~ s/<br>/ /g;
	$label =~ s/<\/?b>//g;
	$label =~ s/:$//g;
	$label =~ s/\s+/ /g;

	$options -> {delimeter} ||= $conf -> {multi_select_delimeter} || '<br>';

	my $replace_delimeter = $options -> {delimeter} eq '<br>' ? ''
		:".replace(/<br>/g, \"$options->{delimeter}\");";

	$options -> {span_name} ||= "ms_$options";

	my $after = <<EOJS;
		if (typeof result !== 'undefined' && result.result == 'ok') {
			document.getElementById ('$options->{span_name}').innerHTML=result.label$replace_delimeter;
			var el_ids = document.getElementsByName ('_$options->{name}') [0];
			var oldIds = el_ids.value;
			el_ids.value = result.ids;
EOJS

	$after .= "if (!stringSetsEqual (oldIds, result.ids)) {\$(el_ids).trigger('change'); $options->{onChange}}";

	my $js_detail;

	if (defined $options -> {detail}) {

		$options -> {value_src} = "document.getElementsByName ('_$options->{name}') [0].value";
		$js_detail = js_detail ($options);

		$after .= $js_detail;

	}

	$after .= "};$$options{after}; void (0);";

	my $url = dialog_open ({
		href  => $options -> {href} . '&multi_select=1',
		title => $label,
		after => $after,
		before => $options -> {before},
	});

	$url =~ s/^javascript://i;

	my $url_dialog_id = $_REQUEST {__dialog_cnt};

	my $detail_from;
	if (exists $options -> {detail_from}) {
		if (ref $options -> {detail_from} ne ARRAY) {
			$options -> {detail_from} = [$options -> {detail_from}];
		}
		foreach my $field (@{$options -> {detail_from}}) {
			$detail_from .= "re = /&$field=[\\d]*/; dialogs[$url_dialog_id].href = dialogs[$url_dialog_id].href.replace(re, ''); dialogs[$url_dialog_id].href += '&$field=' + document.getElementsByName ('_$field') [0].value;";
		}
	}

	my $onclear_js = "document.getElementById ('$options->{span_name}').innerHTML = ''; var el_ids = document.getElementsByName ('_$options->{name}') [0]; var oldValue = el_ids.value; el_ids.value = '';";
	$onclear_js .= "if (oldValue != '') {\$(el_ids).trigger('change'); $options->{onChange}}";
	$onclear_js .= $js_detail;

	return qq|<span id="input_$$options{name}">| . draw_form_field_of_type (
		{
			label => $options -> {label},
			type  => 'hgroup',
			items => [
				{
					type  => 'static',
					value => qq[<span id="$options->{span_name}">] . join ($options -> {delimeter}, map {$_ -> {label}} @{$options -> {values}}) . '</span>',
				},
				{
					type      => 'hidden',
					name      => $options->{name},
					value     => join (',', map {$_ -> {id}} @{$options -> {values}}),
					off       => $_REQUEST {__read_only} || $options -> {read_only},
					label_off => 1,
				},
				{
					type    => 'button',
					value   => $i18n -> {Change},
					onclick => <<EOJS,
						re = /&_?salt=[\\d\\.]*/g; dialogs[$url_dialog_id].href = dialogs[$url_dialog_id].href.replace(re, ''); re = /&ids=[^&]*/i; dialogs[$url_dialog_id].href = dialogs[$url_dialog_id].href.replace(re, ''); dialogs[$url_dialog_id].href += '&salt=' + Math.random () + '&ids=' + document.getElementsByName ('_$options->{name}') [0].value;
						$detail_from
						$url
EOJS
					off     => $_REQUEST {__read_only} || $options -> {read_only},
				},
				{
					type    => 'button',
					value   => $i18n -> {Clear},
					onclick => $onclear_js,
					off     => $_REQUEST {__read_only} || $options -> {read_only},
				},
			],
		},
		$data
	) . q |</span>|;

}

1;
