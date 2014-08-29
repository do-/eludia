<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<meta charset="windows-1251">
	<meta http-equiv="X-UA-Compatible" content="IE=edge">
	<link rel="stylesheet" type="text/css" href="/i/ken/css/normalize.css">
	<link rel="stylesheet" type="text/css" href="/i/ken/styles/kendo.common.min.css">
	<link rel="stylesheet" type="text/css" href="/i/ken/css/icons.css">
	<link rel="stylesheet" type="text/css" href="/i/ken/css/templates.css">
	<link rel="stylesheet" type="text/css" href="/i/ken/css/jquery-ui-1.10.0.custom.min.css" />
	<link rel="stylesheet" type="text/css" title="silver" href="/i/ken/styles/kendo.silver.min.css">
	<link rel="alternate stylesheet" type="text/css" title="black" href="/i/ken/styles/kendo.black.min.css">
	<link rel="alternate stylesheet" type="text/css" title="blueopal" href="/i/ken/styles/kendo.blueopal.min.css">
	<link rel="alternate stylesheet" type="text/css" title="default" href="/i/ken/styles/kendo.default.min.css">
	<link rel="alternate stylesheet" type="text/css" title="metro" href="/i/ken/styles/kendo.metro.min.css">

	<script type='text/javascript' src='/i/ken/js/jquery.min.js'></script>
	<script type='text/javascript' src="/i/ken/js/kendo.all.min.js"></script>
	<script type='text/javascript' src="/i/ken/js/cultures/kendo.culture.ru-RU.cp1251.js"></script>

	<script type="text/javascript">
		kendo.culture("ru-RU");
		$(document).ready(function () {

			var DataSource = new kendo.data.DataSource(parent.chartDataSource);
			parent.chartOptions.dataSource = DataSource;
			parent.chartOptions.theme = 'silver';
			parent.chartOptions.seriesClick = parent.seriesClick;

			function createChart() {
				$(".chart").kendoChart(parent.chartOptions);
			}

			createChart();

			var chart = $(".chart").data("kendoChart");

			parent.$("input[name=svg_text_" + parent.chartName + "]").val(chart.svg());

			function dataBound(e) {
				var pw = $(parent.document).find("#sale").height();
				$(".k-grid-content").css({'height': pw - 71});
				$(".chart, .setting").css({'height': pw - 45});
			}

			$(window).resize (function() {
				chart.refresh();
			})
		});
	</script>

	<style>
		html {
			overflow-x: hidden;
			overflow-y: auto;
		}
	</style>
</head>
<body class="refer" style="overflow: hidden;">
	<div class="chart" style="padding:0px;"></div>
</body>
</html>