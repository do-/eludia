package Eludia::Docs;

no warnings;

package Eludia;
use Eludia;

package main;
use Data::Dumper;
use B::Deparse;

our $deparse = B::Deparse -> new ();	

our $charset = {
	en => 'windows-1252',
	ru => 'windows-1251',
};

@langs = qw(en ru);

################################################################################

@request = (

	{
		name     => '__clock_separator',
		label_ru => "Разделитель часов и минут на часиках авторизационной шапки. Иногда применяется для незаметной индикации чего-либо, например, '!' вместо ':' может означать, что гражданин, чья карточка отображается на экране -- психопат.",
	},
	{
		name     => 'fake',
		label_ru => "Список допустимых значений поля fake через запятую",
	},
	{
		name     => 'type',
		label_ru => "Тип экрана. Используется при определении callback-процедур для обработки текущего запроса.",
	},
	{
		name     => 'id',
		label_ru => "Номер записи. Пустота/непустота этого параметра влияет на выбор callback-процедур для обработки текущего запроса.",
	},
	{
		name     => 'sid',
		label_ru => "Номер текущей сессии.",
	},
	{
		name     => 'start',
		label_ru => "Начало просматриваемого фрагмента листаемой длинной выборки",
	},
	{
		name     => 'salt',
		label_ru => "Случайный параметр, зашумляющий URL для предотвращения кэширования на клиенте",
	},
	{
		name     => 'lpt',
		label_ru => "Устаревший параметр, теперь устанавливаемый при xls=1 по соображениям обратной совместимости",
	},
	{
		name     => 'error',
		label_ru => "Сообщение об ошибке, которое будет выдано клиенту",
	},
	{
		name     => 'order',
		label_ru => "Имя поля, по которому будет отсортирована таблица. Автоматически не действует, но используется API-функцией order",
	},
	{
		name     => '__salt',
		label_ru => "То же, что salt",
	},
	{
		name     => '_salt',
		label_ru => "То же, что salt",
	},
	{
		name     => 'select',
		label_ru => "Имя поля ввода в вызывающем окне, для которого текущее является испочником данных. Это значение не следует устанавливать напрямую, но необходимо отслеживать его наследование, в частности, через опцию keep_params для панели с кнопками.",
	},
	{
		name     => '__read_only',
		label_ru => "Если истина, то все поля ввода форм отрисовываются как static",
	},
	{
		name     => '__no_navigation',
		label_ru => "Если истина, то главное меню и авторизационная шапка не отрисовываются",
	},
	{
		name     => '__include_js',
		label_ru => "Список путей (относительно docroot/i) дополнительных js-файлов, используемых на данной странице",
	},
	{
		name     => '__include_css',
		label_ru => "Список путей (относительно docroot/i) дополнительных css-файлов, используемых на данной странице",
	},
	{
		name     => '__peer_server',
		label_ru => "Имя peer-сервера, с которого пришёл текуший запрос. Если пусто, запрос от локального пользователя.",
	},
	{
		name     => '__uri',
		label_ru => "Адрес текущего запроса до последнего '/' вклюючительно. Может использоваться для генерации ссылок на статику (картинки и пр.). Например, по адресу '\$_REQUEST{__uri}0.gif' всегда располагается однопиксельный бесцветный заполнитель.",
	},
	{
		name     => '__response_sent',
		label_ru => "Если истина, то presentation-часть обработки запроса пропускается. Используется в том случае, если ответ сформирован напрямую с использованием \$r",
	},
	{
		name     => '__x',
		label_ru => "Если истина, то ответ выдаётся в виде XML (в качестве \$_SKIN используется Eludia::Presentation::Skins::XMLDumper). Используется для интеграции с внешними приложениями. Может не работать в случае переопределения функции get_skin_name.",
	},
	{
		name     => 'xls',
		label_ru => "Если истина, то ответ выдаётся в виде HTML-файла, воспринимаемого на клиенте как электронная таблица (в качестве \$_SKIN используется Eludia::Presentation::Skins::XL). Может не работать в случае переопределения функции get_skin_name.",
	},
	{
		name     => '__last_query_string',
		label_ru => "Номер текущей строки запроса в таблице __access_log в рамках текущей сессии",
	},
	{
		name     => '__scrollable_table_row',
		label_ru => "Номер строки таблицы, на которой будет установлен слайдер при загрузке страницы",
	},
	{
		name     => '__last_scrollable_table_row',
		label_ru => "Номер строки таблицы, c которой был произведён переход на текущую страницу",
	},
	{
		name     => '__pack',
		label_ru => "Если истина, то при загрузке страницы окно браузера обжимается до минимального размера, при котором содержимое экрана остаётся видимым (устар.)",
	},
	{
		name     => '__meta_refresh',
		label_ru => "Период автообновления страницы, с",
	},
	{
		name     => '__last_last_query_string',
		label_ru => "Прошлое значение \$_REQUEST {__last_query_string}",
	},
	{
		name     => '__edit',
		label_ru => "Антоним \$_REQUEST {__read_only}. Точнее, как правило, content-процедура автоматически устанавливает \$_REQUEST {__read_only} для не-fake записей, если только не \$_REQUEST {__edit}. Данный параметр обычно фигурирует в запросах, порождаемых по кнопке 'Редактировать', которая автоматически при писывается к форме в режиме read_only при \$conf -> {core_auto_edit}.",
	},
	{
		name     => '__tabindex',
		label_ru => "Внутренний счётчик полей при отрисовке форм ввода",
	},
	{
		name     => '__toolbars_number',
		label_ru => "Внутренний счётчик панелей с кнопками",
	},
	{
		name     => '__only_form',
		label_ru => "Имя формы, содержащей перегружаемое detail-поле",
	},
	{
		name     => '__only_field',
		label_ru => "Имя перегружаемого detail-поля",
	},
	{
		name     => '__only_tabindex',
		label_ru => "Порядковый номер перегружаемого detail-поля в смысле табуляции",
	},
	{
		name     => '__on_load',
		label_ru => "js-код, подставляемый в конец обработчика body.onload",
	},
	{
		name     => '__script',
		label_ru => "js-код, подставляемый в конец элемента html/head/script, если страница предназначена для непосредственного просмотра (а не грузится в iframe[@name=invisible] для перерисовки родительского экрана)",
	},
	{
		name     => '__no_focus',
		label_ru => "Если ложь, то при загрузке страницы окно браузера перехватывает фокус ввода (в частности, всплывает поверх остальных приложений)",
	},
	{
		name     => '__focused_input',
		label_ru => "Имя поля, на котором фокусируестя ввод при загрузке страницы. ",
	},
	{
		name     => '__blur_all',
		label_ru => "Отменяет эвристику определения __focused_input: ни одно поле не получит фокус ввода по умолчанию",
	},
	{
		name     => '__help_url',
		label_ru => "Адрес, открываемый при нажатии на надпись 'F1 - Помощь' и соответствующую горячую клавишу",
	},
	{
		name     => '__core_show_icons',
		label_ru => "Локальное переопределение $conf -> {core_show_icons} для новых разделов унаследованных приложений",
	},



);

################################################################################

@options = (

	{
		name     => 'files',
		label_ru => "Список имён параметров, соответствующих загружаемым (upload) файлам.",
	},
	{
		name     => 'field',
		label_ru => "Используемая компонента исходных записей",
	},
	{
		name     => 'subject',
		label_ru => "Тема сообщения",
	},
	{
		name     => 'text',
		label_ru => "Текст сообщения",
	},
	{
		name     => 'attach',
		label_ru => "Файл, прикреплённый к сообщению",
	},
	{
		name     => 'content_type',
		label_ru => "Тип сообщения, обычно 'text/plain' или 'text/html'",
	},
	{
		name     => 'to',
		label_ru => "Адрес получателя электронного письма. Может быть как адресом e-mail, так id пользователя (будет подставлено занчение поля mail), ссылкой на хэш с компонентами mail (вышеописанное) и label (видимая метка адреса) или ссылкой на список таких значений",
	},

	{
		name     => 'bgcolor',
		label_ru => "Цвет фона",
	},

	{
		name     => 'preset',
		label_ru => "Имя прототипа кнопки из \$conf -> {button_presets}, например, 'create', 'delete'.",
	},

	{
		name     => 'add_hidden',
		label_ru => "Если истина, то в режиме read_only для данного поля генерируется элемент ввода типа hidden.",
	},
	{
		name     => 'keep_esc',
		label_ru => "Если истина, то esc-адресом для следующего экрана будет не текущий экран, а прошлый.",
	},
	{
		name     => 'expand_all',
		label_en => "If true, all subcheckboxes are shown.",
		label_ru => "Если истина, то раскрыты все подчинённые checkbox'ы.",
	},

	{
		name     => 'force_label',
		label_en => "If true, the label is shown even when core_show_icons is on.",
		label_ru => "Если истина, то надпись показывается даже при core_show_icons.",
	},

	{
		name     => 'no_time',
		label_en => "If true, only the date input is awaited, but no time.",
		label_ru => "Если истина, это поле ввода даты, но не времени.",
	},

	{
		name     => 'no_read_only',
		label_en => "If true, the input allows keyboard input.",
		label_ru => "Если истина, то возможен ввод с клавиатуры.",
	},

	{
		name     => 'order',
		label_en => "Items sort order.",
		label_ru => "Порядок сортировки элементов",
	},

	{
		name     => 'no_clear_button',
		label_en => "If true, the [X] button is not shown.",
		label_ru => "Если истина, то кнопка [X] (очистка содержимого) не отрисовывается.",
	},

	{
		name     => 'is_total',
		label_en => "If true, the table row is displayed as a totals line, not ordinary row.",
		label_ru => "Если истина, то строка таблицы подцвечивается как строка с суммой.",
	},

	{
		name     => 'code',
		label_en => "Keyboard scan code. Can be set as /F(\\d+)/ for function keys.",
		label_ru => "Клавиатурный scan code. Для функциональных клавиш может быть задан как /F(\\d+)/.",
	},

	{
		name     => 'data',
		label_en => "ID attibute of an A tag to activate with the hotkey.",
		label_ru => "Атрибут ID тега A, который требуется активизировать при нажатии на горячую клавишу.",
	},

	{
		name     => 'ctrl',
		label_en => "If true, Ctrl key must be pressed.",
		label_ru => "Если истина, требуется нажатие на Ctrl.",
	},

	{
		name     => 'alt',
		label_en => "If true, Alt key must be pressed.",
		label_ru => "Если истина, требуется нажатие на Alt.",
	},

	{
		name     => 'no_force_download',
		label_en => "Unless true, the 'File download' ialog is forced on the client.",
		label_ru => "Если не true, то на клиенте должен появиться диалог открытия файла.",
	},

	{
		name     => 'file_name',
		label_en => "File name as shown to the client.",
		label_ru => "Имя файла для клиента.",
	},

	{
		name     => 'file_path_columns',
		label_en => "Listref of names of column that contain attached file paths.",
		label_ru => "Список имён полей, содержащих пути прикреплённых файлов.",
	},

	{
		name     => 'table',
		label_en => 'Table name.',
		label_ru => 'Имя таблицы.',
	},

	{
		name     => 'dir',
		label_en => 'Directory name to store the file, relative to DocumentRoot.',
		label_ru => 'Имя директории для записи файла, относительно DocumentRoot.',
	},

	{
		name     => 'path',
		label_en => 'File path, relative to DocumentRoot.',
		label_ru => 'Путь к файлу, относительно DocumentRoot.',
	},

	{
		name     => 'size_column',
		label_en => 'Name of the column that contain file size.',
		label_ru => 'Имя поля, содержащего обём прикреплённого файла.',
	},

	{
		name     => 'path_column',
		label_en => 'Name of the column that contain file path.',
		label_ru => 'Имя поля, содержащего путь прикреплённого файла.',
	},

	{
		name     => 'type_column',
		label_en => 'Name of the column that contain file MIME type.',
		label_ru => 'Имя поля, содержащего MIME-тип прикреплённого файла.',
	},

	{
		name     => 'file_name_column',
		label_en => 'Name of the column that contain file name.',
		label_ru => 'Имя поля, содержащего имя прикреплённого файла.',
	},

	{
		name     => 'label',
		label_en => "Visible text displayed in the element's area.",
		label_ru => "Видимый текст, отображаемый элементом.",
	},

	{
		name     => 'off',
		label_en => "If true, the element is not drawn at all",
		label_ru => "Если true, то HTML-код елемента не генерируется",
	},

	{
		name     => '..',
		label_en => "If true and the path is present on the page, the first table row is the reference to the previous level of the path (like '..' in file system).",
		label_ru => "Если true и на странице есть path, то первая строка таблицы ссылается на предпоследний элемент path (как '..' в файловой системе)",
	},

	{
		name     => 'height',
		label_en => "Height, in pixels",
		label_ru => "Высота, в пикселях",
	},

	{
		name     => 'class',
		label_en => "CSS class name",
		label_ru => "Имя CSS-класса",
	},

	{
		name     => 'read_only',
		label_en => "If true, text inputs are replaced by static text + hidden inputs",
		label_ru => "Если true, то текстовые поля ввода превращаются в статический текст + скрытые (hidden) поля",
	},
	
	{
		name     => 'max_len',
		label_en => "Maximum length for the displayed text. If oversized, the text is truncated and '...' is appended",
		label_ru => "Максимальная длина выводимого текста. При превышении текст обрезается, и к нему приписывается '...'",
	},
	
	{
		name     => 'size',
		label_en => "Size of the input field",
		label_ru => "Длина поля текстового ввода",
	},

	{
		name     => 'attributes',
		label_en => "additional HTML attributes for the corresponding TD tag",
		label_ru => "дополнительные HTML-атрибуты, дописываемые в тег TD",
	},
	
	{
		name     => 'a_class',
		label_en => "CSS class name for A tag",
		label_ru => "Имя CSS-класса для тега A",
	},

	{
		name     => 'name',
		label_en => "Input or form name",
		label_ru => "Имя поля ввода или всей формы",
	},

	{
		name     => 'type',
		label_en => "The value for the hidden input named 'type'",
		label_ru => "Значение, передаваемое невидимым полем ввода 'type'",
	},

	{
		name     => 'id',
		label_en => "The value for the hidden input named 'id'",
		label_ru => "Значение, передаваемое невидимым полем ввода 'id'",
	},

	{
		name     => 'action',
		label_en => "The value for the hidden input named 'action'",
		label_ru => "Значение, передаваемое невидимым полем ввода 'action'",
	},

	{
		name     => 'toolbar',
		label_en => "The toolbar on bottom of the table (inside its FORM tag)",
		label_ru => "Панель с кнопками внизу таблицы (внутри соответствующего тега FORM)",
	},

	{
		name     => 'js_ok_escape',
		label_en => "If true, the Ctrl+Enter and Esc keys will submit/escape the current form",
		label_ru => "Если true, то Ctrl+Enter и Esc обрабатываются для этой формы",
	},

	{
		name     => 'checked',
		label_en => "If true, the checkbox is on",
		label_ru => "Если true, checkbox отмечен",
	},

	{
		name     => 'value',
		label_en => "The input's value",
		label_ru => "Значение элемента управления",
	},
	
	{
		name     => 'hidden_value',
		label_en => "The hidden input's value",
		label_ru => "Значение элемента управления типа hidden",
	},

	{
		name     => 'id_image',
		label_en => "The hidden input's value",
		label_ru => "Значение элемента управления типа hidden",
	},

	{
		name     => 'hidden_name',
		label_en => "The hidden input's name",
		label_ru => "Имя элемента управления типа hidden",
	},

	{
		name     => 'picture',
		label_en => "The picture for numeric data (see Number::Format)",
		label_ru => "Формат числовых значений (см. Number::Format)",
	},
	
	{
		name     => 'href',
		label_en => "URL pointed by the element (HREF attribute of the A tag). Magic parameters 'sid' and 'salt' are appended automatically. See <a href='check_href.html'>check_href</a>, <a href='create_url.html'>create_url</a>",
		label_ru => "URL, на который ссылается данный элемент (атрибут HREF тега A). Магические параметры 'sid' и 'salt' приписываются автоматически. См. также check_href, create_url",
	},
	
	{
		name     => 'target',
		label_en => "The target window/frame (TARGET attribute of the A tag)",
		label_ru => "Целевое окно/фрейм ссылки (атрибут TARGET тега A)",
	},

	{
		name     => 'icon',
		label_en => "Reserved",
		label_ru => "Зарезервировано",
	},

	{
		name     => 'confirm',
		label_en => "The confirmation text",
		label_ru => "Текст запроса на подтверждение действия",
	},

	{
		name     => 'preconfirm',
		label_en => "js expression indicating whether to confirm action",
		label_ru => "js-выражение, определяющее, следует ли запрашивать подтверждение",
	},

	{
		name     => 'multiline',
		label_en => "If true, multiline mode is on",
		label_ru => "Если true, то отрисовка многострочная",
	},
	
	{
		name     => 'id_param',
		label_en => "Name of the param which value must be set to the current object ID",
		label_ru => "Имя параметра, в качестве значения которого должен быть передан ID текущего объекта",
	},
	
	{
		name     => 'keep_params',
		label_en => "REQUEST params to be inherited.",
		label_ru => "Список параметров запроса, которые требуется унаследовать.",
	},

	{
		name     => 'cnt',
		label_en => "Number of table rows on the current page (with START/LIMIT clause).",
		label_ru => "Число строк таблицы на текущей странице (с учётом START/LIMIT).",
	},

	{
		name     => 'total',
		label_en => "Total number of table rows (without START/LIMIT clause).",
		label_ru => "Число строк таблицы на текущей странице (без учёта START/LIMIT).",
	},

	{
		name     => 'portion',
		label_en => "Maximum number of table rows on one page (LIMIT value)",
		label_ru => "Максимальное число строк таблицы на одной странице (LIMIT)",
	},

	{
		name     => 'bottom_toolbar',
		label_en => "Toolbar on bottom of the form",
		label_ru => "Панель с копками внизу формы ввода",
	},

	{
		name     => 'format',
		label_en => "Date/time format, for example '%d.%m.%Y %k:%M'",
		label_ru => "Формат даты/времени, например, '%d.%m.%Y %k:%M",
	},

	{
		name     => 'no_time',
		label_en => "If true, no time is selected, only date",
		label_ru => "Если true, редактируется только дата, но не время",
	},
	
	{
		name     => 'onClose',
		label_en => "JavaScript code handling for the 'onClose' event",
		label_ru => "JavaScript-код обработчика события 'onClose'",
	},
	
	{
		name     => 'onChange',
		label_en => "JavaScript code handling for the 'onChange' event",
		label_ru => "JavaScript-код обработчика события 'onChange'",
	},
	
	{
		name     => 'onclick',
		label_en => "JavaScript code handling for the 'onclick' event",
		label_ru => "JavaScript-код обработчика события 'onclick'",
	},

	{
		name     => 'items',
		label_en => "Listref containing subelement definitions",
		label_ru => "Ссылка на список, содержащий описания подэлементов",
	},

#	{
#		name     => 'src',
#		label_en => "Value of SRC attribute of IMG tag (image URL)",
#		label_ru => "Значение атрибута SRC тега IMG (адрес изображения)",
#	},

	{
		name     => 'add_columns',
		label_en => "HASHREF of additional column names => values to store.",
		label_ru => "Хэш с именами и значениями дополнительных полей, которые надо сохранить в таблице.",
	},

	{
		name     => 'new_image_url',
		label_en => "Path to image selection dialog box",
		label_ru => "Адрес страницы выбора изображения",
	},

	{
		name     => 'rows',
		label_en => "Value of ROWS attribute of TEXTAREA tag (textarea height)",
		label_ru => "Значение атрибута ROWS тега TEXTAREA (высота редактора)",
	},

	{
		name     => 'width',
		label_en => "Value of WIDTH attribute.",
		label_ru => "Значение атрибута WIDTH (ширина)",
	},

	{
		name     => 'height',
		label_en => "Value of HEIGHT attribute",
		label_ru => "Значение атрибута HEIGHT (высота)",
	},

	{
		name     => 'title',
		label_en => "Value of TITLE attribute (tooltip text)",
		label_ru => "Значение атрибута TITLE (всплывающий текст)",
	},

	{
		name     => 'cols',
		label_en => "Value of COLS attribute of TEXTAREA tag (textarea width)",
		label_ru => "Количество столбцов",
	},

	{
		name     => 'values',
		label_en => "Data dictionnary for a field: arrayref of hashrefs with fields 'id' (possible field value) and 'label' (displayed). In 'checkboxes' field, hashrefs can contain 'items' elements referring to similar arrays, in this case, the tree is displayed.",
		label_ru => "Словарь данных для поля редактирования: список хэшей с ключами 'id' (возможное значение поля) и 'label' (видимая метка). Для поля типа 'checkboxes' хэши могут содержать элементы 'items' со ссылками на аналогичные массивы: в этом случае отрисовывается дерево.",
	},

	{
		name     => 'empty',
		label_en => "Label corresponding to a non-positive value (first in list), like '[no value]', '<Choose sometyhing!>' etc.",
		label_ru => "Надпись, соответствующая неположительному значению поля, появляется первой в списке. Как правило, это '[не определено]', '[Выберите!]' и т. п.",
	},

	{
		name     => 'esc',
		label_en => "URL referenced by the Escape button (also opened when pressing hardware Esc)",
		label_ru => "Ссылка с кнопки 'выход', открываемая также при нажатии на клавишу Esc",
	},

	{
		name     => 'back',
		label_en => "URL referenced by the Back button (also opened when pressing hardware Esc)",
		label_ru => "Ссылка с кнопки 'назад', открываемая также при нажатии на клавишу Esc",
	},

	{
		name     => 'additional_buttons',
		label_en => "Additional buttons definitions (between ok and cancel)",
		label_ru => "Описания дополнительных кнопок (между ok и cancel)",
	},

	{
		name     => 'left_buttons',
		label_en => "Additional buttons definitions (before ok)",
		label_ru => "Описания дополнительных кнопок (до ok)",
	},

	{
		name     => 'right_buttons',
		label_en => "Additional buttons definitions (after cancel)",
		label_ru => "Описания дополнительных кнопок (после cancel)",
	},

	{
		name     => 'label_ok',
		label_en => "Label for the OK button",
		label_ru => "Надпись на кнопке OK",
	},

	{
		name     => 'label_cancel',
		label_en => "Label for the Cancel button",
		label_ru => "Надпись на кнопке Cancel",
	},

	{
		name     => 'no_ok',
		label_en => "If true and 'bottom_toolbar' is undefined then draw_esc_toolbar is invoked instead of draw_ok_esc_toolbar.",
		label_ru => "Если true и 'bottom_toolbar' неопределена, то вместо draw_ok_esc_toolbar вызывается draw_esc_toolbar.",
	},

	{
		name     => 'root',
		label_en => "Supplementary path record inserted before the first one",
		label_ru => "Дополнительная запись path, предшествующая всем остальным.",
	},

	{
		name     => 'position',
		label_ru => "Номер строки итогов в выборке.",
	},

	{
		name     => 'fields',
		label_ru => "Список полей, по которым осуществляется группировка и вычисляются промежуточные итоги",
	},

	{
		name     => 'no_sum',
		label_ru => "Список числовых полей, для которых промежуточные суммы не вычисляются",
	},

	{
		name     => 'lpt',
		label_en => "If true, 'MS Excel' and 'Print' buttons are shown",
		label_ru => "Если истина, то показываются кнопки 'MS Excel' и 'Печать'",
	},

	{
		name     => 'kind',
		label_en => "Redirection kind:<ul> <li>'internal' (apache only); <li>'http' (response code 302) or <li>'js' (with onLoad handler)",
		label_ru => "Тип перенаправления: 'http' (ответ с кодом 302) или 'js' (через обработчик onLoad)",
	},

	{
		name     => 'before',
		label_en => "When kind is 'js', this option is the JS code executed before the redirection",
		label_ru => "При перенаравлении типа 'js' эта опция исполняется как JavaScript на клиенте до перенаправления",
	},

	{
		name     => 'src',
		label_ru => "Ссылка на мультимедиа-файл",
	},

	{
		name     => 'autostart',
		label_ru => "Если true, то воспроизведение автоматически запускается при загрузке страницы",
	},

	{
		name     => 'src_type',
		label_ru => "MIME-тип мультимедийного содержимого",
	},


);

################################################################################

@subs = (

					#######################################

	{
		name     => 'fake_select',
		syn      => <<EO,


	top_toolbar => [{},
	
		fake_select (),
	
	],
	
EO
		label_ru => 'Стандартный переключатель статусов для верхней панели таблицы',
		see_also => [qw(draw_table)],
	},

					#######################################

	{
		name     => 'del',
		syn      => <<EO,
	
	...
	
	right_buttons => [del (\$data)];
	
	...
	
EO
		label_ru => 'Стандартная кнопка удаления/восстановления для нижней панели формы',
		see_also => [qw(draw_form)],
	},

					#######################################

	{
		name     => 'lrt_start',
		syn      => <<EO,
	lrt_start ();
EO
		label_ru => 'Инициализирует прогресс-индикатор',
		see_also => [qw(lrt_finish lrt_print lrt_println lrt_ok)],
	},

					#######################################

	{
		name     => 'lrt_finish',
		syn      => <<EO,
	lrt_finish ('Data loading is over. Congratulations.', '/?type=users');
EO
		label_ru => 'Закрывает прогресс-индикатор',
		see_also => [qw(lrt_start lrt_print lrt_println lrt_ok)],
	},
					
					#######################################

	{
		name     => 'lrt_print',
		syn      => <<EO,
	lrt_print ('Waiting...');
EO
		label_ru => 'Сообщение на прогресс-индикаторе -- незакрытое (без перевода строки)',
		see_also => [qw(lrt_start lrt_finish lrt_println lrt_ok)],
	},

					#######################################

	{
		name     => 'lrt_println',
		syn      => <<EO,
	lrt_print ('Waiting...'});
	lrt_println (' This is it.');
EO
		label_ru => 'Сообщение на прогресс-индикаторе -- закрытое (с переводом строки). Вместо этой функции обычно используется lrt_ok ()',
		see_also => [qw(lrt_start lrt_finish lrt_print lrt_ok)],
	},

					#######################################

	{
		name     => 'lrt_ok',
		syn      => <<EO,
	lrt_ok ();
	lrt_ok ('File not found!', 1);
EO
		label_ru => 'Сообщение на прогресс-индикаторе об успехе или неуспехе операции (с переводом строки)',
		see_also => [qw(lrt_start lrt_finish lrt_print lrt_println)],
	},


					#######################################

	{
		name     => 'sql_undo_relink',
		syn      => <<EO,
	sql_undo_relink ('users', [\$rehabilitated_id]);
EO
		label_ru => 'Восстанавливает значения внешних ссылок на заданные записи, изменённые в результате ошибочного применения sql_do_relink.',
	},

					#######################################

	{
		name     => 'sql_do_relink',
		syn      => <<EO,		
	sql_do_relink ('users', [\$old_id, \$wrong_id] => \$new_id);		
EO
		label_ru => 'Заменяет во всех ссылках на указанную таблицу страрые значения на новое, удаляет старые записи и проставляет им ссылку is_merged_to на новую.',		
	},

					#######################################

	{
		name     => 'get_ids',
		syn      => <<EO,
		
			# _user_17=1&_user_23=1&_user_75=1
					
			my \@ids = get_ids ('user'); # (17, 23, 75)
		
EO
		label_en => 'Get id list from parameter names',
		label_ru => 'Получение списка id из имён параметров',
		
	},


					#######################################

	{
		name     => 'vld_date',
		syn      => <<EO,
			
	vld_date ('dt_from');  # mandatory
	vld_date ('dt_to', 1); # nullable
		
	!\$_REQUEST {_dt_to} or \$_REQUEST {_dt_from} le \$_REQUEST {_dt_to} or return 'Dates skewed!!!';
		
EO
		label_ru => 'Преобразование дат вида "dd.mm.yyyy" или "dd/mm/yy" или "d m" (для текущего года) к виду "yyyy-mm-dd" с валидацией.',		
		see_also => [qw(vld_inn_10 vld_okpo vld_ogrn vld_unique)],
	},

					#######################################

	{
		name     => 'vld_inn_10',
		syn      => <<EO,
	vld_inn_10 ('inn');    # mandatory
	vld_inn_10 ('inn', 1); # nullable
EO
		label_ru => 'Проверка контрольной суммы 10-значного кода ИНН (юридических лиц).',
		see_also => [qw(vld_date vld_okpo vld_ogrn vld_unique)],
	},

					#######################################

	{
		name     => 'vld_okpo',
		syn      => <<EO,
	vld_okpo ('okpo');    # mandatory
	vld_okpo ('okpo', 1); # nullable
EO
		label_ru => 'Проверка контрольной суммы ОКПО.',
		see_also => [qw(vld_inn_10 vld_date vld_ogrn vld_unique)],
	},

					#######################################

	{
		name     => 'vld_ogrn',
		syn      => <<EO,
	vld_okpo ('ogrn');    # mandatory
	vld_okpo ('ogrn', 1); # nullable
EO
		label_ru => 'Проверка контрольной суммы ОГРН (номера в ЕГРЮЛ).',
		see_also => [qw(vld_inn_10 vld_okpo vld_date vld_unique)],
	},
					#######################################

	{
		name     => 'vld_unique',
		options  => [qw(field/label)],
		syn      => <<EO,
			
		vld_unique ('roles', {   
			field => 'label',  
			value => $_REQUEST {label},  
			id    => $_REQUEST {id},   
		}) or return "#_label#:Duplicate label!"; 
		
		vld_unique ('roles', {   
			field => 'label',   
		}) or return "#_label#:Duplicate label!";
		
		vld_unique ('roles') or return "#_label#:Duplicate label!";

EO
		label_en => 'Check for uniqueness',
		label_ru => 'Проверка единственности записи с заданным значением поля',
		see_also => [qw(vld_inn_10 vld_okpo vld_ogrn vld_date)],
	},

					#######################################

#	{
#		name     => 'vld_noref',
#		syn      => <<EO,
#			
#			vld_noref ('users', {    
#				id         => $_REQUEST {id},    
#				field      => 'id_role',  
#				data_field => 'label',  
#				message    => 'This record is referenced by \"$label\". Deletion cancelled.',
#			}); 
#			
#			vld_noref ('users');
#
#EO
#		
#		label_en => 'Check for external references',		
#		label_ru => 'Проверка отсутствия ссылок на данную запись',
#		
#	},


					#######################################

	{
		name     => 'async',
		syn      => <<EO,
			
		async 'send_mail', ({
			to           => 'foo\@bar.com',
			subject      => 'Spam',
			text         => 'You win!!!',
		});		

EO
		label_en => 'Launches a sub with given args in async mode',
		label_ru => 'Запуск процедуры с заданным набором параметров в асинхронном режиме',
	},

					#######################################

	{
		name     => 'send_mail',
		options  => [qw(to subject text href attach content_type)],
		syn      => <<EO,
	
		my \$file = sql_upload_file (...);
		
		send_mail ({
			to      => \$id_user,
			subject => 'Notification',
			text    => 'We want you to know...',
			href    => "/?type=this_type&id=\$_REQUEST{id}",
			attach  => \$file,
		});		

		send_mail ({
			to           => {
				label => 'Customer',
				mail  => 'foo\@bar.com',
			},
			subject      => 'Notification',
			text         => 'We want you to &lt;b&gt;know&lt;b&gt;...',
			content_type => 'text/html',
			href         => "http://www.perl.com",
		});		
		
		send_mail ({
			to           => ['foo\@bar.com', 'baz\@bar.com'],
			subject      => 'Spam',
			text         => 'You win!!!',
		});		

EO
		label_en => 'Sends a mail message',
		label_ru => 'Отправка e-mail',
		see_also => [qw(encode_mail_header upload_file sql_upload_file)],
	},

					#######################################

	{
		name     => 'encode_mail_header',
		label_en => 'B-encodes the mail header',
		label_ru => 'B-кодирует 1-й аргумент. Charset (2-й аргумент) по умолчанию windows-1251. Если он windows-1251, то производится перекодирование в koi8-r.',
		see_also => [qw(send_mail)],
	},

					#######################################

	{
		name     => 'sql_is_temporal_table',
		label_en => 'Returns 1 if 1st argument is the name of a temporal table.',
		label_ru => 'Определяет является ли 1-й аргумент именем темпоральной таблицы.',
	},

					#######################################

	{
		name     => 'esc_href',
		label_en => '$_REQUEST {__last_query_string} decoded.',
		label_ru => 'Расшифрованное значение $_REQUEST {__last_query_string}, используемое в качестве ссылки с cancel при $conf -> {core_auto_esc}.',
		see_also => [qw(b64u_decode)],
	},

					#######################################

	{
		name     => 'fill_in',
		label_en => 'Initializes internal vocabularies: i18n and button presets.',
		label_ru => 'Начальное заполнение i18n и словаря кнопок',
		see_also => [qw(fill_in_button_presets)],
	},

					#######################################

	{
		name     => 'fill_in_button_presets',
		label_en => 'Initializes internal vocabulary of button presets.',
		label_ru => 'Начальное заполнение словаря кнопок',
		see_also => [qw(fill_in)],
	},
	
					#######################################

	{
		name     => 'js_set_select_option',
		label_en => 'Generates the js href for setting (adding?) a SELECT option in parent window. For internal use.',
		label_ru => 'Генерирует js-ссылку, выбирающую (и, возможно, добавляющую) нужную опцию в текущем SELECTе родительского окна. Для внутреннего использования.',
#		see_also => [qw(fill_in)],
	},

					#######################################

	{
		name     => 'sql_temporality_callback',
		label_en => 'Internal sub passed to DBIx::ModelUpdate when $conf -> {db_temporality} is on.',
		label_ru => 'Внутренняя процедура, передаваемая DBIx::ModelUpdate при вкючённой опции $conf -> {db_temporality}.',
#		see_also => [qw(sql_select_col)],
	},

					#######################################

	{
		name     => 'sql_select_ids',
		syn      => <<EO,
	my \$ids = sql_select_ids ('SELECT id FROM users WHERE id_role = ?', 1);
EO
		label_en => 'Returns ID list suitable for IN () clause',
		label_ru => 'Возвращает список ID, пригодный для подстановки в выражение IN (). Всегда непустой: минимум -1.',
		see_also => [qw(sql_select_col)],
	},

					#######################################

	{
		name     => 'b64u_encode',
		syn      => <<EO,
	my \$s = b64u_encode ( chr (2) );
EO
		label_en => 'URL-safe wrapper around MIME::Base64::encode',
		label_ru => 'URL-безопасный вариант MIME::Base64::encode.',
		see_also => [qw(b64u_decode)],
	},

					#######################################

	{
		name     => 'b64u_decode',
		syn      => <<EO,
	my \$s = b64u_decode ('dHlwZT12b2NzJ');
EO
		label_en => 'Inverse transformation for b64u_encode',
		label_ru => 'Обратное преобразование к b64u_encode.',
		see_also => [qw(b64u_encode)],
	},

					#######################################

	{
		name     => 'b64u_freeze',
		syn      => <<EO,
	my \$frozen = b64u_freeze (\\\%_REQUEST);
EO
		label_en => 'URL-safe wrapper around Storable (if present) or Data::Dumper (otherwise)',
		label_ru => 'URL-безопасный сериализатор структур данных на базе Storable (если он установлен) или Data::Dumper (если нет такого).',
		see_also => [qw(b64u_encode b64u_thaw)],
	},

					#######################################

	{
		name     => 'b64u_thaw',
		syn      => <<EO,
	\%_REQUEST = \%{ b64u_thaw (\$frozen) };
EO
		label_en => 'Inverse transformation for b64u_freeze',
		label_ru => 'Обратное преобразование к b64u_freeze',
		see_also => [qw(b64u_freeze b64u_decode)],
	},

					#######################################

	{
		name     => 'get_request',
		label_en => 'Set up $r and $apr. Internal use only.',
		label_ru => 'Устанавливает значения глобальных переменных $r и $apr в процедурах типа handler. Только для внутреннего использования.',
	},

					#######################################

	{
		name     => 'get_version_name',
		label_en => 'Returns the same as $Eludia::VERSION_NAME.',
		label_ru => 'Вычисляет (и кэширует) значение $Eludia::VERSION_NAME.',
	},

					#######################################

	{
		name     => 'get_mac',
		label_en => 'Returns the MAC address for the given IP or \$ENV{REMOTE_ADDRESS} unless defined. Uses `arp -a` internally. Returns an empy string if fails.',
		label_ru => 'Вычисляет MAC-адрес для заданного IP, по умолчанию \$ENV{REMOTE_ADDRESS}. Использует `arp -a`. В случае неудачи возвращает пустую строку.',
	},

					#######################################

	{
		name     => 'draw_toolbar_break',
		label_en => 'Breaks the current toolbar',
		label_ru => 'Разрывает панель с кнопками и начинает новую строку',
	},

					#######################################

	{
		name     => 'sql_assert_core_tables',
		label_en => 'Guarantees the existence of core tables in the DB. Internal use only.',
		label_ru => 'Гарантирует наличие в БД таблиц, необходимых для функционирования Eludia. Только для внутреннего использования.',
	},

					#######################################

	{
		name     => 'format_picture',
		label_en => 'Wrap around Number::Format -> format_picture hiding the number when $_USER -> {demo_level} > 1.',
		label_ru => 'Функция-обёртка над Number::Format -> format_picture, скрывающая число при $_USER -> {demo_level} > 1.',
	},


					#######################################

	{
		name     => 'redirect',
		syn      => <<EO,
	redirect ({type => 'logon', sid => ''}, {kind => 'http'});
EO
		label_en => 'Redirects the client to the given URL.',
		label_ru => 'Перенаправление клиента на заданный адрес.',
#		see_also => [qw(draw_form draw_table)],
		options  => [qw(kind/internal before)],
	},


					#######################################

	{
		name     => 'out_html',
		syn      => <<EO,
	out_html ({}, '<html></html>');
EO
		label_en => 'Internal sub outting the given HTML code',
		label_ru => 'Внутренняя процедура, подающая заданный HTML на выход',
#		see_also => [qw(draw_form draw_table)],
	},


					#######################################
					
	{
		name     => 'log_action_start',
		label_en => 'Internal logging sub invoked before the current action',
		label_ru => 'Внутренняя протоколирующая процедура, вызываемая до текщего действия',
	},

					#######################################
					
	{
		name     => 'log_action_finish',
		label_en => 'Internal logging sub invoked after the current action',
		label_ru => 'Внутренняя протоколирующая процедура, вызываемая после текщего действия',
	},

					#######################################

	{
		name     => 'trunc_string',
		syn      => <<EO,		
	trunc_string ('A long string', 6) # -> 'A long...';
EO
		label_en => 'Internal sub for truncating too long label strings',
		label_ru => 'Внутренняя процедура, укорачивающая слишком длинные строки (выходящие за границы ячеек таблиц и т. п.)',
	},

					#######################################

	{
		name     => 'keep_alive',
		syn      => <<EO,		
	keep_alive (73548324387324);
EO
		label_en => 'Internal sub keeping the given session alive',
		label_ru => 'Внутренняя процедура, поддерживающая заданную сессию актуальной',
#		see_also => [qw(draw_form draw_table)],
	},


					#######################################

	{
		name     => 'js_ok_escape',
		options  => [qw(name)],
		syn      => <<EO,		
		
	js_ok_escape ({
		name        => 'form1',
		confirm_ok  => 'Apply changes?',
		confirm_esc => 'Quit without saving changes?',
	});
		
EO
		label_en => 'JavaScript handler for Enter and Esc keys. Normally invoked by draw_form. May be needed to invoke manually for bottom toolbars after draw_table.',
		label_ru => 'JavaScript-обработчик для клавиш Enter и Esc. Обычно вызывается автоматически из-под draw_form. Может вывзываться вручную при отрисовке нижней кнопочной панели при draw_table.',
		see_also => [qw(draw_form draw_table)],
	},

					#######################################

	{
		name     => 'js_escape',
		syn      => <<EO,		
		
	js_escape ('So called "foo"'); # --> So called \'foo\'
		
EO
		label_en => 'Generate a valid JavaScript string literal for agiven scalar',
		label_ru => 'Генерирует корректный литерал строки JavaScript для заданного скаляра',
#		see_also => [qw(headers draw_table draw_table_header order)],
	},


					#######################################

	{
		name     => 'interpolate',
		syn      => <<EO,		
		
	interpolate ('2 * 2'); # == 4
		
EO
		label_en => 'Internal sub evaluting the given Perl expression with given source',
		label_ru => 'Внутренняя подпрограмма для вычисления выражения по заданному исходному тексту',
#		see_also => [qw(headers draw_table draw_table_header order)],
	},


					#######################################

	{
		name     => 'hrefs',
		syn      => <<EO,		
		
	[
		label => 'Title',
		hrefs ('title'),
	]
		
# is the same as 	
		
	[
		{
			label => 'Title',
			href  => {order => 'title'},
			href_asc => {order => 'title'},
			href_desc => {order => 'title', desc => 1},
		}
	]
EO
		label_en => 'Shortcut for quick table headers definition (DEPRECATED)',
		label_ru => 'Компактное описание табличного заголовка (УСТАРЕЛО)',
		see_also => [qw(headers draw_table draw_table_header order)],
	},
	

					#######################################

	{
		name     => 'sql_delete_file',
		syn      => <<EO,		
	sql_delete_file ({
		table => 'images',
		file_path_columns => ['path_big', 'path_small'],
	});
EO
		label_en => 'Delete files corresponding to the record in the specified table.',
		label_ru => 'Удаление с диска файлов, соответствующих записи заданной таблицы.',
		see_also => [qw(delete_file)],
	},

					#######################################

	{
		name     => 'sql_select_loop',
		syn      => <<EO,		
	
	my \$sum = 0;
	sql_select_loop (
		'SELECT * FROM my_data WHERE year = ?', 
		sub { \$sum += non_linear_function (\$i -> {field}); },
		2000
	);
EO
		label_en => 'Iterates over a given recordset with a given callback. Good for huge selections.',
		label_ru => 'Последовательный вызов заданной подпрограммы для каждой записи в заданной выборке.',
		see_also => [qw(sql_select_all)],
	},

					#######################################
					
	{
		name     => 'sql_reconnect',
		syn      => <<EO,		
			sql_reconnect ();
EO
		label_en => 'Internal sub maintainning the [my]sql server connection.',
		label_ru => 'Внутренняя процедура поддержки связи с [my]sql-сервером.',
		see_also => [qw(sql_disconnect)],
	},
	
					#######################################

	{
		name     => 'sql_disconnect',
		label_en => 'Closes the database connection.',
		label_ru => 'Закрывает текущую связь с БД',
		see_also => [qw(sql_reconnect)]
	},
	

					#######################################

	{
		name     => 'require_fresh',
		syn      => <<EO,		
			require_fresh ("\${_PACKAGE}Content::\$\$page{type}");
EO
		label_en => 'Internal sub loading the last version of the given module.',
		label_ru => 'Внутренняя процедура загрузки последней версии требуемого модуля.',
		see_also => [qw(require_content get_item_of_)],
	},
					#######################################

	{
		name     => 'require_content',
		syn      => <<EO,		
			require_content 'users';
EO
		label_ru => 'Загрузка последней версии Content-модуля данного типа',
		see_also => [qw(require_fresh)],
	},

					#######################################

	{
		name     => 'get_item_of_',
		syn      => <<EO,		
			my \$user = get_item_of_ 'users';
EO
		label_ru => 'Загрузка последней версии Content-модуля данного типа и выполнение get-процедуры для него',
		see_also => [qw(require_fresh require_content)],
	},


					#######################################

	{
		name     => 'select__static_files',
		syn      => <<EO,		
EO
		label_en => 'Internal sub sending static files included is Eludia.pm engine back to the client.',
		label_ru => 'Внутренняя процедура выдачи на клиент внутренних статических файлов, содержащихся в дистрибутиве Eludia.pm.',
#		see_also => [qw(hotkey)],
	},

					#######################################

	{
		name     => 'register_hotkey',
		options  => [qw(ctrl)],
		syn      => <<EO,		
EO
		label_en => 'Internal sub for defining a hotkey for the current page. Use "hotkey" instead.',
		label_ru => 'Внутреннее определение горячей клавиши. В прикладных программах следует использовать "hotkey"',
		see_also => [qw(hotkey)],
	},


					#######################################

	{
		name     => 'hotkey',
		syn      => <<EO,		
		
	hotkey ({
		code => F11,
		type => 'href',
		data => 'http://www.megapr0n.edu/',
		ctrl => 1,
		alt  => 0,
	});
	
EO
		label_en => 'Define a hotkey for the current page',
		label_ru => 'Определение горячей клавиши (F1-F12 или скан-код)',
#		see_also => [qw(draw_table draw_table_header headers)],
	},

					#######################################

	{
		name     => 'order',
		syn      => <<EO,		
		
	my $order = order ('my_table.title', # default
		number => 'alien_table.n',
	))			
	
EO
		label_en => 'Shortcut for quick ORDER BY content generation',
		label_ru => 'Генерация выражения ORDER BY на основании параметров order и desc',
		see_also => [qw(draw_table draw_table_header headers)],
	},

					#######################################

	{
		name     => 'headers',
		syn      => <<EO,		
		
	headers (qw(
		Title			title
		Number_of_pages		number
	))			
		
# is the same as 	
		
	[
		{
			label => 'Title',
			href  => {order => 'title'},
			href_asc => {order => 'title'},
			href_desc => {order => 'title', desc => 1},
		}
		{
			label => 'Number of pages',
			href  => {order => 'number'},
			href_asc => {order => 'number'},
			href_desc => {order => 'number', desc => 1},
		}
	]
EO
		label_en => 'Shortcut for quick table headers definition',
		label_ru => 'Компактное описание табличного заголовка',
		see_also => [qw(draw_table draw_table_header order)],
	},

					#######################################
					
	{
		name     => 'handler',
		syn      => <<EO,		
		
# In httpd.conf

	SetHandler  perl-script
	PerlModule  MYAPP
	PerlHandler MYAPP::handler # or just MYAPP
EO
		label_en => 'Apache request handler for intranet applications',
		label_ru => 'Обработчик запросов Apache для intranet-приложений',
		see_also => [qw(pub_handler)],
	},

					#######################################
					
	{
		name     => 'pub_handler',
		syn      => <<EO,		
		
# In httpd.conf

	SetHandler  perl-script
	PerlModule  MYAPP
	PerlHandler MYAPP::pub_handler
EO
		label_en => 'Apache request handler for public sites',
		label_ru => 'Обработчик запросов Apache для публичных сайтов',
		see_also => [qw(handler)],
	},

					#######################################
					
	{
		name     => 'handle_hotkey_focus',
#		options  => [qw(js_ok_escape)],
#		syn      => <<EO,		
#EO
		label_en => 'Internal sub generating JavaScript code for keyboard handling for setting focus.',
		label_ru => 'Внутренняя подпрограмма, генерирующая JavaScript-код обработки нажатия на клавишу для перемещения фокуса ввода.',
#		see_also => [qw(upload_file sql_upload_file)],
	},
			
					#######################################
	{
		name     => 'handle_hotkey_href',
#		options  => [qw(js_ok_escape)],
#		syn      => <<EO,		
#EO
		label_en => 'Internal sub generating JavaScript code for keyboard handling for following the given href.',
		label_ru => 'Внутренняя подпрограмма, генерирующая JavaScript-код обработки нажатия на клавишу для открытия заданного URL.',
#		see_also => [qw(upload_file sql_upload_file)],
	},

			
					#######################################
	{
		name     => 'get_user',
#		options  => [qw(js_ok_escape)],
		syn      => <<EO,
   	our $_USER = get_user ();
EO
		label_en => 'Internal sub fetching the current user info.',
		label_ru => 'Внутренняя подпрограмма, считывающая из БД информацию о текущем пользователе системы',
#		see_also => [qw(upload_file sql_upload_file)],
	},

					#######################################
	{
		name     => 'get_filehandle',
#		options  => [qw(js_ok_escape)],
		syn      => <<EO,
   	get_filehandle ('file');
EO
		label_en => 'Returns the file handle for the file upload field with given name. Not to be used directlty',
		label_ru => 'Возвращает дескриптор загружаемого файла, HTML-поле для которого имело заданное имя. Данную подропграмму не следует вызывать непосредственно.',
		see_also => [qw(upload_file sql_upload_file)],
	},

					#######################################
	{
		name     => 'fill_in_i18n',
#		options  => [qw(lang)],
		syn      => <<EO,
   	fill_in_i18n ('ENG', {
   		_charset                 => 'windows-1252',
		Exit                     => 'Exit',
   	});
EO
		label_en => 'I18n vocabulary initialization',
		label_ru => 'Инициализация словая i18n',
#		see_also => [qw(draw_table)],
	},

					#######################################
	{
		name     => 'dump_attributes',
#		options  => [qw(js_ok_escape)],
		syn      => <<EO,
	dump_attributes ({width => 1, height => 10});
EO
		label_en => 'Internal sub dumping the given hashref as HTML attributes',
		label_ru => 'Внутренняя подпрограмма распечатки заданного хэша как HTML-атрибутов',
#		see_also => [qw(draw_table)],
	},

					#######################################
	{
		name     => 'draw_tr',
#		options  => [qw(js_ok_escape)],
		syn      => <<EO,
	draw_tr  ({}, '<td>One</td>', '<td>Two</td>');
EO
		label_en => 'Internal sub rendering the table row',
		label_ru => 'Внутренняя подпрограмма отрисовки строки таблицы',
		see_also => [qw(draw_table)],
	},

					#######################################
	{
		name     => 'draw_table_header',
#		options  => [qw(js_ok_escape)],
		syn      => <<EO,
	draw_table_header  ([
		'No',
		{
			label => 'Title',
			href  => {order => 'title'},
			href_asc => {order => 'title'},
			href_desc => {order => 'title', desc => 1},
		}
	]);
EO
		label_en => 'Internal sub rendering the table header',
		label_ru => 'Внутренняя подпрограмма отрисовки заголовка таблицы',
		see_also => [qw(draw_table)],
	},

					#######################################
	{
		name     => 'draw_page',
#		options  => [qw(js_ok_escape)],
		syn      => <<EO,
	draw_page  ($page);
EO
		label_en => 'Internal sub rendering the whole page',
		label_ru => 'Внутренняя подпрограмма отрисовки страницы в целом',
#		see_also => [qw(draw_table)],
	},

					#######################################
	{
		name     => 'draw_one_cell_table',
		options  => [qw(js_ok_escape)],
		syn      => <<EO,
	draw_one_cell_table ({js_ok_escape => 1}, '<pre> ERROR! (just kidding) </pre>');
EO
		label_en => 'Draws the 100% width table width default style in the main area. Good for custom HTML hacking',
		label_ru => 'Отрисовка таблицы 100%-ной ширины c заданным HTML-наполнением.',
		see_also => [qw(draw_table)],
	},


					#######################################
	{
		name     => 'draw_form_field_iframe',
		options  => [qw(name href width height)],
		syn      => <<EO,
	draw_form_field_iframe ({
		name   => 'my_iframe', 
		href   => 'http://pr0n.site.org',
		width  => 10,
		height => 5,
	});
EO
		label_en => 'Renders an IFRAME form field. Called internally by draw_form',
		label_ru => 'Отрисовка IFRAME как поля формы. Вызывается автоматически из draw_form.',
		see_also => [qw(draw_form)],
	},

					#######################################
	{
		name     => 'draw_form_field',
#		options  => [qw(lpt)],
		syn      => <<EO,
	draw_form_field ($field, $data);
EO
		label_en => 'Internal sub rendering a form field by given definition for the given data.',
		label_ru => 'Отрисовка поля формы по заданному описанию для заданной записи БД. Вызывается автоматически из draw_form.',
		see_also => [qw(draw_form)],
	},


					#######################################
	{
		name     => 'draw_menu',
#		options  => [qw(lpt)],
		syn      => <<EO,
	draw_menu (get_menu_for_admin ());
EO
		label_en => 'Draws the top menu of the page. Invoked automatically.',
		label_ru => 'Отрисовка главного меню страницы. Вызывается автоматически.',
		see_also => [qw(draw_vert_menu)],
	},

					#######################################
	{
		name     => 'draw_vert_menu',
#		options  => [qw(lpt)],
		syn      => <<EO,
	draw_vert_menu ([
	
		{
			name  => 'who',
			label => 'Who?',
		},
		
		BREAK,

		{	
			name => 'env',
			label => '%ENV'
		},
	]);
EO
		label_en => 'Draws the pulldown menu. Invoked automatically.',
		label_ru => 'Отрисовка выпадающего меню. Вызывается автоматически.',
		see_also => [qw(draw_menu)],
	},


					#######################################
	{
		name     => 'draw_auth_toolbar',
		options  => [qw(lpt)],
		syn      => <<EO,
	draw_auth_toolbar ({lpt => 1});
EO
		label_en => 'Draws the navigation toolbar on top of the page. Invoked automatically.',
		label_ru => 'Отрисовка верхней навигационной панели страницы. Вызывается автоматически.',
#		see_also => [qw(draw_text_cell draw_text_cells)],
	},

					#######################################

	{
		name     => 'delete_file',
#		options  => [qw(position)],
		syn      => <<EO,
	delete_file ('i/upload/foo.doc');
EO
		label_en => 'Deletes the given file by its relative path in the current document root.',
		label_ru => "Удаление заданного файла по пути, заданному относительно DocumentRoot'а",
#		see_also => [qw(draw_text_cell draw_text_cells)],
	},


					#######################################

	{
		name     => 'call_for_role',
#		options  => [qw(position)],
		syn      => <<EO,
	my \$some_concent = call_for_role ('get_some_concent', \@args);
EO
		label_en => 'Internal sub calling the given callback according the role of current user.',
		label_ru => 'Внутрення подпрограмма, вызывающая заданную callback-процедуру в соответствии с ролью текущего пользователя',
#		see_also => [qw(draw_text_cell draw_text_cells)],
	},



					#######################################

	{
		name     => 'add_totals',
		options  => [qw(position fields no_sum)],
		syn      => <<EO,
		
	add_totals ($statistics_data, {position => 0});

	my $cnt_extra_lines = add_totals ($statistics_data, {
	
		fields => [
			{name => 'id_region', top => 1, bottom => 1},
			{name => 'id_city',             bottom => 1},
		],
		
		no_sum => 'inn,kpp',
		
	});
	
EO

		label_ru => 'Добавляет строки итогов (суммы всех полей) в заданную выборку (список ссылок на хэши)',

		see_also => [qw(draw_text_cell draw_text_cells)],

	},

					#######################################

	{
		name     => 'create_url',
		syn      => <<EO,	
	create_url (
		type => 'some_other_type',
	);
	
	# /?type=my_type&id=1&sid=123456&_foo=bar --> /?type=some_other_type&id=1&sid=123456
	
EO
		label_en => 'Creates the URL inheriting all parameter values but explicitely set and starting with one underscore. Automatically applied to any HASHREF valued "href" option.',
		label_ru => 'Генерирует URL, наследующий значения всех параметров, кроме упомянутых в списке аргументов и тех, чьи имена начинаются с символа \'_\'. Неявно применяется ко всем значениям опции "href", которые заданы как ссылка на хэш',
		see_also => [qw(check_href)],
	},

					#######################################

	{
		name     => 'check_title',
		options  => [qw(title)],
		syn      => <<EO,	
	check_title ({
		...
		label => 'project "Y"',
		...
	});

	# --> {	
	# ...
	# label => 'project "Y"',
	# title => 'title="project &amp;quot;Y&amp;quot;"'
	# ...
	# }	
	
EO
		label_en => 'Adds a properly quoted TITLE tag to options hashref. Defaults to label option.',
		label_ru => 'Добавляет в опции HTML-код для атрибута TITLE. Значение по умолчанию берётся из опции label.',
		see_also => [qw(create_url)],
	},
				
					#######################################

	{
		name     => 'check_href',
		options  => [qw(href)],
		syn      => <<EO,	
	check_href ({
		...
		href => "/?type=users",
		...
	});
	
	# /?type=users --> /?type=users&sid=3543522543214387&_salt=0.635735452454
	
EO
		label_en => 'Ensures the sid parameter inheritance (session support through URL rewriting) and _salt parameter randomness (prevents from client side cacheing). Automatically applied to any option set with scalar "href" option.',
		label_ru => 'Обеспечивает наследование параметра sid (сессии через URL rewriting) и случайность параметра _salt (защипа от кэширования на клиенте). Неявно применяется ко всем наборам опциий со скалярной "href"',
		see_also => [qw(create_url)],
	},


					#######################################

	{
		name     => 'hotkeys',
		options  => [qw(code data ctrl alt off)],
		syn      => <<EO,	
	hotkeys (
		{
			code => F4,
			data => 'edit_button',
			off  => \$_REQUEST {edit},
		},
		{
			code => F10,
			data => 'ok',
			off  => \$_REQUEST {__read_only},
		},
	);
EO
		label_en => 'Setting hotkeys for anchors with known IDs.',
		label_ru => 'Установка клавиатурных ускорителей для гиперссылок с известными атрибутами ID.',
#		see_also => [qw()],
	},

					#######################################

	{
		name     => 'delete_fakes',
		syn      => <<EO,	
	delete_fakes ('users');
EO
		label_en => 'Garbage collection: delete fake records which belong to non-active sessions. Automatically invoked before any "do_create_$type" callback sub.',
		label_ru => 'Сборка мусора: удаление всех fake-записей, принадлежащих неактивным сессиям. Автоматически вызывается перед каждой callback-процедурой "do_create_$type".',
#		see_also => [qw()],
	},

					#######################################

	{
		name     => 'download_file',
		options  => [qw(file_name path no_force_download)],
		syn      => <<EO,	
	download_file ({
		file_name         => 'report.doc',
		path              => '/i/upload/misc/543543545735-5455',
		no_force_download => 1,
	});
EO
		label_en => 'Sends the file response to the client.',
		label_ru => 'Инициирует загрузку файла на клиент.',
		see_also => [qw(sql_download_file upload_file)],
	},

					#######################################

	{
		name     => 'sql_do_update',
		syn      => <<EO,	
	sql_do_update ('users', ['name', 'login']);
EO
		label_en => 'Updates the record with id = $_REQUEST {id} in the table which name is the 1st argument. Updated fields are listed in the 2nd argument. The value for each field $f is $_REQUEST {"_$f"}. Moreover, the "fake" field is set to 0 unless the 3rd argument is true.',
		label_ru => 'Обновляет запись c id = $_REQUEST {id} в таблице, имя которой есть 1-й аргумент. Список обновляемых полей -- 2-й аргумент. Значение каждого поля $f определяется как $_REQUEST {"_$f"}. В поле "fake" записывается 0, если только не является истиной 3-й аргумент.',
		see_also => [qw(sql_do_insert sql_do_delete)]
	},

					#######################################

	{
		name     => 'sql_do_insert',
		syn      => <<EO,	
	sql_do_insert ('users', {
		name1	=> 'No',
		name2	=> 'Name',
	});
EO
		label_en => 'Inserts a new record in the table and returns its ID. Unless the "fake" value is set, it defaults to $_REQUEST {sid}.',
		label_ru => 'Вставляет новую запись в таблицу и возвращает её номер. Если значение "fake" не задано, оно принимается равным $_REQUEST {sid}.',
		see_also => [qw(sql_do_update sql_do_delete sql_select_id)]
	},

					#######################################

	{
		name     => 'sql_select_id',
		syn      => <<EO,	
	my $id_user = sql_select_id ('users', {
		label	=> 'Foo B. Baz',
		login	=> 'foo',
		fake    => 0,
	}, ['login']);
EO

		label_ru => 'Находит в таблице запись по значениям ключевых полей (их имена заданы в качестве 2-го параметра) или, если таковой не обнаружено, вставляет новую запись. В любом случае возвращает номер заданной записи. Если значение "fake" не задано, оно принимается равным $_REQUEST {sid}.',
		see_also => [qw(sql_do_insert)]
	},

					#######################################

	{
		name     => 'upload_file',
		options	 => [qw(name dir)],
		syn      => <<EO,	
	my \$file = upload_file ({
		name             => 'photo',
		dir		 => 'user_photos'
	});
	
#	{
#		file_name => 'C:\\sample.jpg',
#		size      => 86219,
#		type      => 'image/jpeg',
#		path      => 'i/upload/user_photos/57387635438-3543',
#		real_path => '/var/virtualhosts/myapp/docroot/i/upload/user_photos/57387635438-3543'
#	};
	
EO
		label_en => 'Uploads the file.',
		label_ru => 'Загружает файл на сервер.',
		see_also => [qw(sql_upload_file download_file)],
	},


					#######################################

	{
		name     => 'sql_upload_file',
		options	 => [qw(name dir table path_column type_column file_name_column size_column add_columns)],
		syn      => <<EO,	
	sql_upload_file ({
		name             => 'photo',
		table            => 'users',
		dir		 => 'i/upload/user_photos'
		path_column      => 'path_photo',
		type_column      => 'type_photo',
		file_name_column => 'flnm_photo',
		size_column      => 'size_photo',
		add_columns      => [
			flag => 'erected',
		],
	});
EO
		label_en => 'Uploads the file and stores its info in the table.',
		label_ru => 'Загружает файл еа сервер и записывает его данные в таблицу.',
		see_also => [qw(upload_file sql_download_file)],
	},

					#######################################

	{
		name     => 'sql_download_file',
		options	 => [qw(table path_column type_column file_name_column)],
		syn      => <<EO,	
	sql_download_file ({
		path_column      => 'path_photo',
		type_column      => 'type_photo',
		file_name_column => 'flnm_photo',
	});
EO
		label_en => 'Sends the file download response. The file info is fetched from the table record with with id = $_REQUEST {id}.',
		label_ru => 'Инициирует загрузку файла на клиент. Информация о файле берётся из записи таблицы с id = $_REQUEST {id}.',
		see_also => [qw(sql_upload_file)],
	},


					#######################################

	{
		name     => 'sql_do_delete',
		options	 => [qw(file_path_columns)],
		syn      => <<EO,	
	sql_do_delete ('users', {
		file_path_columns => ['path_photo'],
	});
EO
		label_en => 'Deletes the record with id = $_REQUEST {id} in the table which name is the 1st argument. With all attached files, if any.',
		label_ru => 'Удаляет из таблицы запись с id = $_REQUEST {id}. Если заданы file_path_columns, то стирает соответствующие файлы.',
		see_also => [qw(sql_do_update sql_do_insert)]
	},

					#######################################

	{
		name     => 'sql_last_insert_id',
		syn      => <<EO,	
	my $id = sql_last_insert_id;
EO
		label_en => 'Fetches the last INSERT ID. Usually you should not call this sub directly. Use the sql_do_insert return value instead.',
		label_ru => 'Возвращает последний сгенерированный ID. Как правило, вместо этой функции желатенльно использовать значение, вычисляемое sql_do_insert.',
		see_also => [qw(sql_do_insert)]
	},

					#######################################

	{
		name     => 'add_vocabularies',
		syn      => <<EO,	
	\$item -> add_vocabularies ('roles', 
		'departments', 
		'sexes' => {order => 'id'}
	);
EO
		label_en => 'Add multiple data vocabularies simultanuousely.',
		label_ru => 'Добавляет к объекту сразу несколько словарей данных.',
		see_also => [qw(sql_select_vocabulary)]
	},

					#######################################

	{
		name     => 'sql_do',
		syn      => <<EO,	
	sql_do ('INSERT INTO my_table (id, name) VALUES (?, ?)', \$id, \$name);
EO
		label_en => 'Executes the DML statement with the given arguments.',
		label_ru => 'Исполняет оператор DML с заданными аргументами.',
#		see_also => [qw()]
	},

					#######################################

	{
		name     => 'sql_select_all_cnt',
		syn      => <<EOP,	
	my (\$rows, \$cnt)= sql_select_all_cnt (&lt;&lt;EOS, ...);
		SELECT 
			...
		FROM 
			...
		WHERE 
			...
		ORDER BY 
			...
		LIMIT
			\$start, 15
EOS
EOP
		label_en => 'Executes a given SQL (SELECT) statement with supplied parameters and returns the resultset (listref of hashrefs) and the number of rows in the corresponding selection without the LIMIT clause.',
		label_ru => 'Исполняет оператор SQL с заданными аргументами и возвращает выборку (список хэшей), а также объём выборки без учёта ограничителя LIMIT.',
#		see_also => [qw()]
	},

					#######################################

	{
		name     => 'sql_select_all',
		syn      => <<EOP,	
	my \$rows = sql_select_all (&lt;&lt;EOS, ...);
		SELECT 
			...
		FROM 
			...
		WHERE 
			...
		ORDER BY 
			...
EOS
EOP
		label_en => 'Executes a given SQL (SELECT) statement with supplied parameters and returns the resultset (listref of hashrefs).',
		label_ru => 'Исполняет оператор SQL с заданными аргументами и возвращает выборку (список хэшей).',
		see_also => [qw(sql_select_loop)]
	},

					#######################################

	{
		name     => 'sql_select_col',
		syn      => <<EOP,	
	my \@col = sql_select_col (&lt;&lt;EOS, ...);
		SELECT 
			id
		FROM 
			...
		WHERE 
			...
EOS
EOP
		label_en => 'Executes a given SQL (SELECT) statement with supplied parameters and returns the first column of the resultset (list).',
		label_ru => 'Исполняет оператор SQL с заданными аргументами и возвращает первый столбец выборки (список).',
#		see_also => [qw()]
	},

					#######################################

	{
		name     => 'sql_select_array',
		syn      => <<EOP,	
	my \$r = sql_select_array (&lt;&lt;EOS, ...);
		SELECT 
			...
		FROM 
			...
		WHERE 
			id = ?
EOS
EOP
		label_en => 'Executes a given SQL (SELECT) statement with supplied parameters and returns the first record of the resultset (array, not arrayref).',
		label_ru => 'Исполняет оператор SQL с заданными аргументами и возвращает первую запись выборки (список, не по ссылке).',
#		see_also => [qw()]
	},

					#######################################

	{
		name     => 'sql_select_scalar',
		syn      => <<EOP,	
	my \$label = sql_select_scalar (&lt;&lt;EOS, ...);
		SELECT 
			label
		FROM 
			...
		WHERE 
			id = ?
EOS
EOP
		label_en => 'Executes a given SQL (SELECT) statement with supplied parameters and returns the first field of the first record of the resultset (scalar).',
		label_ru => 'Исполняет оператор SQL с заданными аргументами и возвращает первое поле первой записи выборки (скаляр).',
#		see_also => [qw()]
	},

					#######################################

	{
		name     => 'sql_select_path',
		options  => [qw(id_param/id root)],
		syn      => <<EOP,	
	\$item -> {path} = sql_select_path ('rubrics', \$_REQUEST {id}, {
		id_param => 'parent',
		root     => {
			type => 'my_objects',
			name => 'All my objects',
			id   => ''			
		}
	});
EOP
		label_en => 'Fetches the path to the current object from the hierarchical (PREV id = parent) table in the form suitable for draw_path sub.',
		label_ru => 'Извлекает путь к текущей записи в иерархической (PREV id = parent) таблице в форме, пригодной для передачи процедуре draw_path.',
		see_also => [qw(draw_path sql_select_subtree)]
	},
	
					#######################################

	{
		name     => 'sql_select_subtree',
#		options  => [qw()],
		syn      => <<EOP,	
	my \@child_rubrics = sql_select_subtree ('rubrics', \$_REQUEST {id});
EOP
		label_en => 'Fetches all the child IDs from the hierarchical (PREV id = parent) table as an array.',
		label_ru => 'Извлекает все дочерние ID из иерархической (PREV id = parent) таблицы в виде массива',
		see_also => [qw(sql_select_path)]
	},

					#######################################

	{
		name     => 'sql_select_hash',
		syn      => <<EOP,	
				
	my \$r = sql_select_hash (&lt;&lt;EOS, $_REQUEST {id});
		SELECT 
			*
		FROM 
			users
		WHERE 
			id = ?
EOS

	my \$user = sql_select_hash ('users');

EOP
		label_en => 'Executes a given SQL (SELECT) statement with supplied parameters and returns the first record of the resultset (hashref). If all fields belong to the same table and the ID is $_REQUEST {id} then you can use the simplified form: only table name is supplied.',
		label_ru => 'Исполняет оператор SQL с заданными аргументами и возвращает первую запись выборки (хэш). Если в запросе участвует только 1 таблица, а ID совпадает с $_REQUEST {id}, то вместо SQL можно указать только имя таблицы.',
#		see_also => [qw()]
	},

					#######################################

	{
		name     => 'sql_select_vocabulary',
		syn      => <<EOP,	
	\$item -> {roles} = sql_select_vocabulary ('roles');
	
	\$item -> {types} = sql_select_vocabulary ('types', {order => 'code'});
	
EOP
		options  => [qw(order/label)],
		label_en => 'Selects all records from a given table where fake=0 ordered by label ascending (data vocabulary).',
		label_ru => 'Выбирает из заданной таблицы все записи, для которых fake=0 в опрядке возрастания label (словарь данных).',
		see_also => [qw(add_vocabularies draw_form_field_radio draw_form_field_select)]
	},


					#######################################

	{
		name     => 'draw_centered_toolbar_button',
		options  => [qw(off href target/_self confirm preconfirm onclick label preset)],
		label_en => 'Draws a button on a toolbar. Invoked from "draw_centered_toolbar" sub.',
		label_ru => 'Отрисовывает кнопку на панели снизу от формы ввода. Вызывается из-под "draw_centered_toolbar"',
		see_also => [qw(draw_centered_toolbar)]
	},


					#######################################

	{
		name     => 'draw_centered_toolbar',
		options  => [qw()],
		syn      => <<EO,
	draw_centered_toolbar ({}, [
		{
			icon => 'ok',     
			label => 'OK', 
			href => '#', 
			onclick => "document.form.submit()"
		},
		{
			icon => 'cancel', 
			label => 'Esc', 
			href => '/', 
			id => 'esc'
		},
	 ])		
EO
		label_en => 'Draws a toolbar on bottom of an input form. Usually you should use draw_ok_esc_toolbar instead.',
		label_ru => 'Отрисовывает панель снизу от формы ввода. Как правило, следует использовать draw_ok_esc_toolbar.',
		see_also => [qw(
			draw_form 
			draw_table
			draw_centered_toolbar_button
			draw_back_next_toolbar
			draw_close_toolbar
			draw_esc_toolbar
			draw_ok_esc_toolbar
		)]
	},

					#######################################

	{
		name     => 'draw_back_next_toolbar',
		options  => [qw(additional_buttons left_buttons right_buttons back type)],
		label_en => 'Draws toolbar with Back and Next buttons. Used in wizards',
		label_ru => 'Отрисовывает панель с кнопками "назад" и "далее". Применяется для пошаговых "мастеров".',
		see_also => [qw(draw_centered_toolbar)]
	},

					#######################################

	{
		name     => 'draw_close_toolbar',
		options  => [qw(additional_buttons left_buttons right_buttons)],
		label_en => 'Draws toolbar with a close button. Used in popup windows.',
		label_ru => 'Отрисовывает панель с кнопкой "закрыть". Применяется для всплывающих окон.',
		see_also => [qw(draw_centered_toolbar)]
	},

					#######################################

	{
		name     => 'draw_esc_toolbar',
		options  => [qw(esc/?type=$_REQUEST{type} additional_buttons left_buttons right_buttons href/esc(?type=$_REQUEST{type}))],
		label_en => 'Draws toolbar with an escape button.',
		label_ru => 'Отрисовывает панель с кнопкой "выход"',
		see_also => [qw(draw_centered_toolbar)]
	},

					#######################################

	{
		name     => 'draw_ok_esc_toolbar',
		options  => [qw(name esc/?type=$_REQUEST{type} additional_buttons left_buttons right_buttons label_ok/применить label_cancel/вернуться href/esc(?type=$_REQUEST{type}))],
		label_en => 'Draws toolbar with an escape button.',
		label_ru => 'Отрисовывает панель с кнопкой "выход"',
		see_also => [qw(draw_centered_toolbar)]
	},

					#######################################

	{
		name     => 'set_cookie',
#		options  => [],
		label_en => 'Sets the Cookie response header.',
		label_ru => 'Устанавливает заголовок cookie.',
		syn      => <<EO,
			set_cookie (
				-name    =>  'psid',
				-value   =>  \$sid,
				-expires =>  '+3M',
				-path    =>  '/',
			);      
EO
#		see_also => [qw()]
	},
			
					#######################################

	{
		name     => 'draw_form',
		options  => [qw(action/update type/$_REQUEST{type} id/$_REQUEST{id} name/form esc target/invisible bottom_toolbar/draw_ok_esc_toolbar() no_ok keep_params off)],
		syn      => <<EO,
		
	my \$data = {				# comes from 'get_item_of_users' callback sub
	
		id	 => 1,
		name     => 'J. Doe',
		login    => 'scott',
		password => 'tiger',
		id_role  => 1,
		
		path    => [		# passed to draw_path (see)
			{type => 'users', name => 'Everybody'},
			{type => 'users', name => 'J. Doe', id => 1},
		],
		
		roles    => [		# vocabulary
			{id => 1, name => 'admin'},
			{id => 2, name => 'user'},
		],
			
	};
		
	draw_form ({
			name => 'form1',
			esc  => '/?type=loosers&parent=13',

			left_buttons => [
				{
					preset => 'prev',
					href  => "/?type=users&action=disable&id=$$data{id}"
				}
			],

			additional_buttons => [
				{
					label  => 'Disable it',
					href   => "/?type=users&action=disable&id=$$data{id}"
					hotkey => {
						code => F11,
						ctrl => 1,
					}
				}
			],
			
			right_buttons => [
				{
					preset => 'next',
					href  => "/?type=users&action=disable&id=$$data{id}"
				}
			],
			
		}, 
		
		\$data
		
		[
			{			# text field -- by default
				name  => 'name',
				label => 'Name',
				size  => 30,
			},
			[			# 2 fields at one line
				{
					name  => 'login',
					mandatory  => 1,
					label => '&login',
					size  => 30,
				},
				{
					name  => 'password',
					label => 'Password',
					type  => 'password',
					size  => 30,
 				},
			],
			{			# drop-down
				name   => 'id_role',
				label  => 'Role',
				type   => 'select',
				values => \$data -> {roles},
			},
		]
	);
EO
		label_en => 'Draws the input form. Individual fields are rendered with "draw_form_field_$type" (default type is "string") subs, see references below. For each input $_, the "value" option defaults to $data -> {$_ -> {name}}. Options are passed to the bottom toolbar rendering subroutine (as usual, draw_ok_esc_toolbar).',
		label_ru => 'Отрисовывает форму ввода данных. Отдельные поля отрисовываются подпрограммами "draw_form_field_$type" (тип по умолчанию -- "string"), см. ссылки ниже. Для каждого поля ввода $_ опция "value" по умолчанию определяется как $data -> {$_ -> {name}}. Опции передаются подрпограмме отрисовки нижней панели с кнопками (обычно draw_ok_esc_toolbar)',
		see_also => [qw(
			draw_ok_esc_toolbar
			draw_form_field_button
			draw_form_field_datetime 
			draw_form_field_checkbox
			draw_form_field_checkboxes
			draw_form_field_file 
			draw_form_field_image
			draw_form_field_hgroup 
			draw_form_field_hidden
			draw_form_field_htmleditor
			draw_form_field_password
			draw_form_field_radio
			draw_form_field_select
			draw_form_field_static
			draw_form_field_string 
			draw_form_field_text
		)]
	},

					#######################################

	{
		name     => 'draw_form_field_banner',
		options  => [qw(label)],
		label_ru => 'Отрисовывает горизонтальный заголовок во всю ширину формы. Вызывается процедурой draw_form.',
		see_also => [qw(draw_form)]
	},

					#######################################

	{
		name     => 'esc',
		label_ru => 'Сокращённая форма redirect (esc_href ())',
		see_also => [qw(redirect esc_href)],
		options  => [qw(kind)],
	},

					#######################################

	{
		name     => 'draw_form_field_button',
		options  => [qw(name label onclick value)],
		label_en => 'Draws a button. Invoked by draw_form.',
		label_ru => 'Отрисовывает кнопку. Вызывается процедурой draw_form.',
		see_also => [qw(draw_form)]
	},

					#######################################

	{
		name     => 'draw_form_field_htmleditor',
		options  => [qw(name label width height off toolbar value)],
		label_en => 'Draws the WYIWYG HTML editing area (see http://www.fredck.com/FCKeditor/). Invoked by draw_form.',
		label_ru => 'Отрисовывает интерактивный редактор HTML (см. http://www.fredck.com/FCKeditor/). Вызывается процедурой draw_form.',
		see_also => [qw(draw_form)]
	},

					#######################################

	{
		name     => 'draw_form_field_image',
		options  => [qw(name label id_image src width height new_image_url)],
		label_en => 'Draws the image with a button invoking a choose dialog box. Invoked by draw_form.',
		label_ru => 'Отрисовывает картинку и кнопку, вызвыающую диалог выбора нового изображения. Вызывается процедурой draw_form.',
		see_also => [qw(draw_form)]
	},

					#######################################

	{
		name     => 'draw_form_field_color',
		options  => [qw(name label value)],
		label_ru => 'Отрисовывает элемент выбора цвета (палитру). Вызывается процедурой draw_form.',
		see_also => [qw(draw_form)]
	},

					#######################################

	{
		name     => 'draw_form_field_select',
		options  => [qw(name label value values off empty max_len onChange height)],
		label_en => 'Draws the drop down listbox. Invoked by draw_form.',
		label_ru => 'Отрисовывает выпадающий список опций. Вызывается процедурой draw_form.',
		see_also => [qw(draw_form sql_select_vocabulary)]
	},

					#######################################

	{
		name     => 'draw_form_field_checkboxes',
		options  => [qw(name label value values expand_all off cols)],
		label_en => 'Draws the group of checkboxes. Invoked by draw_form.',
		label_ru => 'Отрисовывает группу checkbox\'ов. Вызывается процедурой draw_form.',
		see_also => [qw(draw_form)]
	},

					#######################################

	{
		name     => 'draw_form_field_checkbox',
		options  => [qw(name label checked off attributes)],
		label_en => 'Draws the checkbox. Invoked by draw_form.',
		label_ru => 'Отрисовывает поле логигеского ввода (checkbox). Вызывается процедурой draw_form.',
		see_also => [qw(draw_form)]
	},

					#######################################

	{
		name     => 'draw_form_field_radio',
		options  => [qw(name label value values off)],
		label_en => 'Draws the group of radiobuttons. Invoked by draw_form.',
		label_ru => 'Отрисовывает группу радиокнопок. Вызывается процедурой draw_form.',
		see_also => [qw(draw_form sql_select_vocabulary)]
	},

					#######################################

	{
		name     => 'draw_form_field_static',
		options  => [qw(name label value off href values hidden_name hidden_value add_hidden)],
		label_en => 'Draws the static text in the place of the form input. Used to implement [temporary] read only fields. Invoked by draw_form.',
		label_ru => 'Отрисовывает статический текст на месте поля ввода. Изображает [временно] нередактируемое поле записи. Вызывается процедурой draw_form.',
		see_also => [qw(draw_form)]
	},

					#######################################

	{
		name     => 'draw_form_field_password',
		options  => [qw(name label value off size/120)],
		label_en => 'Draws the password form input. Invoked by draw_form.',
		label_ru => 'Отрисовывает поле ввода пароля. Вызывается процедурой draw_form.',
		see_also => [qw(draw_form)]
	},

					#######################################

	{
		name     => 'draw_form_field_text',
		options  => [qw(name label value off rows/25 cols/60)],
		label_en => 'Draws the textarea form input. Invoked by draw_form.',
		label_ru => 'Отрисовывает многострочное текстовое поле ввода. Вызывается процедурой draw_form.',
		see_also => [qw(draw_form)]
	},

					#######################################

	{
		name     => 'draw_form_field_hgroup',
		options  => [qw(items)],
		label_en => 'Draws the horizontal group of form inputs defined by "items" option. Invoked by draw_form.',
		label_ru => 'Отрисовывает строку полей ввода, описания которых заданы опцией "items". Вызывается процедурой draw_form.',
		see_also => [qw(draw_form)]
	},

					#######################################

	{
		name     => 'draw_form_field_file',
		options  => [qw(name label size)],
		label_en => 'Draws the file upload form input. Invoked by draw_form.',
		label_ru => 'Отрисовывает поле ввода для загрузки файла. Вызывается процедурой draw_form.',
		see_also => [qw(draw_form)]
	},

					#######################################

	{
		name     => 'draw_form_field_hidden',
		options  => [qw(name value off)],
		label_en => 'Draws the hidden form input. Invoked by draw_form.',
		label_ru => 'Отрисовывает скрытое поле ввода. Вызывается процедурой draw_form.',
		see_also => [qw(draw_form)]
	},

					#######################################

	{
		name     => 'draw_form_field_string',
		options  => [qw(name label value off size max_len/$$conf{max_len} picture)],
		label_en => 'Draws the text form input. Invoked by draw_form.',
		label_ru => 'Отрисовывает текстовое поле ввода. Вызывается процедурой draw_form.',
		see_also => [qw(draw_form)]
	},

					#######################################

	{
		name     => 'draw_form_field_date',
		options  => [qw(name label value off format/$$conf{format_dt} no_clear_button onClose max_len size/11_16 no_read_only)],
		label_en => 'The same as draw_form_field_datetime with no_time set to 1',
		label_ru => 'То же, что draw_form_field_datetime, но всегда без ввода времени',
		see_also => [qw(draw_form draw_form_field_datetime)]
	},

					#######################################

	{
		name     => 'draw_form_field_datetime',
		options  => [qw(name label value off format/$$conf{format_dt} no_time no_clear_button onClose max_len size/11_16 no_read_only)],
		label_en => 'Draws the calendar form input (DHTML from http://dynarch.com/mishoo/calendar.epl).',
		label_ru => 'Отрисовывает поле ввода типа "календарь" (DHTML-код позаимствован с http://dynarch.com/mishoo/calendar.epl).',
		see_also => [qw(draw_form)]
	},

					#######################################

	{
		name     => 'ids',
		options  => [qw(field/id)],
		syn      => <<EO,
	ids ([{id => 15}, {id => 110, label => 'foo'}]) == '-1,15,110';	
EO
		label_ru => 'Извлекает значения всех компонент id или иного указанного поля из данного списка хэшей. Результат всегда пригоден для подстановки в выражение IN (...).',
#		see_also => [qw(draw_toolbar)]
	},

					#######################################

	{
		name     => 'draw_toolbar_input_text',
		options  => [qw(name label value size off keep_params)],
		syn      => <<EO,	
	draw_toolbar_input_text ({
		label  => 'Search',
		name   => 'q',
	}),
EO
		label_en => 'Draws the text input (usually, for quick search).',
		label_ru => 'Отрисовывает текстовое поле ввода на панели над таблицей (обычно для быстрого поиска).',
		see_also => [qw(draw_toolbar)]
	},
	
					#######################################

	{
		name     => 'peer_proxy',
#		options  => [qw(files)],
		syn      => <<EO,	
	peer_proxy (PORTAL, {
		type   => 'docstorage_file',
		id     => 75124,
		action => 'download',
	}),
EO
		label_ru => 'Запрос на peer-сервер с заданными параметрами. Ответ передаётся в STDOUT через буфер ограниченного объёма.',
		see_also => [qw(peer_query)]
	},

					#######################################

	{
		name     => 'peer_query',
		options  => [qw(files)],
		syn      => <<EO,	
	my \$data = peer_query (PORTAL, {
		__adendum  => 'Hello from localhost...',
	}),
EO
		label_ru => 'Запрос на peer-сервер, наследующий параметры текущего запроса. Ответ возвращается в виде Perl-скаляра, как правило, ссылки на хэш.',
		see_also => [qw(peer_get peer_proxy)]
	},

					#######################################

	{
		name     => 'peer_get',
		options  => [qw(files)],
		syn      => <<EO,	
	my \$data = peer_get (PORTAL, {
		__adendum  => 'Hello from localhost...',
	}),
EO
		label_ru => 'Запрос на peer-сервер для извлечения объекта данных. Отличается от peer_query тем, что передаёт обратно значение $_REQUEST {__read_only} и может использоваться при $_REQUEST {xls} (на удалённом сервере не инициируется поточный ответ)',
		see_also => [qw(peer_query)]
	},
					
					#######################################

	{
		name     => 'peer_execute',
		options  => [qw(files)],
		syn      => <<EO,	
	my \$data = peer_execute (PORTAL, {
		__adendum  => 'Hello from localhost...',
	}),
EO
		label_ru => 'Запрос на peer-сервер для изменения данных. Отличается от peer_query тем, что передаёт обратно значение $_REQUEST {error} и производит корректный redirect.',
		see_also => [qw(peer_query)]
	},

					#######################################

	{
		name     => 'draw_toolbar_input_datetime',
		options  => [qw(name label value size no_time format onClose attributes no_read_only no_clear_button)],
		syn      => <<EO,	
	draw_toolbar_input_datetime ({
		label  => 'С какой даты',
		name   => 'dt_from',
	}),
EO
		label_en => 'Draws the datetime input (usually, for quick filter).',
		label_ru => 'Отрисовывает календарик со временем на панели над таблицей (обычно для быстрого фильтра).',
		see_also => [qw(draw_toolbar draw_toolbar_input_date)]
	},

					#######################################

	{
		name     => 'draw_toolbar_input_date',
		options  => [qw(name label value size format onClose attributes no_read_only no_clear_button)],
		syn      => <<EO,	
	draw_toolbar_input_datetime ({
		label  => 'С какой даты',
		name   => 'dt_from',
	}),
EO
		label_en => 'Draws the datetime input (usually, for quick filter).',
		label_ru => 'Отрисовывает календарик для выбора даты на панели над таблицей (обычно для быстрого фильтра).',
		see_also => [qw(draw_toolbar draw_toolbar_input_datetime)]
	},

					#######################################

	{
		name     => 'draw_toolbar_input_select',
		options  => [qw(name values value empty max_len onChange)],
		syn      => <<EO,	
	draw_toolbar_input_select ({
		name   => 'id_topic',
		values => \$data -> {topics},
		empty  => '[All topics]',
	}),						
EO
		label_en => 'Draws the drop-down input (usually, for quick filter).',
		label_ru => 'Отрисовывает выпадающий список на панели над таблицей (обычно для быстрого фильтра).',
		see_also => [qw(draw_toolbar)]
	},

					#######################################

	{
		name     => 'draw_toolbar_input_checkbox',
		options  => [qw(name label checked)],
		syn      => <<EO,	
	draw_toolbar_input_checkbox ({
		name   => 'show_hidden',
		label  => 'Show hidden items',
	}),						
EO
		label_en => 'Draws the checkbox input (usually, for quick filter).',
		label_ru => 'Отрисовывает поле для галочки на панели над таблицей (обычно для быстрого фильтра).',
		see_also => [qw(draw_toolbar)]
	},

					#######################################

	{
		name     => 'draw_toolbar_input_submit',
		options  => [qw(name label off)],
		syn      => <<EO,	
	draw_toolbar_input_submit ({
		label  => 'Refresh',
	}),						
EO
		label_en => 'Draws the submit button (usually, for top toolbars with many quick filters).',
		label_ru => 'Отрисовывает submit-кнопку (для верхней панели со множеством быстрых фильтров).',
		see_also => [qw(draw_toolbar)]
	},

					#######################################

	{
		name     => 'draw_toolbar_pager',
		options  => [qw(cnt total portion/$$conf{portion})],
		syn      => <<EO,	
	draw_toolbar_pager ({
		cnt     => 0 + @{$data -> {list}},
		total   => \$data -> {cnt},
		portion => \$data -> {portion},
	})
EO
		label_en => 'Draws the table navigation pager.',
		label_ru => 'Отрисовывает элемент листания таблицы.',
		see_also => [qw(draw_toolbar)]
	},

					#######################################

	{
		name     => 'draw_hr',
		options  => [qw(height/1 class/bgr8)],
		syn      => 'draw_hr (height => 10, class => "bgr0")',
		label_en => 'Draws a vertical spacer (mostly inter-table divider).',
		label_ru => 'Отрисовывает пустой межтабличный разделитель заданной высоты.',
	},


					#######################################

	{
		name     => 'draw_toolbar',
		options  => [qw(off target/invisible keep_params)],
		syn      => <<EO,	
	draw_toolbar ([
	
		{
			off => \$_REQUEST {__read_only},
			keep_params => ['type', 'select'],
		},
		
		{
			icon => 'create',
			label => 'Create',
			href => "/?type=my_objects&action=create",
		},

		{
			type   => 'input_text'
			label  => 'Search',
			keep_params => [],
			name   => 'q',
		},
		
		{
			type    => 'pager',
			cnt     => 0 + @{$data -> {list}},
			total   => \$data -> {cnt},
			portion => \$data -> {portion},
		},
		
	])
EO
		label_en => 'Draws the toolbar on top of the table.',
		label_ru => 'Отрисовывает панель с кнопками поверх таблицы.',
		see_also => [qw(draw_toolbar_button draw_toolbar_input_text draw_toolbar_input_select draw_toolbar_pager)]
	},

					#######################################

	{
		name     => 'draw_toolbar_button',
		options  => [qw(label href target/_self confirm off keep_esc)],
		syn      => <<EO,	
	draw_toolbar_button ({
		icon => 'create',
		label => 'Create',
		href => "?type=my_objects&action=create",
	})
EO
		label_en => 'Draws a button on the toolbar on top of the table.',
		label_ru => 'Отрисовывает кнопку на панели поверх таблицы.',
		see_also => [qw(draw_toolbar)]
	},



					#######################################

	{
		name     => 'draw_window_title',
		options  => [qw(label off)],
		syn      => <<EO,	
	draw_window_title ({
		label => "My Fancy Window",
		off   => \$data -> {no_crap},
	})
EO
		label_en => 'Draws the window title.',
		label_ru => 'Отрисовывает заголовок окна.',
	},
	
					#######################################

	{
		name     => 'draw_path',
		options  => [qw(max_len multiline id_param/id)],
		see_also => [qw(sql_select_path)],
		syn      => <<EO,	
	draw_path ([
		{type => rubrics,  name => 'Contents'},
		{type => rubrics,  name => 'Rubric1',    id => 1,  id_param => 'id_rubric'},
		{type => rubrics,  name => 'Rubric2',    id => 2,  id_param => 'id_rubric'},
		{type => articles, name => 'My Article', id => 10},
	])
EO
		label_en => 'Draws the object path (like "Contents/Rubric1/Rubric2/My Article").',
		label_ru => 'Отрисовывает путь к объекту (например, "Contents/Rubric1/Rubric2/My Article").',
	},

					#######################################

	{
		name     => 'draw_text_cells',
		syn      => <<EO,	
	draw_text_cells ({href => "/?type=foo&action=bar"}, [
			'foo',
			'bar',
			{
				label   => "100000000",
				picture => '\$ ### ### ###',
			}
		])
EO
		label_en => 'Draws the series of text cells with common options.',
		label_ru => 'Отрисовывает последовательность текстовых клеток с общими опциями.',
		see_also => [qw(draw_table draw_text_cell)]
	},
					
					#######################################

	{
		name     => 'draw_logon_form',
		syn      => <<EO,	
	draw_logon_form ()
EO
		label_ru => 'Отрисовывает форму авторизации для заглавной страницы приложения',
	},

					#######################################
					
	{
		name     => 'draw_cells',
		options  => [qw(href bgcolor)],
		syn      => <<EO,	
	draw_cells ({href => "/?type=foo&action=bar"}, [
			{						# checkbox
				type => 'checkbox',
				name => "foo_$$i{id}",
			},
			'foo',						# text
			'bar',						# text
			{						# text
				label   => "100000000",
				picture => '\$ ### ### ###',
			},
			{						# input
				type => 'input',
				name => "price_$$i{id}",
				size => 6,
			},
			{						# button
				icon => 'edit',
				href => {"/?type=foo&id=$$i{id}"},
			},
		])
EO
		label_en => 'Draws the series of cells of different types.',
		label_ru => 'Отрисовывает последовательность текстовых клеток, кнопок или полей ввода',
		see_also => [qw(draw_table draw_text_cells draw_row_buttons draw_checkbox_cell draw_input_cell)]
	},

					#######################################

	{
		name     => 'draw_row_buttons',
		options  => [qw(off)],
		syn      => <<EO,	
	draw_row_buttons ({off => 0 + NEVER + EVER}, [
			{
				label   => "[Edit]",
				icon    => "edit",
				href    => "/?type=items&id=\$\$i{id}",
			},
			{
				label   => "[Delete]",
				icon    => "delete",
				href    => "/?type=items&action=delete&id=\$\$i{id}",
				confirm => "Are you sure?!",
			}
		])
EO
		label_en => 'Draws the series of row buttons.',
		label_ru => 'Отрисовывает последовательность кнопок в строке таблицы.',
		see_also => [qw(draw_table draw_row_button)]
	},


					#######################################

	{
		name     => 'draw_text_cell',
		options  => [qw(label max_len/$$conf{max_len} picture attributes off href target/invisible a_class/lnk4 is_total)],
		syn      => <<EO,	
	draw_text_cell ('foo')

	draw_text_cell ({
		label   => "100000000",
		picture => '\$ ### ### ###',
		href    => "/?type=foo&action=bar",
	})
EO
		label_en => 'Draws table cell containing an input field.',
		label_ru => 'Отрисовывает клетку таблицы с текстовым полем ввода.',
		see_also => [qw(draw_table draw_text_cells)]
	},

					#######################################

	{
		name     => 'draw_radio_cell',
		options  => [qw(name value/1 checked off title attributes)],
		syn      => <<EO,	

	draw_radio_cell ({
		name     => "item_number_17",
		checked  => \$REQUEST {id} == 17,
	})
EO
		label_en => 'Draws table cell containing a radio button.',
		label_ru => 'Отрисовывает клетку таблицы с радио-кнопкой.',
		see_also => [qw(draw_table)]
	},
					#######################################

	{
		name     => 'draw_embed_cell',
		options  => [qw(src src_type/audio/mpeg autostart/false height/45)],
		syn      => <<EO,	

	draw_embed_cell ({
		src => '/i/audio/0012.mp3',
	})
EO
		label_ru => 'Отрисовывает клетку таблицы с multimedia-файлом.',
		see_also => [qw(draw_table)]
	},


					#######################################

	{
		name     => 'draw_input_cell',
		options  => [qw(name label off/0 read_only/0 max_len/$$conf{max_len} size/30 attributes a_class/lnk4)],
		syn      => <<EO,	
	draw_input_cell ({
		name  => "_B5",
		label => \$i -> {B5},
	})
EO
		label_en => 'Draws table cell containing an input field.',
		label_ru => 'Отрисовывает клетку таблицы с текстовым полем ввода.',
		see_also => [qw(draw_table)]
	},

					#######################################

	{
		name     => 'draw_checkbox_cell',
		options  => [qw(name value/1 attributes checked)],
		syn      => <<EO,	
	draw_checkbox_cell ({
		name  => "_adding_\$\$i{id}",
	})
EO
		label_en => 'Draws table cell containing an input field.',
		label_ru => 'Отрисовывает клетку таблицы с текстовым полем ввода.',
		see_also => [qw(draw_table)]
	},











					#######################################

	{
		name     => 'draw_select_cell',
		options  => [qw(onChange rows)],
		syn      => <<EO,	
	draw_select_cell ({
		name   => "_adding_\$\$i{id}",
		values => [
			{id => 0, label => 'Off'},
			{id => 1, label => 'On'},
		]
	})
EO
		label_en => 'Draws table cell containing an input field.',
		label_ru => 'Отрисовывает клетку таблицы с текстовым полем ввода.',
		see_also => [qw(draw_table)]
	},












					#######################################

	{
		name     => 'draw_row_button',
		options  => [qw(label icon href target/invisible confirm off force_label)],
		syn      => <<EO,	
	draw_row_button ({
		label   => "[Delete]",
		icon    => "delete",
		href    => "/?type=items&action=delete&id=\$\$i{id}",
		confirm => "Are you sure?!",
	})
EO
		label_en => 'Draws a button in the table row.',
		label_ru => 'Отрисовывает кнопку в строке таблицы.',
		see_also => [qw(draw_table)]
	},

					#######################################

	{
		name     => 'draw_table',
		options  => [qw(off .. name type/$_REQUEST{type} action/add toolbar js_ok_escape)],
		syn      => <<EO,	
	draw_table (	
		
		['Name', 'Phone'],
		
		sub {
			draw_text_cell  ({ \$i -> {label} }),
			draw_input_cell ({ 
				name  => '_phone_' . \$i -> {id},
				label => \$i -> {phone},
			}),
		},
		
		[
			{id => 1, label => 'McFoo', phone => '001-01-01-001'},
			{id => 2, label => 'Dubar', phone => '0'},
		],
				
		{
			'..'    => 1,
			name    => 'form_phones',
			toolbar => draw_ok_esc_toolbar (),
			top_toolbar => [ {},
				fake_select (),
			],
		}		
	
	)
EO
		label_en => 'Draws the data table with the given headers, callback sub and data array. Data are passed to the callback sub through the global variable $i.',
		label_ru => 'Отрисовывает таблицу данных с заданными заголовками, callback-процедурой и массивом данных. Данные передаются в callback-процедуру через глобальную переменную $i.',
		see_also => [qw(draw_text_cells draw_text_cell draw_input_cell draw_checkbox_cell draw_row_button draw_row_buttons draw_table_header draw_embed_cell fake_select)]
	},

					#######################################


);

################################################################################

@params = (

	{
		name => 'type',
		label_en => 'Screen type for the current request. Determines (with id and action) what callbacks (e.g. "select_$type", "draw_item_of_$type", "do_$action_$type") are to be invoked.',
		label_ru => 'Текущий тип экрана. Определяет (совместно с id и action), какие подпрограммы (например, "select_$type", "draw_item_of_$type", "do_$action_$type") должны быть вызваны.',
		default => 'logon',
	},

	{
		name => 'action',
		label_en => 'Action name. If set, "validate_$action_$type" and "do_$action_$type" callbackcs are invoked, then the user is redirected to the URL with an empty action.',
		label_ru => 'Имя действия. Если задан, то вызываются подапрограммы "validate_$action_$type" и "do_$action_$type", после чего пользователь перенаправляется на URL с пустым action',
	},

	{
		name => '__include_js',
		label_en => 'ARRAYREF of names of custom javaScript files located in application_root/doc_root/i/.',
		label_ru => 'Ссылка на список дополнительных javaScript-файлов, расположенных в директории  application_root/doc_root/i/.',
		default => '[\'js\']',
	},

	{
		name => '__include_css',
		label_en => 'ARRAYREF of names of custom CSS files located in application_root/doc_root/i/.',
		label_ru => 'Ссылка на список дополнительных CSS-файлов, расположенных в директории  application_root/doc_root/i/.',
	},

	{
		name => 'keepalive',
		label_en => 'If set, extends the lifetime for the session which number is his value. Internal paramerter, not to be used in application developpment.',
		label_ru => 'Если задан, то продлевает время жизни сессии, чей номер совпадает с его значением. Внутренний параметр, не должен использоваться напрямую.',
	},

	{
		name => 'sid',
		label_en => 'Session ID. If set, determines the current session => current user, otherwise the client is redirecred to the logon screen (type=logon).',
		label_ru => 'Если задан, то определяет ID сессии => текущего пользователя, в противном случае клиент перенаправляется на входную форму (type=logon).',
	},

	{
		name => 'salt',
		label_en => 'Fake parameter with random values. Used for preventing browser from using local HTML cache.',
		label_ru => 'Фиктивный параметр со случайными значениями. Используется для предотвращения кэширования HTML на стороне клиента.',
	},

	{
		name => '_frame',
		label_en => 'Reserved for browsers not suppotring IFRAME tag.',
		label_ru => 'Зарезервировано для браузеров без поддержки тега IFRAME.',
	},

	{
		name => 'error',
		label_en => 'Error message text. Must not be set directly, it\'s calulated from "validate_$action_$type" return value.',
		label_ru => 'Текст сообщения об ошибке. Не должен задаваться явно, так как вычисляется на основе значения, возвращаемого подпрограммой "validate_$action_$type".',
	},

	{
		name => '__response_sent',
		label_en => 'If set, no "draw_$type" or "draw_item_of_$type" sub is called and no HTML is sent to the client.',
		label_ru => 'Если задан, то процедура "draw_$type" или "draw_item_of_$type" не вызывается и сгенерированный HTML не пересылается клиенту.',
	},

	{
		name => 'redirect_params',
		label_en => 'Set this parameter to Data::Dumper($some_hashref) if you want to restore %$some_hashref as %_REQUEST after the next logon. Normally must appear only at logon screen as a hidden input.',
		label_ru => 'Установите значение этого параметра в Data::Dumper($some_hashref), если хотите, чтобы %$some_hashref был восстановлен как %_REQUEST после следующего входа в систему. В норме должен присутствовать только на ворме входа в виде скрытого поля ввода.',
	},

	{
		name => 'id',
		label_en => 'If set, "get_item_of_$type" and "draw_item_of_$type" will be called instead of "select_$type" and "draw_$type".',
		label_ru => 'Если установлен, то "get_item_of_$type" и "draw_item_of_$type" будут вызваны вместо "select_$type" and "draw_$type".',
	},

	{
		name => 'dbf',
		label_en => 'Obsoleted by __response_sent.',
		label_ru => 'Атавизм. Следует использовать __response_sent.'
	},

	{
		name => 'xls',
		label_en => 'If set, the table with lpt attribute set to 1 is cropped from the output and sent to the client as an Excel worksheet.',
		label_ru => 'Если установлен, то из HTML страницы вызезается таблица с атрибутом lpt=1 и возвращается на клиент в виде рабочего листа Excel.'
	},

	{
		name => 'lpt',
		label_en => 'If set, the table with lpt attribute set to 1 is cropped from the output and sent to the client in the printer friendly form.',
		label_ru => 'Если установлен, то из HTML страницы вызезается таблица с атрибутом lpt=1 и возвращается на клиент в виде, пригодном для распечатки.'
	},
	
	{
		name => 'role',
		label_en => 'Current role ID. Used in multirole alpplications only.',
		label_ru => 'ID текущей роли. Имеет смысл только в приложениях, где один пользователь может работать в нескольких ролях.'
	},

	{
		name => 'order',
		label_en => 'Name of the sort column. Set in hrefs produced by headers sub, used in SQL generated by order sub.',
		label_ru => 'Имя столбца, по которому производится сортировка. Устанавливается в ссылках, сгенерироанных headers, используется в SQL, сгенерированном order.',
	},
	
	{
		name => 'desc',
		label_en => 'If true, the sort order is descending. Set in hrefs produced by headers sub, used in SQL generated by order sub.',
		label_ru => 'Если истина, то порядок сортировки обратный. Устанавливается в ссылках, сгенерироанных headers, используется в SQL, сгенерированном order.',
	},

	{
		name => '__content_type',
		label_en => 'MIME type of the HTTP responce sent to the client.',
		label_ru => 'MIME-тип HTTP-ответа',
		default => 'text/html; charset=windows-1251',
	},
	
	{
		name => 'period',
		label_en => 'Always tranferred by <a href=../check_href.html>check_href</a> sub. Reserved for calendar-like applications.',
		label_ru => 'Всегда передаётся по ссылкам через check_href. Зарезервировано для календарных приложений.',
	},
	
	{
		name => '__read_only',
		label_en => 'If true, all input fields are disabled.',
		label_ru => 'Если истина, все поля ввода превращаются в надписи.',
	},

	{
		name => '__pack',
		label_en => 'If true, the browser window is packed around the main form/table. Used in popup windows.',
		label_ru => 'Если истина, окно браузера сжимается до минимума, охватывающего страницу. Используется во всплывающих окнах.',
	},
	
	{
		name => '__popup',
		label_en => 'If true, set all of __read_only, __pack and __no_navigation to true.',
		label_ru => 'Если истина, то истинны также __read_only, __pack и __no_navigation.',
	},

	{
		name => '__no_navigation',
		label_en => 'If true, no top navigation bar (user name/calendar/logout) is shown. Used in popup windows.',
		label_ru => 'Если истина, то не показывается верняя панель навигации (пользователь/календарь/выход). Используется во всплывающих окнах.',
	},

	{
		name => '_xml',
		label_en => 'If set, is surrounded with XML tags and placed in HEAD section. Used for MS Office 2000 HTML emulation.',
		label_ru => 'Если непуст, то окружается тегами XML и помещается в раздел HEAD. Используется для эмуляции MS Office 2000 HTML.',
	},

	{
		name => '__scrollable_table_row',
		label_en => 'Numer of table row highlighted by the slider at page load.',
		label_ru => 'Номер строки таблицы, на которой располагается слайдер при загрузке страницы.',
		default => '0',
	},

	{
		name => '__meta_refresh',
		label_en => 'The value for &lt;META HTTP-EQUIV=Refresh ... &gt; tag.',
		label_ru => 'Значение для тега &lt;META HTTP-EQUIV=Refresh ... &gt;.',
	},
	
	{
		name => '__focused_input',
		label_en => 'The NAME of the input to be focused at page load. Unless set, the first text inpyt is focused.',
		label_ru => 'Значение атрибута NAME поля ввода, на котором должен стоять фокус ввода при загрузке страницы. Если не установлен, фокусируется первое текстовое поле.',
	},

	{
		name => '__blur_all',
		label_en => 'If true, no input is focused.',
		label_ru => 'Если установлен, ни одно поле ввода не имеет фокуса.',
	},

	{
		name => '__help_url',
		label_en => 'URL to be activated on F1 press or [Help] link.',
		label_ru => 'URL, активизируемый при нажатии на F1 или ссылку [Справка].',
	},

	{
		name => '__path',
		label_en => 'Set internally by <a href=../draw_path.html>draw_path</a> for implement \'..\' facility in <a href=../draw_table.html>draw_table</a>.',
		label_ru => 'Устанавливается внутри draw_path, чтобы реализовать опцию \'..\' в draw_table.',
	},

	{
		name => '__toolbars_number',
		label_en => 'Set internally by <a href=../draw_toolbar.html>draw_toolbar</a> for proper toolbar indexing.',
		label_ru => 'Устанавливается внутри draw_toolbar для индексации панелей управления.',
	},
	
	{
		name => 'start',
		label_en => 'Number of first displayed record in multipage recordsets.',
		label_ru => 'Номер первой записи выборки, показываемой на странице (при наличии нарезки).',
	},

);

our @conf = (

	{
		name     => 'classic_menu_style',
		label_ru => "Если истина, то Skins::Classic отрисовывает меню в 'старом' стиле: раскрытие не onhover, а onclick",
	},

	{
		name     => 'precision',
		label_ru => "Точность при переводе чисел в объекты Math::FixedPrecision",
	},

	{
		name     => '_charset',
		label_en => "Default charset for public sites (pub_handler)",
		label_ru => "Кодировка по умолчанию для публичных сайтов (pub_handler)",
	},

	{
		name     => 'lang',
		label_en => "Default language name according to NISO Z39.53",
		label_ru => "Название языка по умолчанию в соответствии с NISO Z39.53",
	},

	{
		name => 'page_title',
		label_en => 'HTML page title',
		label_ru => 'Содержимое тега TITLE результирующей HTML-страницы',
	},

	{
		name => 'top_banner',
		label_en => 'Verbatim HTML area between top navigation toolbar and the main area.',
		label_ru => 'Фрагмент HTML, вставляемый между верхней навигационной панелью и основной частью страницы.',
	},
	
	{
		name => 'kb_options_focus',
		label_en => 'Ctrl & Alt options for focus shortcuts',
		label_ru => 'Опции ctrl и alt для клавиатурных ускорителей, перемещающих фокус ввода.',
		default => '$conf -> {kb_options_buttons}',
		see_also => [qw(kb_options_buttons)],
	},
	
	{
		name => 'kb_options_buttons',
		label_en => 'Ctrl & Alt options for buttons shortcuts',
		label_ru => 'Опции ctrl и alt для клавиатурных ускорителей кнопок.',
		default => '{ctrl => 1, alt => 1}',
		see_also => [qw(kb_options_focus kb_options_menu)],
	},
	
	{
		name => 'kb_options_menu',
		label_en => 'Ctrl & Alt options for main menu shortcuts',
		label_ru => 'Опции ctrl и alt для клавиатурных ускорителей главного меню.',
		default => '{ctrl => 1, alt => 1}',
		see_also => [qw(kb_options_focus kb_options_buttons)],
	},

	{
		name => 'max_len',
		label_en => 'Default length limit for dispayed strings',
		label_ru => 'Ограниение по умолчанию для отображаемых строк.',
		default => '30',
#		see_also => [qw(kb_options_focus kb_options_buttons)],
	},

	{
		name => 'format_d',
		label_en => 'Default date format for calendar input field',
		label_ru => 'Формат даты по умолчанию для поля ввода типа "календарь"',
		default => '%d.%m.%Y',
		see_also => [qw(format_dt)],
	},

	{
		name => 'number_format',
		label_en => 'Number::Format options',
		label_ru => 'Опции для объекта Number::Format. Желательно устнавливать -thousands_sep и -decimal_point.',
		see_also => [qw(format_dt)],
	},

	{
		name => 'format_dt',
		label_en => 'Default date format for calendar input field',
		label_ru => 'Формат даты/времени по умолчанию для поля ввода типа "календарь"',
		default => '%d.%m.%Y %k:%M',
		see_also => [qw(format_d)],
	},

	{
		name => 'portion',
		label_en => 'Default page size for long lists',
		label_ru => 'Умолчательое количество строк выборки на странице',
		default => '15',
	},

	{
		name => 'session_timeout',
		label_en => 'User session timeout, in minutes',
		label_ru => 'Время жизни сессии, мин.',
	},

	{
		name => 'i18n',
		label_en => 'i18n dictionary',
		label_ru => 'Словарь для многоязычного интерфейса',
	},

	{
		name => 'button_presets',
		label_en => 'standard buttons dictionary',
		label_ru => 'Словарь стандартных кнопок',
	},

	{
		name => 'size',
		label_en => 'Default value for input sizes',
		label_ru => 'Значение по умолчанию для размера полей ввода',
	},

	{
		name => 'use_cgi',
		label_en => 'If true, then CGI.pm is used instead of mod_perl interface',
		label_ru => 'Если истина, то вместо родного интерфейса mod_perl используется CGI.pm.',
	},

	{
		name => 'core_sweep_spaces',
		label_en => 'If true, then unnecessary spaces are sweeped off the resulting HTML.',
		label_ru => 'Если истина, то из HTML страниц удаляются незначащие пробельные символы.',
	},

	{
		name => 'core_auto_esc',
		label_en => 'If true, then return URLs and \$REQUEST{__scrollable_table_row}s are saved and esc hrefs for all forms are autogenerated.',
		label_ru => 'Если истина, то для каждой ссылки из строки таблицы сохраняется обратный URL и номер выбранной строки (__scrollable_table_row), ссылки с кнопок [вернуться] при этом генерируются автоматически.',
	},

	{
		name => 'core_cache_html',
		label_en => 'If true, then resulting HTML is cached for public sites.',
		label_ru => 'Если истина, HTML страниц для публичных сайтов кэшируется.',
	},

	{
		name => 'core_multiple_roles',
		label_en => 'If true, multiple roles mode is enabled.',
		label_ru => 'Если истина, активизируется режим множественных ролей.',
	},

	{
		name => 'core_auto_edit',
		label_en => 'If true, "edit" button appears on ok_esc toolbar by default when $_REQUEST{__read_only} is on.',
		label_ru => 'Если истина, то на панели при форме редактирования при установленном $_REQUEST{__read_only} появляется кнопка "edit".',
	},

	{
		name => 'core_no_auth_toolbar',
		label_en => 'If true, the auth toolbar is hidden.',
		label_ru => 'Если истина, то панель авторизации не показывается.',
	},

	{
		name => 'core_hide_row_buttons',
		label_en => 'If 2, row buttons are hidden. If 1, row buttons are empty tds. If -1, no popup menus are shown.',
		label_ru => 'Если 2, то построчные кнопки не показываются. Если 1, то построчные показываются как пустые клетки. Если -1, то не показываются контекстные меню.',
	},

	{
		name => 'core_spy_modules',
		label_en => 'If true then application *.pm modules are checked for freshness for each request and is reloaded as needed.',
		label_ru => 'Если истина, то для *.pm-модулей отслеживается дата изменения и при необходимости производится подгрузка свежих версий.',
	},

	{
		name => 'core_show_icons',
		label_en => 'Shows buttons with icons, if present',
		label_ru => 'Показывать графические кнопки',
	},

	{
		name => 'core_recycle_ids',
		label_en => 'If true, fake records ids are recycled',
		label_ru => 'Если истина, то id, принадлежащие fake-записям, не пропускаются, а переиспользуются.',
	},

	{
		name => 'db_dsn',
		label_en => 'DBI DSN. Better set it in $preconf!',
		label_ru => 'Строка соединения БД. Желательно задавать не в $conf, а в $preconf',
		see_also => [qw(db_user db_password)],
	},

	{
		name => 'db_user',
		label_en => 'DBI user. Better set it in $preconf!',
		label_ru => 'Имя пользователя БД. Желательно задавать не в $conf, а в $preconf',
		see_also => [qw(db_dsn db_password)],
	},

	{
		name => 'db_password',
		label_en => 'DBI password. Better set it in $preconf!',
		label_ru => 'Пароль пользователя БД. Желательно задавать не в $conf, а в $preconf',
		see_also => [qw(db_dsn db_user)],
	},

	{
		name => 'db_temporality',
		label_en => 'List of temporal tables or 1 if all tables are meant to be temporal.',
		label_ru => 'Список темпоральных таблиц или 1, если все таблицы темпоральные.',
	},

	{
		name => 'core_keep_textarea',
		label_en => 'If true, "text" field are shown as &lt;textarea readonly=1&gt; when $_REQUEST {__read_only}.',
		label_ru => 'Если истина, text-поля в $_REQUEST {__read_only}-режиме показываются не как static, а как &lt;textarea readonly=1&gt;.',
	},
	{
		name => 'exit_url',
		label_ru => 'Адрес, используемый для выхода из приложения. Эту опцию имеет смысл использовать для Eludia-приложений, встроенных в публичные сайты.',
	},
	{
		name => 'peer_roles',
		label_ru => 'Хэш peer-серверов для данного экземпляра приложения: ключи -- имена серверов, значения -- хэши "тамошняя роль -- здешняя роль". Здешняя роль для тамошней роли "" используется по умолчанию.',
	},

);

our @preconf = (

	{
		name => 'core_show_dump',
		label_ru => 'Если истина, то в главном меню всех пользователей присутствуют пункты Dump и Proto. Используется при отладке.',
	},
	{
		name => 'core_no_xml',
		label_ru => 'Если истина, то выдача содержимого в виде XML блокирована.',
	},
	{
		name => 'core_no_morons',
		label_ru => 'Если истина, то функция window.open не шифруется.',
	},
	{
		name => 'peer_servers',
		label_ru => 'Хэш peer-серверов для данного экземпляра приложения: ключи -- имена серверов, значения -- URL.',
	},
	{
		name => 'mail',
		label_ru => 'Адрес электронной почты, на который будут отсылаться ВСЕ сообщения с данного экземпляра приложения. Используется при отладке.',
	},
	{
		name => 'subset',
		label_ru => 'Подмножество текущего приложения. Значению этой опции должен соответствовать по имени файл Model/Subsets/$subset.txt.',
	},
	{
		name => 'no_model_update',
		label_ru => 'Если истина, то автообновление объектов БД отключено. Использовать в случае проблем с DBD-драйвером.',
	},
	{
		name => 'core_keep_textarea',
		label_en => 'If true, "text" field are shown as &lt;textarea readonly=1&gt; when $_REQUEST {__read_only}.',
		label_ru => 'Если истина, text-поля в $_REQUEST {__read_only}-режиме показываются не как static, а как &lt;textarea readonly=1&gt;.',
	},

	{
		name => 'core_no_log_mac',
		label_en => 'If true, MACs are not logged.',
		label_ru => 'Если истина, то MAC-адреса не пишутся в log.',
	},

	{
		name => 'core_hide_row_buttons',
		label_en => 'If 2, row buttons are hidden. If 1, row buttons are empty tds. If -1, no popup menus are shown.',
		label_ru => 'Если 2, то построчные кнопки не показываются. Если 1, то построчные показываются как пустые клетки. Если -1, то не показываются контекстные меню.',
	},

	{
		name => 'use_cgi',
		label_en => 'If true, then CGI.pm is used instead of mod_perl interface',
		label_ru => 'Если истина, то вместо родного интерфейса mod_perl используется CGI.pm.',
	},

	{
		name => 'core_auth_cookie',
		label_en => 'If set, then cookie authorization mode is on. The value is used as -expires parameter',
		label_ru => 'Если непусто, то включён режим cookie-авторизации. Значение параметра используется в качестве -expires.',
	},

	{
		name => 'core_debug_profiling',
		label_en => 'If true, all callback subs are profiled',
		label_ru => 'Если истина, то включён режим профилирования. В STDERR (1) или в БД (2) пишется время исполнения каждой callback-поцедуры',
	},

	{
		name => 'core_gzip',
		label_en => 'If true, use gzip transfer encoding when possible',
		label_ru => 'Если истина, по возможности использовать кодировку gzip.',
	},

	{
		name => 'core_spy_modules',
		label_en => 'If true then application *.pm modules are checked for freshness for each request and is reloaded as needed.',
		label_ru => 'Если истина, то для *.pm-модулей отслеживается дата изменения и при необходимости производится подгрузка свежих версий.',
	},

	{
		name => 'core_multiple_roles',
		label_en => 'If true then multiple simultaneous sessions with different roles per one user are allowed.',
		label_ru => 'Если истина, то один пользователь может одновременно поддерживать несколько сессий с разными ролями.',
	},

	{
		name => 'db_dsn',
		label_en => 'DBI DSN',
		label_ru => 'Строка соединения БД',
		see_also => [qw(db_user db_password)],
	},

	{
		name => 'db_user',
		label_en => 'DBI user',
		label_ru => 'Имя пользователя БД',
		see_also => [qw(db_dsn db_password)],
	},

	{
		name => 'db_password',
		label_en => 'DBI password',
		label_ru => 'Пароль пользователя БД',
		see_also => [qw(db_dsn db_user)],
	},

);

################################################################################

%i18n = (
	NAME => {
		en => 'NAME',
		ru => 'НАЗВАНИЕ',
	},
	SYNOPSIS => {
		en => 'SYNOPSIS',
		ru => 'ИСПОЛЬЗОВАНИЕ',
	},
	DESCRIPTION => {
		en => 'DESCRIPTION',
		ru => 'ОПИСАНИЕ',
	},
	OPTIONS => {
		en => 'OPTIONS',
		ru => 'ОПЦИИ',
	},
	DEFAULT => {
		en => 'DEFAULT',
		ru => 'ПО УМОЛЧАНИЮ',
	},
	SEE_ALSO => {
		en => 'SEE ALSO',
		ru => 'СМ. ТАКЖЕ',
	},	
	DEFAULT => {
		en => 'DEFAULT VALUE',
		ru => 'ПО УМОЛЧАНИЮ',
	},	
	'API Reference' => {
		en => 'API Reference',
		ru => 'Подпрограммы',
	},
);

################################################################################

sub generate_param {

	my ($lang, $s) = @_;		
	
	my $see_also = '';
	foreach my $sa (sort @{$s -> {see_also}}) {
		$see_also .= qq{<li><a href="$sa.html">$sa</a>};
	}
	
	$see_also and $see_also = <<EOF;
					<dt>${$i18n{SEE_ALSO}}{$lang}
					<dd><ul>$see_also</ul>
EOF
		
	open (F, ">$lang/params/$$s{name}.html");
	print F <<EOF;
		<HTML>
			<HEAD>
				<TITLE>Eludia.pm documentation: parameter $$s{name}</TITLE>
				<meta http-equiv="Content-Type" content="text/html; charset=$$charset{$lang}" />
				<link rel="STYLESHEET" href="../../css/z.css" type="text/css">
			</HEAD>
			<BODY>
				<dl>
					<dt>${$i18n{NAME}}{$lang}
					<dd>\$_REQUEST {$$s{name}}
					
					@{[ $$s{default} ? <<EOD : '' ]}
						<dt>${$i18n{DEFAULT}}{$lang}
						<pre>$$s{default}</pre>
EOD

					<dt>${$i18n{DESCRIPTION}}{$lang}
					<dd>$$s{"label_$lang"}
					
					$see_also

				</dl>
			</BODY>
		</HTML>
EOF

	close (F);

}

################################################################################

sub generate_conf {

	my ($lang, $s) = @_;		
	
	my $see_also = '';
	foreach my $sa (sort @{$s -> {see_also}}) {
		$see_also .= qq{<li><a href="$sa.html">$sa</a>};
	}
	
	$see_also and $see_also = <<EOF;
					<dt>${$i18n{SEE_ALSO}}{$lang}
					<dd><ul>$see_also</ul>
EOF
		
	open (F, ">$lang/conf/$$s{name}.html");
	print F <<EOF;
		<HTML>
			<HEAD>
				<TITLE>Eludia.pm documentation: \$conf option $$s{name}</TITLE>
				<meta http-equiv="Content-Type" content="text/html; charset=$$charset{$lang}" />
				<link rel="STYLESHEET" href="../../css/z.css" type="text/css">
			</HEAD>
			<BODY>
				<dl>
					<dt>${$i18n{NAME}}{$lang}
					<dd>\$conf -> {$$s{name}}
					
					@{[ $$s{default} ? <<EOD : '' ]}
						<dt>${$i18n{DEFAULT}}{$lang}
						<pre>$$s{default}</pre>
EOD

					<dt>${$i18n{DESCRIPTION}}{$lang}
					<dd>$$s{"label_$lang"}
					
					$see_also

				</dl>
			</BODY>
		</HTML>
EOF

	close (F);

}

################################################################################

sub generate_preconf {

	my ($lang, $s) = @_;		
	
	my $see_also = '';
	foreach my $sa (sort @{$s -> {see_also}}) {
		$see_also .= qq{<li><a href="$sa.html">$sa</a>};
	}
	
	$see_also and $see_also = <<EOF;
					<dt>${$i18n{SEE_ALSO}}{$lang}
					<dd><ul>$see_also</ul>
EOF
		
	open (F, ">$lang/preconf/$$s{name}.html");
	print F <<EOF;
		<HTML>
			<HEAD>
				<TITLE>Eludia.pm documentation: \$conf option $$s{name}</TITLE>
				<meta http-equiv="Content-Type" content="text/html; charset=$$charset{$lang}" />
				<link rel="STYLESHEET" href="../../css/z.css" type="text/css">
			</HEAD>
			<BODY>
				<dl>
					<dt>${$i18n{NAME}}{$lang}
					<dd>\$preconf -> {$$s{name}}
					
					@{[ $$s{default} ? <<EOD : '' ]}
						<dt>${$i18n{DEFAULT}}{$lang}
						<pre>$$s{default}</pre>
EOD

					<dt>${$i18n{DESCRIPTION}}{$lang}
					<dd>$$s{"label_$lang"}
					
					$see_also

				</dl>
			</BODY>
		</HTML>
EOF

	close (F);

}

################################################################################

sub generate_sub {

	my ($lang, $s) = @_;
	
	my %soptions = ();
	my %coptions = ();
	my %poptions = ();
	
	if ($lang eq 'en') {	
		
		my $body = '';
		eval '$body = $deparse -> coderef2text(\&Eludia::' . $s -> {name} . ')';	

		my @soptions = ($body =~ m{\$\$options\{\'(\w+)\'\}});
		%soptions = map {$_ => 1} @soptions;
		
		my @coptions = ($body =~ m{\$\$conf\{\'(\w+)\'\}});
		%coptions = map {$_ => 1} @coptions;
		map {delete $coptions {$_ -> {name}}} @conf;
		
		my @poptions = ($body =~ m{\$\$preconf\{\'(\w+)\'\}});
		%poptions = map {$_ => 1} @poptions;
		map {delete $poptions {$_ -> {name}}} @preconf;

	}

	my $options = '';
	foreach my $o (@{$s -> {options}}) {
		my ($name, $default) = split /\//, $o;
		$default ||= '&nbsp;';
		my ($o_def) = grep {$_ -> {name} eq $name} @options;
		$o_def or die "Option not defined: $name.\n";
		my $label = $o_def -> {"label_$lang"};
		$options .= qq{<tr bgcolor=white><td>$name<td>$label<td>$default};
		delete $soptions {$name};
	}
	
	if ($lang eq 'en') {	
		print STDERR join '', map {"Warning! undocumented option '$_' in sub '$$s{name}': \n"} sort keys %soptions;
		print STDERR join '', map {"Warning! undocumented \$conf option '$_' in sub '$$s{name}': \n"} sort keys %coptions;
		print STDERR join '', map {"Warning! undocumented \$preconf option '$_' in sub '$$s{name}': \n"} sort keys %poptions;
	}
	
	$options and $options = <<EOF;
					<dt>${$i18n{OPTIONS}}{$lang}
					<dd>
						<br>
						<table cellspacing=0 cellpadding=0><tr><td bgcolor=002000>
							<table cellspacing=1 cellpadding=5>
								<tr bgcolor=white><th>${$i18n{NAME}}{$lang}<th>${$i18n{DESCRIPTION}}{$lang}<th nowrap>${$i18n{DEFAULT}}{$lang}
								$options
							</table>
						</table>
EOF
	
	my $see_also = '';
	foreach my $sa (sort @{$s -> {see_also}}) {
		$see_also .= qq{<li><a href="$sa.html">$sa</a>};
	}
	
	$see_also and $see_also = <<EOF;
					<dt>${$i18n{SEE_ALSO}}{$lang}
					<dd><ul>$see_also</ul>
EOF
	
	
	open (F, ">$lang/$$s{name}.html");
	print F <<EOF;
		<HTML>
			<HEAD>
				<TITLE>Eludia.pm documentation: $$s{name}</TITLE>
				<meta http-equiv="Content-Type" content="text/html; charset=$$charset{$lang}" />
				<link rel="STYLESHEET" href="../css/z.css" type="text/css">
			</HEAD>
			<BODY>
				<dl>
					<dt>${$i18n{NAME}}{$lang}
					<dd>$$s{name}

					<dt>${$i18n{SYNOPSIS}}{$lang}
					<pre>$$s{syn}</pre>

					<dt>${$i18n{DESCRIPTION}}{$lang}
					<dd>$$s{"label_$lang"}
					
					$options
					$see_also

				</dl>
			</BODY>
		</HTML>
EOF

	close (F);

}

################################################################################

sub generate_left {
	
	my ($lang) = @_;
	
	my $subs = '';
	foreach my $s (sort {$a -> {name} cmp $b -> {name}} @subs) {
		my $class = $s -> {label_en} =~ /internal/i ? 'class=internal' : '';
		$subs .= qq{<a $class href="$$s{name}.html" target="main">$$s{name}</a><br>};
		generate_sub ($lang, $s);
	}
		
	my $params = '';
	foreach my $s (sort {$a -> {name} cmp $b -> {name}} @params) {
		$params .= qq{<a href="params/$$s{name}.html" target="main">$$s{name}</a><br>};
		generate_param ($lang, $s);
	}

	my $coptions = '';
	foreach my $s (sort {$a -> {name} cmp $b -> {name}} @conf) {
		$coptions .= qq{<a $class href="conf/$$s{name}.html" target="main">$$s{name}</a><br>};
		generate_conf ($lang, $s);
	}
		
	my $poptions = '';
	foreach my $s (sort {$a -> {name} cmp $b -> {name}} @preconf) {
		$poptions .= qq{<a $class href="preconf/$$s{name}.html" target="main">$$s{name}</a><br>};
		generate_preconf ($lang, $s);
	}

	open (F, ">$lang/left.html");
	print F <<EOF;
		<HTML>
			<HEAD>
				<TITLE>Eludia.pm documentation</TITLE>
				<meta http-equiv="Content-Type" content="text/html; charset=$$charset{$lang}" />
				<STYLE>
					body {
					    background: #FFFFFF;
					    font-family: Verdana, Arial, Helvetica, sans-serif;
					    font-weight: normal;
					    font-size: 11px;
    					};
					h1 {
					    font-family: Verdana, Arial, Helvetica, sans-serif;
					    font-weight: bold;
					    font-size: 12px;
    					};
					a:link, a:visited, a:active {
					    font-family: Verdana, Arial, Helvetica, sans-serif;
					    text-decoration: none;
					    color: #005050;
    					};
					a:hover {
					    font-family: Verdana, Arial, Helvetica, sans-serif;
					    text-decoration: underline;
					    color: #005050;
    					};
					a.internal:link, a.internal:visited, a.internal:active {
					    font-family: Verdana, Arial, Helvetica, sans-serif;
					    text-decoration: none;
					    color: #009090;
    					};
					a.internal:hover {
					    font-family: Verdana, Arial, Helvetica, sans-serif;
					    text-decoration: underline;
					    color: #009090;
    					};
				</STYLE>
			</HEAD>			
			<BODY>
				@{[ map { <<EO } @langs ]}
					<a href="../$_/index.html" target="_top">$_</a>
EO
				<h1>${$i18n{'API Reference'}}{$lang}</h1>
				$subs

				<h1>%_REQUEST</h1>
				$params				
				
				<h1>\$conf</h1>
				$coptions

				<h1>\$preconf</h1>
				$poptions
			</BODY>
		</HTML>
EOF
	close (F);
}

################################################################################

sub generate_index {
	my ($lang) = @_;
	open (F, ">$lang/index.html");
	print F <<EOF;
		<HTML>
			<HEAD>
				<TITLE>Eludia.pm documentation</TITLE>
				<meta http-equiv="Content-Type" content="text/html; charset=$$charset{$lang}" />
			</HEAD>
			<FRAMESET cols="300,*">
				<FRAME name="left" src="left.html" target="main">
				<FRAME name="main" src="about.html">
			</FRAMESET>
		</HTML>
EOF
	close (F);
}

################################################################################

sub generate_for_lang {
	my ($lang) = @_;
	mkdir $lang;
	mkdir "$lang/params";
	mkdir "$lang/conf";
	mkdir "$lang/preconf";
	generate_index ($lang);
	generate_left  ($lang);
}

################################################################################

sub subs_in ($) {
	my $package = shift;
	my @result = ();
	eval '@result = grep { defined *{$' . $package . '::{$_}}{CODE} } sort keys %' . $package . '::';
	return @result;
}

################################################################################

sub generate {
	map { generate_for_lang ($_) } @langs;
	mkdir 'css';
	open (F, ">css/z.css");
	print F <<EOF;
		body {
		    background: #FFFFFF;
    		};
		dt {
		    font-family: Verdana, Arial, Helvetica, sans-serif;
		    font-weight: bold;
		    font-size: 12pt;
		    margin-top: 10px;
    		};
		dd {
		    font-family: Verdana, Arial, Helvetica, sans-serif;
		    font-weight: normal;
		    font-size: 10pt;
		    margin-top: 5px;
    		};
		pre {
		    font-family: Courier New, Courier;
		    font-weight: normal;
		    font-size: 10pt;
		    color: #603060;
    		};
		th {
		    font-family: Verdana, Arial, Helvetica, sans-serif;
		    font-weight: bold;
		    font-size: 10pt;
    		};
		td {
		    font-family: Verdana, Arial, Helvetica, sans-serif;
		    font-weight: normal;
		    font-size: 10pt;
    		};
		a:link, a:visited, a:active {
		    font-family: Verdana, Arial, Helvetica, sans-serif;
		    text-decoration: none;
		    color: #005050;
    		};
		a:hover {
		    font-family: Verdana, Arial, Helvetica, sans-serif;
		    text-decoration: underline;
		    color: #005050;
    		};
EOF
	close (F);
	
	my @subs_in_eludia = subs_in 'Eludia';
	my %imported_subs = map {$_ => 1} ('OK', map {subs_in $_} qw(Data::Dumper URI::Escape HTTP::Date MIME::Base64 Time::HiRes));
	my %documented_subs = map {$_ -> {name} => 1} @subs;
	my @undocumented_subs = grep {!exists $imported_subs {$_} && !exists $documented_subs {$_} && !/__/} @subs_in_eludia;

	print STDERR join '', map {"Warning! undocumented sub '$_'\n"} @undocumented_subs;
		
}

################################################################################

sub generate_docbook_subs {

	no warnings;

	open O, ">api_docs.xml";

	print O <<EOX;
<?xml version="1.0" encoding="windows-1251"?>
<appendix id="api">
	<title>Процедуры API <productname>Eludia.pm</productname></title>
EOX


	foreach my $s (sort {$a -> {name} cmp $b -> {name}} @subs) {

		my %soptions = ();
		my %coptions = ();
		my %poptions = ();
		my %roptions = ();


		my $body = '';
		eval '$body = $deparse -> coderef2text(\&Eludia::' . $s -> {name} . ')';	

		my @soptions = ($body =~ m{\$\$options\{\'(\w+)\'\}});
		%soptions = map {$_ => 1} @soptions;

		my @coptions = ($body =~ m{\$\$conf\{\'(\w+)\'\}});
		%coptions = map {$_ => 1} @coptions;
		map {delete $coptions {$_ -> {name}}} @conf;

		my @poptions = ($body =~ m{\$\$preconf\{\'(\w+)\'\}});
		%poptions = map {$_ => 1} @poptions;
		map {delete $poptions {$_ -> {name}}} @preconf;

		my @roptions = ($body =~ m{\$_REQUEST\{\'(\w+)\'\}});
		%roptions = map {$_ => 1} @roptions;
		map {delete $roptions {$_ -> {name}}} @request;

		my $options = '';
		foreach my $o (@{$s -> {options}}) {
			my ($name, @default) = split /\//, $o;
			my $default = join '/', @default;
#			$default ||= '&nbsp;'; #!!!
			my ($o_def) = grep {$_ -> {name} eq $name} @options;
			$o_def or die "Option not defined: $name.\n";
			my $label = $o_def -> {"label_ru"};
			if ($default) {
				$label .= qq{, по умолчанию "$default"};
			}
			$options .= <<EOX;
	<varlistentry>
		<term><varname>$name</varname></term>
		<listitem><para>$label</para></listitem>
	</varlistentry>
EOX
			
			delete $soptions {$name};

		}

		print STDERR join '', map {"Warning! undocumented option '$_' in sub '$$s{name}': \n"} sort keys %soptions;
		print STDERR join '', map {"Warning! undocumented \$conf option '$_' in sub '$$s{name}': \n"} sort keys %coptions;
		print STDERR join '', map {"Warning! undocumented \$preconf option '$_' in sub '$$s{name}': \n"} sort keys %poptions;		
		print STDERR join '', map {"Warning! undocumented \$_REQUEST option '$_' in sub '$$s{name}': \n"} sort keys %roptions;

		$options and $options = <<EOX;
	<variablelist>
		<title>Опции</title>
		$options
	</variablelist>
EOX

		my $synopsis = $s -> {syn} ? <<EOX : '';
<synopsis>
<![CDATA[
$$s{syn}
]]>    
</synopsis>
EOX


		my $see_also = '';
		foreach my $sa (sort @{$s -> {see_also}}) {
			$see_also .= ', ' if $see_also;
			$see_also .= qq{<link linkend="api_sub_$sa"><varname>$sa</varname></link>};
		}

		$see_also and $see_also = <<EOX;
						<para>См. также: $see_also.</para>
EOX


		print O <<EOX;
	<section id="api_sub_$$s{name}">
		
		<title><varname>$$s{name}</varname></title>
		
		<para>
			$$s{"label_ru"}
		</para>	
		
$synopsis
		
		$options
		
		$see_also
		
	</section>

EOX

	}

	print O <<EOX;
</appendix>
EOX

	close O;

	open O, ">conf.xml";

	print O <<EOX;
<?xml version="1.0" encoding="windows-1251"?>
<appendix id="conf">
	<title>Опции конфигурации приложения (\$conf)</title>
	<variablelist>
EOX

	foreach (sort {$a -> {name} cmp $b -> {name}} @conf) {
		
		$$_{label_ru} =~ s{\.\s*$}{};
		
		print O <<EOX;
			<varlistentry>
				<term><varname>$$_{name}</varname></term>
				<listitem><para>$$_{label_ru}.</para></listitem>
			</varlistentry>
EOX
	}

	print O <<EOX;
	</variablelist>
</appendix>
EOX

	close O;
	open O, ">preconf.xml";

	print O <<EOX;
<?xml version="1.0" encoding="windows-1251"?>
<appendix id="preconf">
	<title>Опции конфигурации инсталляции (\$preconf)</title>
	<variablelist>
EOX

	foreach (sort {$a -> {name} cmp $b -> {name}} @preconf) {
		
		$$_{label_ru} =~ s{\.\s*$}{};
		
		print O <<EOX;
			<varlistentry>
				<term><varname>$$_{name}</varname></term>
				<listitem><para>$$_{label_ru}.</para></listitem>
			</varlistentry>
EOX
	}

	print O <<EOX;
	</variablelist>
</appendix>
EOX

	close O;
	open O, ">request.xml";

print O <<EOX;
<?xml version="1.0" encoding="windows-1251"?>
<appendix id="request">
	<title>Специальные параметры запросов (\%_REQUEST)</title>
	<variablelist>
EOX

	foreach (sort {$a -> {name} cmp $b -> {name}} @request) {
		
		$$_{label_ru} =~ s{\.\s*$}{};
		
		print O <<EOX;
			<varlistentry>
				<term><varname>$$_{name}</varname></term>
				<listitem><para>$$_{label_ru}.</para></listitem>
			</varlistentry>
EOX
	}

	print O <<EOX;
	</variablelist>
</appendix>
EOX

	my @subs_in_eludia = subs_in 'Eludia';
	my %imported_subs = map {$_ => 1} (qw (OK GET HEAD LOCK_EX LOCK_NB LOCK_SH LOCK_UN POST PUT MP2), map {subs_in $_} qw(Data::Dumper URI::Escape HTTP::Date MIME::Base64 Time::HiRes Storable File::Copy File::Find));
	my %internal_subs = map {$_ => 1} (qw (
		_adjust_row_cell_style
		draw_table_header_cell
		draw_table_header_row
		draw_table_row
		flix_encode_field
		flix_encode_record
		flix_mirror
		flix_reindex_record
		get_page
		get_skin_name
		is_off
		menu_subset
		peer_name
		peer_reconnect
		simple_svn_prompt
		sql_weave_model
		svn_status
		vld_noref
		svn_path
		select_subset
		is_recyclable
		assert_fake_key
		order_cells
	));
	my %documented_subs = map {$_ -> {name} => 1} @subs;
	my @undocumented_subs = grep {!/_DEFAULT$/ && !exists $imported_subs {$_} && !exists $internal_subs {$_} && !exists $documented_subs {$_} && !/__/} @subs_in_eludia;

	print STDERR join '', map {"Warning! undocumented sub '$_'\n"} @undocumented_subs;
	
}

1;
