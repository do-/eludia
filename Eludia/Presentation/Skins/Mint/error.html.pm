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
				var label = $('#error_detail_area').is(":visible")? "Скрыть подробности ошибки" : "Показать подробности ошибки";
				$("#toggle_detail").text(label);
			}

			function support_mailto_href(options) {
				var href = 'mailto:' + options.email + '?';
				href = href + 'subject=' + encodeURIComponent(options.subject);
				href = href + '&body=' + encodeURIComponent(
					"Пожалуйста, подробно опишите Ваши действия до появления ошибки здесь:\n\n\n" + options.label
				);

				return href;
			}


			function on_load(){

				var dialogArguments = parent.dialogArguments;

				if (dialogArguments.title) {
					document.title = dialogArguments.title;
					title_set = 1;
				}
				window.returnValue = {'result': 'esc'};

				if(dialogArguments.details) {
					$('#error_detail').val(dialogArguments.details);
				}

				if (dialogArguments.msg) {
					$('#error_message_area').text(dialogArguments.msg);
				}
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
			Произошла внутренняя ошибка.
		</span>
		</p>
		<p>
			<a href="#" id="toggle_detail" onclick="toggle_detail();">Показать подробности ошибки</a>
		</p>
		<p>
			<span id="error_detail_area" style="display: none">
				<textarea id="error_detail" rows="8" cols="62"></textarea>
			</span>
			<p></p>
		</p>
		<span id="mail_support_area">
			<p>
				<span id="error_hint_area">
					Для более быстрого решения проблемы Вы можете отправить письмо в техподдержку с подробным описанием
				Ваших действий до появления ошибки (опишите их до системной информации об ошибке).
				</span>
			</p>
			<p>
				<a id="mail_support" href="#" >Отправить e-mail в службу технической поддержки</a>
			</p>
		<span>
		<span>
			<a id="button_close" href="javascript: parent.close ();" style="float:right">Закрыть</div>
		</span>
	</body>
</html>
