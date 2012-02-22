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
	
		
		if (navigator.appVersion.indexOf ("MSIE") != -1 && navigator.appVersion.indexOf ("Opera") == -1) {

			var version=0;
			var temp = navigator.appVersion.split ("MSIE");
			version  = parseFloat (temp [1]);

			if (version < 5.5) {
				alert ('��������! ������ WEB-���������� ��������������� � ������������� ������ ��������� � ���������� ��������� MS Internet Explorer ������ �� ���� 5.5. �� ����� ������� ����� ����������� ������ ' + version + '. ����������, ��������� ������ ���������� �������������� ��������� ���������� MS Internet Explorer �� ������� ������ (��������� ���������� � ���������� ���������) ��� �������� ��� ��������������.');
				document.location.href = 'http://www.microsoft.com/ie';
			}
			
			if ($propose_gzip) {
				alert ('��������! ��������� ������ �������� ����� �� ��������� ������������ ���������������� �������� (HTTP 1.1) ��� ����� � ��������. ���������, ����������, ������ �������������� ��������� ������������� ��������� HTTP 1.1 ��� ����� � �������� $ENV{HTTP_HOST} -- ��� ���������� ���������� ��������� ������� �������� ������ � 3-5 ���.');
			}


		}
		else {
		
			var brand = navigator.appName;
		
			if (navigator.appVersion.indexOf ("Opera") > -1) {
				brand = 'Opera';
			}

//			alert ('��������! ������ WEB-���������� ��������������� � ������������� ������ ��������� � ���������� ��������� MS Internet Explorer. �� ��������� ������������ ��������� ' + brand + '. � ���� �������� ����������� ��������� ������������ �� ������������ � ������������ ����� ������������. ����������, ����������� ����������� ��, ������������� �� ����� ������� �����.');
			
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
		
					<b>��������!</b> ������������ ������� �� ����� ������� ����� ��������� ����� �������, ��� ���������� ������ ���������� ����������.

					<p>����������, ��������� ������ ���������� �������������� ��������� ������������� �������� ��������� (javaScript) ��� ������� $ENV{HTTP_HOST}.
			
				</table>
			</table>
			
		
		</noscript>
		
			<table id="abuse_1" border=0 width=50% height=30% cellspacing=1 cellpadding=0 bgcolor=red style="display:none"><tr><td>
				<table border=0 width=100% height=100% cellspacing=0 cellpadding=10><tr><td bgcolor=white>		
		
					<b>��������!</b> ������������ ������� �� ����� ������� ����� ��������� ����� �������, ��� ���������� ������ ���������� ����������. ��������, ��� ������� � ������������� ������������, ���������� � �������� � ������������� �������� Internet: ���������, ��������������� � �. �.

					<p>����������, ��������� ������ ���������� �������������� ��������� ������������� ������� window . open() ��� ������� $ENV{HTTP_HOST}.
			
				</table>
			</table>
						
EOH

}

1;