var i18n = {
	F5: "��������! �� �������� ���������� ��������� ����� �����. ������������ �������� ������� � ����� ���� ����������. ����������?",
	choose_open_vocabulary: "����� �� �����������",
	request_sent : '������ ��������� �� ������',
	copy_clipboard: "��� ����������� ������� CTRL+C, ����� ENTER"
};

try{
	kendo.culture("ru-RU");
	kendo.ui.Upload.prototype.options.localization =
	  $.extend(kendo.ui.Upload.prototype.options.localization, {
		select: "��������...",
		cancel: "������",
		retry: "���������",
		remove: "�������",
		uploadSelectedFiles: "��������� �����",
		dropFilesHere: "��� ��������, ���������� ���� ����.",
		statusUploading: "��������",
		statusUploaded: "��������",
		statusFailed: "�� �������"
	});
} catch(e) {
}
