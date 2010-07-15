################################################################################

sub draw_form_field_multi_select {

	my ($options, $data) = @_;

	check_href ($options);

	my $label = $options -> {label};
	$label =~ s/<br>/ /g;
	$label =~ s/\s+/ /g;

	my $url = dialog_open ({
		href	=> $options -> {href} . '&multi_select=1',
		title	=> $label,
	}, {
		dialogHeight	=> 'screen.availHeight - (screen.availHeight <= 600 ? 50 : 100)',
		dialogWidth	=> 'screen.availWidth - (screen.availWidth <= 800 ? 50 : 100)',
	}) . "if (result.result == 'ok') {document.getElementById ('ms_$options').innerHTML=result.label; document.form._$options->{name}.value=result.ids;";
	
	my $js_detail;
	
	if (defined $options -> {detail}) {

		$options -> {value_src} = "this.form.elements['_$options->{name}'].value";
		$js_detail = js_detail ($options);

		$url .= $js_detail;

	}

	$url .= "} void (0);";

	$url =~ s/^javascript://i;
	
	my $url_dialog_id = $_REQUEST {__dialog_cnt};

	my $detail_from;
	if (exists $options -> {detail_from}) {
		if (ref $options -> {detail_from} ne ARRAY) {
			$options -> {detail_from} = [$options -> {detail_from}];
		}
		foreach my $field (@{$options -> {detail_from}}) {
			$detail_from .= <<EOJS;
			re = /&$field=[\\d]*/;
			dialog_open_$url_dialog_id.href = dialog_open_$url_dialog_id.href.replace(re, '');
			dialog_open_$url_dialog_id.href += '&$field=' + document.getElementsByName ('_$field') [0].value;
EOJS
		}
	}

	return draw_form_field_of_type (
		{
			label	=> $options -> {label},
			type	=> 'hgroup',
			items	=> [
#				{
#					type	=> 'static',
#					value	=> qq[<table id="_$$options{name}">],
#				},
				{
					type	=> 'static',
					value	=> qq[<span id="ms_$options">] . join ('<br>', map {$_ -> {label}} @{$options -> {values}}) . '</span>',
				},
				{
					type	=> 'hidden',
					name	=> $options->{name},
					value	=> join (',', map {$_ -> {id}} @{$options -> {values}}),
					off		=> $_REQUEST {__read_only},
					label_off => 1,
				},
				{
					type	=> 'button',
					value	=> 'Изменить',
					onclick	=> <<EOJS,
						re = /&_?salt=[\\d\\.]*/g;
						dialog_open_$url_dialog_id.href = dialog_open_$url_dialog_id.href.replace(re, '');
						dialog_open_$url_dialog_id.href += '&salt=' + Math.random ();
						
						re = /&ids=[^&]*/i; 
						dialog_open_$url_dialog_id.href = dialog_open_$url_dialog_id.href.replace(re, '');
						dialog_open_$url_dialog_id.href += '&ids=' + document.getElementsByName ('_$options->{name}') [0].value; 

						$detail_from

						$url
EOJS

					off	=> $_REQUEST {__read_only},
				},
				{
					type	=> 'button',
					value	=> 'Очистить',
					onclick => "document.getElementById ('ms_$options').innerHTML=''; document.form._$options->{name}.value='';" . $js_detail,
					off	=> $_REQUEST {__read_only},
				},
#				{
#					type	=> 'static',
#					value	=> qq[</table>],
#				},
			],
		},
		$data
	);

}

1;