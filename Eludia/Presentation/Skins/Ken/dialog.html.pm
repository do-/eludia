<html>
	<head>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
		<title>Справочник</title>
		<script>
			var title_set = 0;
			function _setSelectOption (id, label) {
				window.returnValue.result = 'ok';				
				window.returnValue.id = id;				
				window.returnValue.label = label;
				window.close ();
			}
		</script>
	</head>
	<BODY
		BGCOLOR="#FFFFFF"
		leftMargin=0
		topMargin=0
		bottomMargin=0
		rightMargin=0
		marginwidth=0
		marginheight=0
		scroll=no
		onLoad="
			if (dialogArguments.title) {
				document.title = dialogArguments.title;
				title_set = 1;
			}
			window.returnValue = {'result': 'esc'};
			open(dialogArguments.href, '_body_iframe');
		"
	>
		<iframe name='_body_iframe' id='__body_iframe' src="0.html" width=100% height=100% scrolling=no application=yes>
		</iframe>
	</body>
</html>
