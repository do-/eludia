var WshShell  = null;
var FSO       = null;

function __get_env_var (varname) {
	return WshShell.ExpandEnvironmentStrings ('%' + varname + '%');
}

function __write (where, what) {
	if (FSO.FileExists (where)) FSO.DeleteFile (where);
	var fh = FSO.OpenTextFile (where, 2, true);
	fh.Write (what);
	fh.Close ();
}

function __shortcut (path, app_title, hotkey, icon_fname, HTA_fname, HTA_dir) {

	var link = WshShell.CreateShortcut (path + '\\' + app_title + '.lnk');
	link.Description = app_title;
	if (hotkey) link.HotKey = hotkey;
	link.IconLocation = icon_fname + ',0';
	link.TargetPath = HTA_fname;
	link.WindowStyle = 4;
	link.WorkingDirectory = HTA_dir;
	link.Save ();

}

function SetupHTA (app_code, app_title, app_url, content, icon, hotkey) {

	try {
		FSO = new ActiveXObject ('Scripting.FileSystemObject');
		WshShell = new ActiveXObject ("WScript.Shell");
	}
	catch (err) {
		alert ('Произошла ошибка установки приложения: ' + err.message + ". Вероятно, следует изменить уровень безопасности для текущей зоны на 'низкий'. Для этого следует щёлкнуть на названии зоны на нижней панели, переместить вертикальный движок до конца вниз, затем нажать ОК и обновить страницу (F5). Смена параметров безопасности нужна только на время установки, по её окончании настройку можно будет вернуть.");
		return;
	}
	
	var HTA_dir    = __get_env_var ('ProgramFiles') + '\\' + app_code;
	var HTA_fname  = HTA_dir + '\\' + app_code + '.hta';
	var icon_fname = HTA_dir + '\\favicon.ico';

	if (FSO.FileExists (HTA_fname) && !confirm ('Приложение "' + app_title + '" уже установлено. Перезаписать?')) return;
	
	if (!FSO.FolderExists (HTA_dir)) FSO.CreateFolder (HTA_dir);
	
	__write (HTA_fname, content);
	__write (icon_fname, icon);

	var msg = 'Приложение "' + app_title + '" установлено.';
		
	__shortcut (
		WshShell.SpecialFolders ("Desktop")
		, app_title, hotkey, icon_fname, HTA_fname, HTA_dir);

	__shortcut (
		__get_env_var ('APPDATA') + '\\Microsoft\\Internet Explorer\\Quick Launch'
		, app_title, null, icon_fname, HTA_fname, HTA_dir);

	if (hotkey) msg = msg + ' Чтобы запустить его, нажмите ' + hotkey;
	
	alert (msg);
	
	window.close ();
	
}

function nope (a1, a2, a3) {
	var w = window;
	w.open (a1, a2, a3);
}
