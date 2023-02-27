var i18n = {
	F5: "Внимание! Вы изменили содержимое некоторых полей ввода. Перезагрузка страницы приведёт к утере этой информации. Продолжить?",
	choose_open_vocabulary: "Выбор из справочника",
	request_sent : 'Запрос отправлен на сервер',
	copy_clipboard: "Для копирования нажмите CTRL+C, потом ENTER",
	count : 'Кол-во',
	sum   : 'Сумма',
	clipboard_help: "Для копирования нажмите CTRL+C, потом ENTER",
	no_data_found : 'Список пуст',
	clipboard_copied: "Скопировал"
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
//	console.log (e);
}
