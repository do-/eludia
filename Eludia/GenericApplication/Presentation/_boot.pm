################################################################################

sub draw__boot {

	$_REQUEST {__no_navigation} = 1;

	my $propose_gzip = 0;
	if ($preconf -> {core_gzip} && ($r -> headers_in -> {'Accept-Encoding'} !~ /gzip/)) {
		$propose_gzip = 1;
	}

	my $delay = 0;
	my $img = "$_REQUEST{__static_url}/0.gif";
	my $transition = '';

	if ($conf -> {splash}) {
		$delay = $conf -> {splash} -> {delay} || 1000;
		$img = "$_REQUEST{__static_site}/i/$conf->{splash}->{src}";
		$conf -> {splash} -> {effect} ||= 'Fade(Duration=1)';
		$transition = "<HEAD><meta http-equiv='Page-Exit' content='progid:DXImageTransform.Microsoft.$conf->{splash}->{effect}'></HEAD>";
	}

	$_REQUEST {__on_load} = <<EOJS;

		setTimeout ("nope ('$_REQUEST{__uri}?type=logon', '_top')", $delay);

		setTimeout ("document.getElementById ('splash').style.display = 'none'; document.getElementById ('abuse_1').style.display = 'block'", 10000);

EOJS

	return <<EOH

		$transition


		<table id=splash width=100% height=100% border=0 cellspacing=0 cellpadding=0>
			<tr>
				<td valign=center align=center>
					<img src="$img" valign=middle align=center>
				</td>
			</tr>
		</table>

			<center>

		<noscript>


			<table border=0 width=50% height=30% cellspacing=1 cellpadding=0 bgcolor=red><tr><td>
				<table border=0 width=100% height=100% cellspacing=0 cellpadding=10><tr><td bgcolor=white>

					<b>¬нимание!</b> ќперационна€ система на вашем рабочем месте настроена таким образом, что нормальна€ работа приложени€ невозможна.

					<p>ѕожалуйста, попросите вашего системного администратора разрешить использование активных сценариев (javaScript) дл€ сервера $ENV{HTTP_HOST}.

				</table>
			</table>


		</noscript>

			<table id="abuse_1" border=0 width=50% height=30% cellspacing=1 cellpadding=0 bgcolor=red style="display:none"><tr><td>
				<table border=0 width=100% height=100% cellspacing=0 cellpadding=10><tr><td bgcolor=white>

					<b>¬нимание!</b> ќперационна€ система на вашем рабочем месте настроена таким образом, что нормальна€ работа приложени€ невозможна. ¬еро€тно, это св€зано с соображени€ми безопасности, св€занными с доступом к общедоступным ресурсам Internet: рекламным, развлекательным и т. п.

					<p>ѕожалуйста, попросите вашего системного администратора разрешить использование функции window . open() дл€ сервера $ENV{HTTP_HOST}.

				</table>
			</table>

EOH

}

1;