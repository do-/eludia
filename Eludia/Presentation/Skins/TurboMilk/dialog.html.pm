<html>
	<head>
		<meta http-equiv="X-UA-Compatible" content="IE=5">
		<title>����������</title>
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
		<iframe name='_body_iframe' id='__body_iframe' src="0.html" width=100% height=100% scrolling=yes application=yes style="border: 0">
		</iframe>
	</body>
</html>
