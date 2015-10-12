<!doctype html>
	<head>
		<meta http-equiv="X-UA-Compatible" content="IE=edge">
		<style>
			body {
				margin           : 0,
			}
			body,html {
				overflow:hidden
			}
			.help-image {
				height: 100px;
				width: auto;
				margin-right: 20px;
			}
		</style>
		<script src="/i/_skins/TurboMilk/navigation.js"></script>
		<script>
			function toggle_detail() {
				$("#error_detail_area").toggle();
				$("#mail_support_area").toggle();
				var label = $('#error_detail_area').is(":visible")? "������ ����������� ������" : "�������� ����������� ������";
				$("#toggle_detail").text(label);
			}

			function support_mailto_href(options) {
				var href = 'mailto:' + options.email + '?';
				href = href + 'subject=' + encodeURIComponent(options.subject);
				href = href + '&body=' + encodeURIComponent(options.details);

				var uri_max_length = 2000;
				href = href.substring(0, uri_max_length);

				return href;
			}

			function on_load(){
				if (dialogArguments.title) {
					document.title = dialogArguments.title;
					title_set = 1;
				}
				window.returnValue = {'result': 'esc'};

				if(dialogArguments.details) {
					$('#error_detail').val(dialogArguments.details);
				}

				$('#mail_support').attr('href', support_mailto_href(dialogArguments));
			}
		</script>
	</head>
	<body onLoad="on_load()" style="background-color : #efefef">
		<div style="float: left">
			<img src="/i/_skins/TurboMilk/error.png?salt=43" class="help-image"></img>
		</div>
		<p>��������� ���������� ������. ��������� � ��� ��� ���������� � ������ ������������ � �� ���������� � �� �����������.</p>
		<p>
			<a href="#" id="toggle_detail" onclick="toggle_detail();">�������� ����������� ������</a>
		</p>
		<p>
			<span id="error_detail_area" style="display: none">
				<textarea id="error_detail" rows="7" cols="57"></textarea>
			</span>
			<p></p>
		</p>
		<span id="mail_support_area">
			<p>
				��� ����� �������� ������� �������� �� ������ ��������� ������ � ������������ � ��������� ���������
				����� �������� �� ��������� ������ (������� �� �� ��������� ���������� �� ������).
			</p>
			<p>
				<a id="mail_support" href="#" >��������� email � ������ ����������� ���������</a>
			</p>
		<span>
		<span>
			<a href="javascript: var w = window.parent.parent; w.close ();" class="button" style="float:right">�������</div>
		</span>
	</body>
</html>
