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
			#error_detail_area {
				margin: 5px;
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
				href = href + '&body=' + encodeURIComponent(
					"����������, �������� ������� ���� �������� �� ��������� ������ �����:\n\n\n" + options.label
				);

				return href;
			}

			function on_load(){
				if (dialogArguments.title) {
					document.title = dialogArguments.title;
					title_set = 1;
				}
				window.returnValue = {'result': 'esc'};

				if(dialogArguments.details)
					$('#error_detail').val(dialogArguments.details);
				if (dialogArguments.msg)
					$('#error_message_area').text(dialogArguments.msg);
				if (dialogArguments.show_error_detail)
					$('#toggle_detail').text(dialogArguments.show_error_detail);
				if (dialogArguments.error_hint_area)
					$('#error_hint_area').text(dialogArguments.error_hint_area);
				if (dialogArguments.mail_support)
					$('#mail_support').text(dialogArguments.mail_support);
				if (dialogArguments.close)
					$('#button_close').text(dialogArguments.close);

				$('#mail_support').attr('href', support_mailto_href(dialogArguments));
			}
		</script>
	</head>
	<body onLoad="on_load()" style="background-color : #efefef">
		<div style="float: left">
			<img src="/i/_skins/TurboMilk/error.png?salt=43" class="help-image"></img>
		</div>
		<p>
		<span id="error_message_area">
			��������� ���������� ������.
		</span>
		</p>
		<p>
			<a href="#" id="toggle_detail" onclick="toggle_detail();">�������� ����������� ������</a>
		</p>
		<p>
			<span id="error_detail_area" style="display: none">
				<textarea id="error_detail" rows="8" cols="57"></textarea>
			</span>
			<p></p>
		</p>
		<span id="mail_support_area">
			<p>
				<span id="error_hint_area">
					��� ����� �������� ������� �������� �� ������ ��������� ������ � ������������ � ��������� ���������
				����� �������� �� ��������� ������ (������� �� �� ��������� ���������� �� ������).
				</span>
			</p>
			<p>
				<a id="mail_support" href="#" >��������� e-mail � ������ ����������� ���������</a>
			</p>
		<span>
		<span>
			<a id="button_close" href="javascript: var w = window.parent.parent; w.close ();" class="button" style="float:right">�������</div>
		</span>
	</body>
</html>
