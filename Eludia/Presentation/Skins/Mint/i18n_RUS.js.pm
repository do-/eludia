define(
	['kendo.core.min'],
	function (){
		var kendo = window.kendo;
		window.i18n = {
			F5: "Внимание! Вы изменили содержимое некоторых полей ввода. Перезагрузка страницы приведёт к утере этой информации. Продолжить?",
			choose_open_vocabulary: "Выбор из справочника",
			request_sent : 'Запрос отправлен на сервер',
			clipboard_help: "Для копирования нажмите CTRL+C, потом ENTER",
			clipboard_copied: "Скопировал",
			count : 'Кол-во',
			no_data_found : 'Список пуст',
			sum   : 'Сумма'
		};

		try{
			kendo.culture("ru-RU");
			if (kendo.ui && kendo.ui.Upload) {
				kendo.ui.Upload.prototype.options.localization =
				  $.extend(kendo.ui.Upload.prototype.options.localization, {
					select: "Выберите...",
					cancel: "Отмена",
					retry: "Повторить",
					remove: "Удалить",
					uploadSelectedFiles: "Загрузить файлы",
					dropFilesHere: "Для загрузки, перетащите файл сюда.",
					statusUploading: "загрузка",
					statusUploaded: "загрузил",
					statusFailed: "не удалось"
				});
			}
		} catch(e) {
			console.log (e);
		}

		return {};
	}
);
