<!DOCTYPE html>
<html>
	<head>
		<meta http-equiv="X-UA-Compatible" content="IE=edge">
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
		<style>
HTML, BODY {
	FONT-FAMILY: Tahoma, 'MS Sans Serif';
	FONT-WEIGHT: normal;
	FONT-SIZE: 8pt;
	COLOR: #000000;
	background-color: #FFFFFF;
	height:100%;
	margin:0px;
	padding:0px;
	overflow: auto;
}

IFRAME {
	height:100%;
	width:100%;
	display:block;
	margin:0;
	padding:0;
	border: 0;
}

		</style>
	</head>
	<BODY
		onLoad="
			if (dialogArguments.title) {
				document.title = dialogArguments.title;
				title_set = 1;
			}
			window.returnValue = {'result': 'esc'};
			open(dialogArguments.href, '_body_iframe');
		"
	>
		<iframe name='_body_iframe' id='__body_iframe' src="0.html" scrolling=yes>
		</iframe>
	</body>
</html>
