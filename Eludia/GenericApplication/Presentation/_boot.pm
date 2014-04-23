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
		var is_opera = navigator.appVersion.indexOf ("Opera") > -1;
		var is_old_ie = navigator.appVersion.indexOf ("MSIE") > -1 && !is_opera;
		var is_new_ie = /Trident\\/\\d\\./i.test(navigator.userAgent);
		if (is_new_ie || is_old_ie) {

			var version=0;
			var temp = navigator.appVersion.split ("MSIE");
			if (temp.length == 0) { // ie11
				temp = navigator.appVersion.split ("rv:");
			}
			version  = parseFloat (temp [1]);

			if (version < 5.5) {
				alert ('Внимание! Данное WEB-приложение разрабатывалось и тестировалось только совместно с программой просмотра MS Internet Explorer версии не ниже 5.5. На вашем рабочем месте установлена версия ' + version + '. Пожалуйста, попросите вашего системного администратора выполнить обновление MS Internet Explorer до текущей версии (абсолютно бесплатная и безопасная процедура) или сделайте это самостоятельно.');
				document.location.href = 'http://www.microsoft.com/ie';
			}
			
			if ($propose_gzip) {
				alert ('Внимание! Настройки вашего рабочего места не позволяют использовать высокоскоростной протокол (HTTP 1.1) для связи с сервером. Попросите, пожалуйста, вашего администратора разрешить использование протокола HTTP 1.1 для связи с сервером $ENV{HTTP_HOST} -- эта совершенно безопасная процедура ускорит передачу данных в 3-5 раз.');
			}


		}
		else if (navigator.userAgent != "unitech mobile") {
		
			var brand = navigator.appName;
		
			if (is_opera) {
				brand = 'Opera';
			}

			alert ('Внимание! Данное WEB-приложение разрабатывалось и тестировалось только совместно с программой просмотра MS Internet Explorer. Вы пытаетесь использовать программу ' + brand + '. В этих условиях разработчик ПОЛНОСТЬЮ ОТКАЗЫВАЕТСЯ от консультаций и рассмотрения жалоб пользователя. Пожалуйста, используйте СТАНДАРТНОЕ ПО, установленное на вашем рабочем месте.');
			
		}					
						
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
		
					<b>Внимание!</b> Операционная система на вашем рабочем месте настроена таким образом, что нормальная работа приложения невозможна.

					<p>Пожалуйста, попросите вашего системного администратора разрешить использование активных сценариев (javaScript) для сервера $ENV{HTTP_HOST}.
			
				</table>
			</table>
			
		
		</noscript>
		
			<table id="abuse_1" border=0 width=50% height=30% cellspacing=1 cellpadding=0 bgcolor=red style="display:none"><tr><td>
				<table border=0 width=100% height=100% cellspacing=0 cellpadding=10><tr><td bgcolor=white>		
		
					<b>Внимание!</b> Операционная система на вашем рабочем месте настроена таким образом, что нормальная работа приложения невозможна. Вероятно, это связано с соображениями безопасности, связанными с доступом к общедоступным ресурсам Internet: рекламным, развлекательным и т. п.

					<p>Пожалуйста, попросите вашего системного администратора разрешить использование функции window . open() для сервера $ENV{HTTP_HOST}.
			
				</table>
			</table>
						
EOH

}

1;