
 /*
 * jQuery Browser Plugin 0.0.6
 * https://github.com/gabceb/jquery-browser-plugin
 *
 * Original jquery-browser code Copyright 2005, 2013 jQuery Foundation, Inc. and other contributors
 * http://jquery.org/license
 *
 * Modifications Copyright 2014 Gabriel Cebrian
 * https://github.com/gabceb
 *
 * Released under the MIT license
 *
 * Date: 30-03-2014
 */!function(a,b){"use strict";var c,d;if(a.uaMatch=function(a){a=a.toLowerCase();var b=/(opr)[\/]([\w.]+)/.exec(a)||/(chrome)[ \/]([\w.]+)/.exec(a)||/(version)[ \/]([\w.]+).*(safari)[ \/]([\w.]+)/.exec(a)||/(webkit)[ \/]([\w.]+)/.exec(a)||/(opera)(?:.*version|)[ \/]([\w.]+)/.exec(a)||/(msie) ([\w.]+)/.exec(a)||a.indexOf("trident")>=0&&/(rv)(?::| )([\w.]+)/.exec(a)||a.indexOf("compatible")<0&&/(mozilla)(?:.*? rv:([\w.]+)|)/.exec(a)||[],c=/(ipad)/.exec(a)||/(iphone)/.exec(a)||/(android)/.exec(a)||/(windows phone)/.exec(a)||/(win)/.exec(a)||/(mac)/.exec(a)||/(linux)/.exec(a)||/(cros)/i.exec(a)||[];return{browser:b[3]||b[1]||"",version:b[2]||"0",platform:c[0]||""}},c=a.uaMatch(b.navigator.userAgent),d={},c.browser&&(d[c.browser]=!0,d.version=c.version,d.versionNumber=parseInt(c.version)),c.platform&&(d[c.platform]=!0),(d.android||d.ipad||d.iphone||d["windows phone"])&&(d.mobile=!0),(d.cros||d.mac||d.linux||d.win)&&(d.desktop=!0),(d.chrome||d.opr||d.safari)&&(d.webkit=!0),d.rv){var e="msie";c.browser=e,d[e]=!0}if(d.opr){var f="opera";c.browser=f,d[f]=!0}if(d.safari&&d.android){var g="android";c.browser=g,d[g]=!0}d.name=c.browser,d.platform=c.platform,a.browser=d}(jQuery,window);

/*
	underscore js
*/
var _ = window.top._;

if (typeof _ === 'undefined') {
	$.ajax({
		url: '/i/mint/libs/underscore/underscore.js',
		async: false,
		dataType: 'script'
	})
}

$.fn.scrollTo = function(target, options, callback) {
  if(typeof options == 'function' && arguments.length == 2){ callback = options; options = target; }
  var settings = $.extend({
    scrollTarget  : target,
    offsetTop     : 50,
    duration      : 500,
    easing        : 'swing'
  }, options);
  return this.each(function(){
    var scrollPane = $(this);
    var scrollTarget = (typeof settings.scrollTarget == "number") ? settings.scrollTarget : $(settings.scrollTarget);
    var scrollY = (typeof scrollTarget == "number") ? scrollTarget : scrollTarget.offset().top + scrollPane.scrollTop() - parseInt(settings.offsetTop);
    scrollPane.animate({scrollTop : scrollY }, parseInt(settings.duration), settings.easing, function(){
      if (typeof callback == 'function') { callback.call(this); }
    });
  });
}

var select_options = {};
var browser_is_msie = $.browser.msie;
var is_dialog_blockui = $.browser.webkit || $.browser.safari;

var is_ua_mobile = /mobile|android/i.test (navigator.userAgent);
var dialog_width = is_ua_mobile  ? top.innerWidth - 20  : document.documentElement.clientWidth - 100;
var dialog_height = is_ua_mobile ? top.innerHeight - 100 : document.documentElement.clientHeight - 100;

if (!is_ua_mobile) {
	var ua = /Chrome\/(\d+)/.exec (navigator.userAgent);
	is_ua_mobile = ua && ua.length > 1 && ua [1] > 36;
}
is_ua_mobile = 1;


var is_dirty = false,
	scrollable_table_is_blocked = false,
	tableSlider,
	q_is_focused = false,
	is_interface_is_locked = false,
	left_right_blocked = false,
	lastClientHeight = 0,
	lastClientWidth = 0,
	lastKeyDownEvent = {},
	expanded_nodes = {},
	kb_hooks = [{}, {}, {}, {}],

	max_len = 50,
	poll_invisibles_interval_id,
	max_tabindex = 0,
	supertables = [];


var request = {},
	params = window.location.search.substr(1).split ('&');

for (var i = 0; i < params.length; i++ ) {
	var couple = params [i].split ('=');
	request [couple [0]] = couple [1];
}

var alert_window_is_open = false,
	confirm_window_is_open = false;

/*
	Options:
	title   - текст заголовка окна, def Ошибка
	icon    - путь к иконке, def: /i/_skins/Mint/alert.png
	ok_text - текст кнопки, def: OK
*/
window.__original_alert = window.alert;
window.alert = function(message, errorFieldName, options) {
	var w = window.name == 'invisible' ? parent : window.name == '_body_iframe' ? parent.parent : window,
		$field = errorFieldName ? w.$('[name="' + errorFieldName + '"') : null;

	if (errorFieldName && !$field.is(':visible')) $field = $field.parent();
	if (errorFieldName && $field.length !== 0) {
		$field.focus();

		var notification = w.$('#notification').data('kendoTooltip'),
			role = $field.attr('role'),
			showFor;

		if (notification) notification.hide();
		switch(role) {
			case 'dropdownlist':
				showFor = $field.closest('.k-widget.k-dropdown');
				break;
			case 'upload':
				showFor = $field.closest('.k-button.k-upload-button');
				break;
			case 'multiSelect':
				showFor = $field.closest('span');
				break;
			default:
				showFor = $field;
		}
		notification = w.$('#notification').kendoTooltip({
			position: 'bottom',
			autoHide: false,
			content: message
		}).data('kendoTooltip');
		notification.show(showFor);
		notification.popup.element.addClass('error');
	} else {
		try {
			var $ = w.$,
				kendo = w.kendo,
				$alertWindow = $('<div/>', { id: 'alert-window' }),
				K_alertWindow,
				maxWidth = Math.max(document.documentElement.clientWidth, window.innerWidth || 0) / 2,
				maxHeight = Math.max(document.documentElement.clientHeight, window.innerHeight || 0) / 2;

			if (!options) options = {};
			$('body').append($alertWindow);
			K_alertWindow = $alertWindow.kendoWindow({
				modal: true,
				title: options.title || 'Ошибка',
				resizable: false,
				draggable: false,
				minWidth: 400,
				maxWidth: maxWidth,
				maxHeight: maxHeight,
				open: function() {
					alert_window_is_open = true;
				},
				close: function() {
					setTimeout(function() { alert_window_is_open = false; }, 500);
					if (typeof options.on_close === 'function') options.on_close();
					this.destroy();
				}
			}).data('kendoWindow');
			K_alertWindow
				.content(kendo.template('<div>' +
						'<div class="icon"><img src="#= data.icon #" /></div>' +
							'<div class="viewport">' +
								'<div>' +
									'<div style="max-height: #= data.maxHeight #px">#= data.message #</div>' +
								'</div>' +
							'</div>' +
						'<div class="footer">' +
							'<a class="k-button">#= data.okText #</a>' +
						'</div>' +
					'</div>')({
						message: message,
						icon: options.icon || '/i/_skins/Mint/alert.png',
						maxHeight: maxHeight - 53,
						okText: options.ok_text || 'OK'
					})
				)
				.center()
				.open();
			$('.footer a', $alertWindow).click(function(e) {
				e.preventDefault();
				K_alertWindow.close()
			});
		} catch(e) {
			if (console && console.error) console.error(e);
			window.__original_alert(message);
		}
	}
	if (w.is_interface_is_locked) {
		w.$.unblockUI();
		w.is_interface_is_locked = false;
	}
	w.setCursor(top);
	w.setCursor(w);
};

window.warning = function(message) {
	window.alert(
		message,
		null,
		{
			title : 'Предупреждение',
			icon  : '/i/_skins/Mint/warning.png'
		}
	);
}

/*
	Options:
	title       - текст заголовка окна, def: Ошибка
	icon        - путь к иконке, def: /i/_skins/Mint/question.png
	ok_text     - текст кнопки, def: Да
	cancel_text - текст кнопки, def: Нет
*/
window.__original_confirm = window.confirm;
window.confirm = function(message, succesCallback, failCallback, options) {
	if (typeof succesCallback !== 'function') {
		var result = window.__original_confirm(message);
		window.setCursor(top);
		window.setCursor(window);
		return result;
	}
	if (!options) options = {};

	var $confirmWindow = $('<div/>', { id: 'confirm-window' }),
		maxWidth = Math.max(document.documentElement.clientWidth, window.innerWidth || 0) / 2,
		maxHeight = Math.max(document.documentElement.clientHeight, window.innerHeight || 0) / 2,
		K_confirmWindow = $confirmWindow.kendoWindow({
			modal: true,
			resizable: false,
			draggable: false,
			title: options.title || i18n.confirm,
			minWidth: 400,
			maxWidth: maxWidth,
			maxHeight: maxHeight,
			open: function() {
				confirm_window_is_open = true;
			},
			close: function() {
				setTimeout(function() { confirm_window_is_open = false; }, 500);
				if (is_interface_is_locked) {
					$.unblockUI();
					is_interface_is_locked = false
				}
				if (this.element.data('success') && succesCallback) succesCallback();
				if (!this.element.data('success') && failCallback) failCallback();
				setCursor(top);
				setCursor(window);
				this.destroy();
			}
		}).data('kendoWindow');

	K_confirmWindow
		.content(kendo.template('<div>' +
				'<div class="icon"><img src="#= data.icon #"/></div>' +
				'<div class="viewport">' +
					'<div>' +
						'<div style="max-height: #= data.maxHeight #px">#= data.message #</div>' +
					'</div>' +
				'</div>' +
				'<div class="footer">' +
					'<a class="k-button _ok">#= data.okText #</a>' +
					'<a class="k-button _cancel">#= data.cancelText #</a>' +
				'</div>' +
			'</div>')({
				message: message,
				icon: options.icon || '/i/_skins/Mint/question.png',
				maxHeight: maxHeight - 53,
				okText: options.ok_text || 'Да',
				cancelText: options.cancel_text || 'Нет'
			}))
		.center()
		.open();
	$confirmWindow.focus();
	confirm_window_is_open = true;
	$('.footer a', $confirmWindow).click(function(e) {
		e.preventDefault();

		var $this = $(this);

		if ($this.hasClass('_ok') && typeof succesCallback === 'function') $confirmWindow.data('success', true);
		if ($this.hasClass('_cancel') && typeof failCallback === 'function') $confirmWindow.data('success', false);
		K_confirmWindow.close();
	});
}

$(document).on('keyup', function(e) {
	var $alertWindow = $('#alert-window'),
		$confirmWindow = $('#confirm-window');

	$alertWindow = $alertWindow.length ? $alertWindow.data('kendoWindow') : null;
	$confirmWindow = $confirmWindow.length ? $confirmWindow.data('kendoWindow') : null;

	if (($alertWindow || $confirmWindow) && [13, 27, 32].indexOf(e.keyCode) !== -1) {
		e.preventDefault();
		if ($confirmWindow) $confirmWindow.element.data('success', e.keyCode !== 27);
		($alertWindow || $confirmWindow).close();
	}
});

function drop_form_tr_for_this_minus_icon (i) {

	$(i).parent ().parent ().remove ();

}

function clone_form_tr_for_this_plus_icon (i) {

	var tr_old = $(i).parent ().parent ();

	if (i.src.indexOf ('minus.gif') > -1) {

		tr_old.remove ();

		return;

	}

	var id = tr_old.attr ('id');

	var selector = "tr[id^='" + id + "']";

	var n = 0;

	var last = null;

	$(selector, tr_old.parent ()).each (function () {

		n ++;

		last = this;

	});

	var tr_new = tr_old.clone ();

	$('img', tr_new).each (function () {

		var oldId = this.id;

		this.id   += ('_' + n);

	});

	tr_new.attr ('id', id + '_' + n);

	var img = $('img:last', tr_new);

	img.attr ('src', img.attr ('src').replace ('plus', 'minus'));

	var td = $('td:first', tr_new);

	td.text (img.attr ('lowsrc') + ' ' + (parseInt (img.attr ('name')) + n) + ':');

	$(':input', tr_new).each (function () {

		this.id   += ('_' + n);
		this.name += ('_' + n);
		this.value = '';

	});

	tr_new.insertAfter (last);

}

function get_event (e) {

	return browser_is_msie ? window.event : e;

}


function dialog_open (options) {

	if (typeof (options) === 'number') {
		options = dialogs[options];
	}

	if (typeof options.off === 'function' ? options.off() : options.off)
		return;

	options.before = options.before || function (){};
	options.before();

	options.after = options.after || function (result){};

	options.href   = options.href.replace(/\#?\&_salt=[\d\.]+$/, '');
	options.href  += '&_salt=' + Math.random ();
	options.parent = window;

	if (options.fullscreen) {
		options.height = document.documentElement.clientHeight - 40;
		options.width = document.documentElement.clientWidth - 20;
		options.position =  {my: "left top", at: "left top", of: window};
	}

	var url = window.location.protocol + '//' + window.location.host + '/i/_skins/Mint/dialog.html?' + Math.random();

	if ($.browser.webkit || $.browser.safari)
		$.blockUI ({fadeIn: 0, message: '<h1>' + i18n.choose_open_vocabulary + '</h1>'});

	var getDialogSize = function(type, size) {
		return size
			? /^[\d]{1,2}%$/.test(size)
				? (function(size) {
					return window.top.document.documentElement[type === 'width' ? 'clientWidth' : 'clientHeight'] / 100 * size
				})(parseInt(size.replace('%', '')))
				: size
			: type === 'width' ? dialog_width : dialog_height
	}

	if (is_ua_mobile) {
		$.showModalDialog({
			url             : url,
			height          : getDialogSize('height', options.height),
			width           : getDialogSize('width', options.width),
			position        : options.position || undefined,
			resizable       : true,
			scrolling       : 'no',
			dialogArguments : options,
			onClose: function () {
				var result = this.returnValue || {result : 'esc'};
				$.unblockUI ();
				options.after(result);
			}
		});

		return;
	}


	var width  = options.width  || (screen.availWidth - (screen.availWidth <= 800 ? 50 : 100));
	var height = options.height || (screen.availHeight - (screen.availHeight <= 600 ? 50 : 100));

	var result = window.showModalDialog(url, options, options.options + ';dialogWidth=' + width + 'px;dialogHeight=' + height + 'px');
	result = result || {result : 'esc'};

	options.after(result);

	if ($.browser.webkit || $.browser.safari)
		$.unblockUI ();

	setCursor ();

	return result;

}

function close_multi_select_window (ret) {
	var w = window, i = 0;
	for (;i < 5 && w.name != '_modal_iframe'; i ++)
		w = w.parent;
	if (w.name == '_modal_iframe') {
		if (ret)
			w.returnValue = ret;
		w.parent.$('DIV.modal_div').dialog ('close');
	} else {
		if (ret)
			top.returnValue = ret;
		top.close ();
	}
}

function open_vocabulary_from_select(s, options) {

	var value = $(s).data('kendoDropDownList').value();

	if (is_dialog_blockui)
		$.blockUI ({fadeIn: 0, message: '<h1>' + options.message + '</h1>'});
	try {
		if (is_ua_mobile) {
			 $.showModalDialog({
				url             : window.location.protocol + '//' + window.location.host + '/i/_skins/Mint/dialog.html?' + Math.random(),
				height          : options.dialog_height
					? ( (document.documentElement.clientHeight <= options.dialog_height)
							? document.documentElement.clientHeight - 100
							: options.dialog_height )
					: dialog_height,
				width           : options.dialog_width
					? ( (document.documentElement.clientWidth  <= options.dialog_width)
							? ( (document.documentElement.clientWidth < 768) ? dialog_width : document.documentElement.clientWidth - 100 )
							: options.dialog_width )
					: dialog_width,
				resizable       : true,
				scrolling       : 'no',
				title_max_len   : options.title_max_len,
				dialogArguments : {href: options.href, parent: window, title: options.title},
				onClose: function () {
					var result = this.returnValue || {result: 'esc'},
						$s = $(s),
						kendo_select = $s.data("kendoDropDownList"),
						selected_item,
						widget,
						width;

					if (result.result == 'ok') {
						if (options.gridId) {
							var kGridRow = $('#grid_' + options.gridId).data('kendoGrid').dataSource.data()[options.rowIndex];

							if (_.isArray(kendo_grids[options.gridId].data.vocs[options.vocId])) {
								if (!_.find(kendo_grids[options.gridId].data.vocs[options.vocId], function(item) {
									item.id == result.id
								})) kendo_grids[options.gridId].data.vocs[options.vocId].push({
									id: result.id,
									label: result.label
								});
							} else {
								kendo_grids[options.gridId].data.vocs[options.vocId] = [{
									id: result.id,
									label: result.label
								}]
							}

							kGridRow.set(options.field, result.id);
						} else {
						setSelectOption(s, result.id, result.label);
						}
					} else {
						if (options.gridId) {
							if (value) {
								var kGridRow = $('#grid_' + options.gridId).data('kendoGrid').dataSource.data()[options.rowIndex];

								kGridRow.set(options.field, value);
							}
						} else {
							kendo_select.select($s.data('prev_value'));

							var selected_item = kendo_select.wrapper.find('span.k-input'),
								widget = kendo_select.wrapper,
								$parent = typeof widget.parent().attr('data-note') === 'undefined'
									? widget.parent()
									: widget.parent().parent(),
								widgetWrapperWidth = $parent.width(),
								width;

							widget.css({ width: 'auto' });
							width = selected_item.width() + 55;
							if (width > widgetWrapperWidth)
								width = widgetWrapperWidth;
							kendo_select.list.width('auto');
							widget.width(width);
							kendo_select.focus();
						}
					}
					if (is_dialog_blockui && (result.result == 'esc' || result.result == 'ok' && options.kind != 'toolbar_input_select'))
						$.unblockUI();
					if (!options.gridId)
					kendo_select.colorize_empty_value();
				}
			});
		} else {
			var result = window.showModalDialog (
				window.location.protocol + '//' + window.location.host + '/i/_skins/Mint/dialog.html?' + Math.random(),
				{href: options.href, parent: window, title: options.title},
				'status:no;resizable:yes;help:no;dialogWidth:' + options.dialog_width + 'px;dialogHeight:' + options.dialog_height + 'px'
			);

			window.focus ();
			if (result.result == 'ok') {
				setSelectOption (s, result.id, result.label);
			} else {
				var kendo_select = $(s).data('kendoDropDownList');

				kendo_select.select(0);
				kendo_select.close();
				kendo_select.focus ();
				$(s).trigger ('change');
			}
			if (is_dialog_blockui)
				$.unblockUI ();
		}
	} catch (e) {
		var kendo_select = $(s).data('kendoDropDownList');

		kendo_select.select(0);
		kendo_select.close();
		if (is_dialog_blockui)
			$.unblockUI ();
	}
}

function open_vocabulary_from_combo (combo, options) {

	if (is_dialog_blockui)
		$.blockUI ({fadeIn: 0, message: '<h1>' + options.message + '</h1>'});

	setComboValue = function (result) {

		if (result.result == 'ok') {

			for (var j = 0; j < combo.dataSource.data().length; j ++) {
				if (combo.dataSource.data() [j].id == result.id) {
					break;
				}
			}

			if (j == combo.dataSource.data().length) {
				combo.dataSource.add ({id : result.id, label : result.label});
			}

			combo.select (j);
			$(combo.element[0]).trigger('change');

		}

	};

	try {

		if (is_ua_mobile) {

			 var me = this;

			 $.showModalDialog({
				url             : window.location.protocol + '//' + window.location.host + '/i/_skins/Mint/dialog.html?' + Math.random(),
				height          : dialog_height,
				width           : dialog_width,
				resizable       : true,
				scrolling       : 'no',
				dialogArguments : {href: options.href, parent: window, title: options.title},
				onClose: function () {

					window.focus ();

					var result = this.returnValue;

					setComboValue (result);

					if (is_dialog_blockui)
						$.unblockUI ();

				}
			});


		} else {

			var result = window.showModalDialog (
				window.location.protocol + '//' + window.location.host + '/i/_skins/Mint/dialog.html?' + Math.random(),
				{href: options.href, parent: window, title: options.title},
				'status:no;resizable:yes;help:no;dialogWidth:' + options.dialog_width + 'px;dialogHeight:' + options.dialog_height + 'px'
			);

			window.focus ();

			setComboValue (result);

		}

		if (is_dialog_blockui)
			$.unblockUI ();

	} catch (e) {

		if (is_dialog_blockui)
			$.unblockUI ();

	}

}

function encode1251 (str) {

//	var r = /[а-яА-Я]/g;
//	var r = /[\340-\377\300-\337]/g;
	var r = /[\u0410-\u044f]/g;
	var result = str.replace (r, function (chr) {
		result = chr.charCodeAt(0) - 848;
		return '%' + result.toString(16);
	});
	r = /ё/g;
	result = result.replace (r, '%b8');
	r = /Ё/g;
	result = result.replace (r, '%а8');
	r = / /g;
	result = result.replace (r, '%20');

	return result;

}

function handle_hotkey_focus    (r) {document.form.elements [r.data].focus ()}
function handle_hotkey_focus_id (r) {document.getElementById (r.data).focus ()}
function handle_hotkey_href     (r) {

	if (alert_window_is_open || confirm_window_is_open) return;

	if (r.confirm && !confirm (r.confirm)) return blockEvent ();

	if (r.href) {
		nope (r.href + '&__from_table=1&salt=' + Math.random (), '_self');
	}
	else {
		activate_link_by_id (r.data);
	}

}

function nope (url, name, options) {
	var w = window;
	if (name == '_self') {
		w.location.href = url;
	}
	else {
		w.open (url, name, options);
	}
}

function nop () {}

function ancestor_window_with_child (id) {

	var w = window;
	var m = null;
	var tries = 20;

	while (tries && w && !m) {
		w = w.parent;
		m = w.document.getElementById (id);
		tries --;
	}

	if (!m) return null;

	return {
		window: w,
		child:  m
	};

}

function _dumper_href (tail, target) {

	var wf = ancestor_window_with_child ('_body_iframe');

	if (!wf) return alert ('_body_iframe not found :-((');

	var body_iframe    = wf.child.contentWindow;

	var content_iframe = body_iframe.document.getElementById ('__content_iframe');

	var href = content_iframe ? content_iframe.contentWindow.location.href : body_iframe.location.href;

	activate_link (href + tail, target);

}

function code_alt_ctrl (code, alt, ctrl) {
	var e = get_event (lastKeyDownEvent);
	if (e.keyCode != code) return 0;
	if (e.altKey  != alt)  return 0;
	if (e.ctrlKey != ctrl) return 0;
	return 1;
}

function endsWith (str, s){
	var reg = new RegExp (s + "$");
	return reg.test (str);
}

function check_top_window () {
	return;
	try {
		if (!endsWith (window.name, '_iframe')) window.location.href = window.location.href + '&__top=1'
	} catch (e) {}
}

function activate_link_by_id (id) {

	var a = document.getElementById (id);

	a_click (a)

}

function refresh_radio__div (id) {
	var div = document.getElementById ('radio_div_' + id),
		display = document.getElementById (id).checked? 'block' : 'none';

	if (div.style.display === display) {
		return;
	}
	div.style.display = display;
	if (display == 'block') {
		$(div).find('select').each(function() {
			var	$div_parents = $(this).parents('div'),
				$wrapper = $div_parents.eq((typeof $div_parents.eq(0).attr('id') == 'undefined') ? 1 : 0);

			if ($wrapper.css('display') !== 'none') {
				$(this).trigger('change');
			}
		});
	}
	if (div.hasAttribute('clear-on-hide') && display === 'none') {
		var selects = $(div).find('select');

		if (selects.length) {
			selects.data('kendoDropDownList').value(0);
			selects.trigger('change')
		}

		var dates = $(div).find('input[data-type=datepicker]');

		if (dates.length) {
			dates.data('kendoDatePicker').value(null);
			dates.trigger('change')
		}
		$(div).find('input:not([data-type])').val('').trigger('change');
	}
}

function stibqif (stib, qif) {
	if (arguments.length == 1)
		qif = stib;
	scrollable_table_is_blocked = stib;
	q_is_focused                = qif;
}

function a_click (a, e) {

	if (a.onclick) {

		try { e.cancelBubble = false } catch (xxx) {}

		a.onclick ();

	}

	if (e != null && e.cancelBubble) return;

	if (browser_is_msie) {

		a.click ();

	}
	else {

		blockEvent (e);

		var txt = '' + a;

		if (txt.substr (0, 11).toUpperCase() == 'JAVASCRIPT:') {

			var code = decodeURI (txt.substr (11));

			eval (code);

		} else {

			var target = a.target;

			if (!target) target = '_self';

			nope (a.href, target);

		}

	}

}

function focus_on_input (__focused_input) {

	var focused_inputs = document.getElementsByName (__focused_input);

	if (focused_inputs != null && focused_inputs.length > 0) {
		var focused_input = focused_inputs [0];
		try {focused_input.focus ();} catch (e) {}
		if (focused_input.type == 'radio') focused_input.select ();
		return;
	}

	$("FORM:not('.toolbar')").find("INPUT[type='text'],INPUT[type='checkbox'],INPUT[type='radio'],TEXTAREA").each (function () {
		try {
			if ($(this).is_on_screen())
				this.focus ();
		} catch (e) { return true; } return false;
	})

}

$.fn.kendoSelectsSetWidth = function() {
	var el = $(this);

	if (!el.data("kendoDropDownList")) return;

	var kendo_select  = el.data("kendoDropDownList"),
		selected_item = kendo_select.wrapper.find('span.k-input'),
		widget = el.closest('.k-widget'),
		widgetWrapperWidth,
		width,
		$parent = typeof widget.parent().attr('data-note') === 'undefined'
			? widget.parent()
			: widget.parent().parent();

	widget.css({ width: 'auto' });
	selected_item.addClass('full-size');
	width = selected_item.width() + 35;
	selected_item.removeClass('full-size');
	widgetWrapperWidth = Math.max($parent.width(), $parent[0].clientWidth);
	if (width > widgetWrapperWidth)
		width = widgetWrapperWidth + 5;
	kendo_select.list.width('auto');
	widget.width(width);
}


function adjust_kendo_selects(top_element) {

	function required_lighten() {

		var wrapper = this.wrapper;

		if (wrapper.hasClass('required')) {

			var value = this.value(),
				emptyVal = this.element.attr('data-empty-val');

			if (emptyVal ? value == emptyVal : value < 1) wrapper.addClass('light');
			else wrapper.removeClass('light');

		}

	};

	var select_tranform = function() {

		if (this.selectedIndex == $.data(this, 'prev_value')) return;

		var $this    = $(this),
			tooltips = [];

		$('option', $this).each(function() {
			tooltips.push($(this).attr('data-tooltip'));
		});

		$this.addClass('k-group').kendoDropDownList({
			height: 320,
			popup : {
				appendTo: $('body'),
			},
			dataBound: function() {

				var empty_option = this.wrapper.find('option[value=0]'),
					k_items      = this.ul.find('li.k-item'),
					is_empty     = (empty_option.length == -1) ? false : (empty_option.index() < 1);

				if (this.value() > 0 || !is_empty) this.wrapper.removeClass('required');

				this.dataItems().forEach(function(item, index) {

					var value = parseInt(item.value);

					if (value == 0 || value == -1) {
						var k_item = k_items.eq(index);

						k_item.addClass('empty');
					}

				});

			},
			open: function(e) {

				$.data($this[0], 'prev_value', this.selectedIndex);

				if (typeof this.wrapper.parent().attr('data-note') !== 'undefined') {

					var $tooltip = this.wrapper.parent(),
						K_tooltip = $tooltip.data('kendoTooltip');

					this.tooltip = K_tooltip.options;
					K_tooltip.destroy();
					$tooltip.kendoTooltip({
						autoHide: false,
						position: 'top',
						content: $tooltip.attr('data-note').replace(/(?:\r\n|\r|\n)/g, '<br/>')
					}).data('kendoTooltip').show();

				}

				$('> li', this.ul).each(function(idx) {
					if (tooltips[idx]) $(this).kendoTooltip({ content: tooltips[idx] });
				});

				if (!$this.attr('data-ken-autoopen')) return;

				var kendo_select = this,
					non_voc_options = $.grep(kendo_select.dataSource.data(), function(el, idx) {
						return el.value != 0 && el.value != -1;
					});

				if (non_voc_options.length > 0) return;

				// auto click vocabulary item
				setTimeout (function () { // HACK: 'after_open' event replacement
					kendo_select.select(function(dataItem){return dataItem.value == -1});
					$this.trigger('change');
					kendo_select.close();
				}, 200);

				return blockEvent();

			},
			close: function(e) {

				$('> li', this.ul).each(function() {
					var K_tooltip = $(this).data('kendoTooltip');
					if (K_tooltip) K_tooltip.destroy();
				});

				if (typeof this.wrapper.parent().attr('data-note') !== 'undefined') {

					var $tooltip = this.wrapper.parent(),
						K_tooltip = $tooltip.data('kendoTooltip');

					K_tooltip.destroy();
					$tooltip.kendoTooltip(this.tooltip);

				}

			},
			change: function(e) {
				required_lighten.call(this);
			}
		})
		.data('kendoDropDownList')
		.colorize_empty_value();

		$this.kendoSelectsSetWidth();

		if ($this.attr('required'))
			$this.data('kendoDropDownList').wrapper.addClass('required');

		required_lighten.call($this.data('kendoDropDownList'));

	}

	$('select', top_element).not('#_setting__suggest, #_id_filter__suggest, [multiselect]')
		.each(select_tranform)
		.change(select_tranform);

}


function do_kendo_combo_box (id, options) {

	var values      = options.values,
		ds          = {};

	if (options.href) {
		ds = {
			transport: {
				read            : {
					url         : options.href + '&salt=' + Math.random (),
					contentType : 'application/x-www-form-urlencoded; charset=UTF-8',
				},
				dataType    : 'json',
				parameterMap: function(data, type) {
					var q;
					if (data.filter && data.filter.filters && data.filter.filters [0] && data.filter.filters [0].value)
						q = data.filter.filters [0].value;
					if (!data.ids && !q)
						q = $('#' + id).data("kendoComboBox").input.val();

					if (type == 'read') {
						return {
							start   : data.skip,
							portion : data.take,
							ids     : data.ids,
							q       : q
						}
					}
				}
			},
			serverFiltering : true,
			serverPaging    : true,
			pageSize        : options.portion,
			schema   : {
				total : 'cnt',
				data  : function (result) {
schema_loop:
					for(var i = values.length - 1; i >= 0; i--) {
						for (var j = 0; j < result.result.length; j ++)
							if (result.result [j].id == values [i].id)
								continue schema_loop;
						result.result.unshift (values [i]);
					}

					return result.result;
				}
			}

		};
	} else {
		ds = values;
	}

	var required_lighten = function() {
		var wrapper = this.wrapper;

		if (wrapper.hasClass('required')) {
			var value = this.value()

			if (this.value()) {
				wrapper.removeClass('light');
			} else {
				wrapper.addClass('light');
			}
		}
	}

	var input_change = {
		is_changed : true,
		on_change  : function () {
			this.is_changed = true;
		}
	};

	var combo = $('#' + id).kendoComboBox({
		placeholder     : options.empty,
		dataTextField   : 'label',
		dataValueField  : 'id',
		filter          : 'contains',
		minLength       : 3,
		autoBind        : false,
		dataSource      : ds,
		cascade: function(e) {
			var input = this.element [0];

			if (this.value() && !this.dataItem()) {

				this.value ('');

			} else {

				if (!input.options)
					input.options = [];

				input.selectedIndex = this.selectedIndex;
				input.options [this.selectedIndex] = {};
				input.options [this.selectedIndex].value = this.value ();

			}

		},

		open : function (e) {
			stibqif (true);
			if (input_change.is_changed)
				this.dataSource.query();
			input_change.is_changed = false;
			var max_len = 0,
				data_items = this.dataSource.data (),
				w = this.popup.element.css("width").replace("px", "");
			for (var i = 0; i < data_items.length; i ++)
				if (data_items [i].label.length > max_len)
					max_len = data_items [i].label.length;

			if (max_len * 8 + 50 > w)
				this.popup.element.css("width", (max_len * 8 + 60) + "px");
		},

		close : function (e) {
			stibqif (false);
		},

		select : function (e) {
			var w = (this.dataItem() ? this.dataItem().label : e.item.text ()).length * 8 + 60,
				el = this.element.closest(".k-widget");

			if (w > el.width ())
				el.width(w);
		},
		change: function(e) {
			required_lighten.call(this);
		},
		cascade: function(e) {
			required_lighten.call(this);
		}

	}).data('kendoComboBox');

	$('#' + id + '_input').on('keypress', $.proxy(input_change.on_change, input_change));

	for(var i = 0; i < values.length; i++) {
		combo.dataSource.add ({id : values [i].id, label : values [i].label});
		if (values [i].selected)
			combo.select (i);
	}

	required_lighten.call(combo);

	var p = combo.popup.element;
	var w = p.css("visibility","hidden").show().outerWidth();
	p.hide().css("visibility","visible");
	if (options.empty && options.empty.length * 8 > w)
		w = options.empty.length * 8;
	if (options.max_len && options.max_len * 8 < w)
		w = options.max_len * 8;
	combo.element.closest(".k-widget").width(w + 60);

}

function hide_dropdown_button (id) {
	var $ul = $("#ul_" + id);

	if (!$ul.length) return false;

	$ul.remove();
	$("#form_" + id).remove();

	return true;
};

function setup_drop_down_button (id, data) {
	var $button = $('#' + id);

	$button.blur(function(e) {
		if (!$('#ul_' + id).length)
			return;

		var relTarg = e.relatedTarget || e.toElement;

		if (!relTarg) {
			window.setTimeout(function () { hide_dropdown_button(id); }, 100);

			return;
		}
		if (relTarg.id !== "ul_" + id && $(relTarg).closest('#ul_' + id).length == 0)
			hide_dropdown_button(id);
	});
	$button.click(function(e) {
		e.preventDefault();

		if (hide_dropdown_button(id)) return;

		var $this    = $(this),
			$wrapper = $('#wrapper_' + id),
			$form    = $('<form/>', { id: 'form_' + id }),
			$ul      = $('<ul/>', { id: 'ul_' + id });

		if (!$wrapper.length) {
			$wrapper = $this.wrap('<span></span>').parent();
			$wrapper.attr('id', 'wrapper_' + id);
			$wrapper.css('position', 'relative');
		}

		$wrapper.append($form);

		$ul.css({
			position      : 'absolute',
			left          : 0,
			'z-index'     : 200,
			'white-space' : 'nowrap'
		});

		if (($(document).height() - $this.offset().top) < data.length * 30 + $this[0].clientHeight) $ul.css({ bottom: $this[0].clientHeight + 'px' });
		else $ul.css({ top: '100%' });

		$form.append([
			$('<input/>', {
				id    : 'salt_' + id,
				type  : 'hidden',
				name  : '__salt',
				value : Math.random()
			}),
			$ul
		]);

		_.forEach(data, function(item) {
			item.url = item.url.replace(/'/g,'"')
		});

		$ul.kendoMenu({
			dataSource  : data,
			orientation : 'vertical',
			select      : function(e) {
				var item = data[$(e.item).index()];

				if (item.target) $(e.item).find('.k-link').attr('target', item.target);
				if (item.blockui !== null) {
					/salt=(\d{1,}\.\d{1,})/.test(item.url)
					var salt = RegExp.$1 || Math.random();
					$('#form_' + id + ' input[name=__salt]').val(salt);
					blockui('', 1, 'form_' + id, function() { hide_dropdown_button(id); });
				} else hide_dropdown_button(id);
			}
		});

		if ($ul.width() < this.clientWidth) $ul.width(this.clientWidth);

		$button.focus();
	});
}

function table_row_context_menu(e, tr) {
	var menuDiv = $('<ul class="menuFonDark" title="" style="position:absolute;z-index:200;white-space:nowrap;top:0;left:0" />').appendTo(document.body),
		items = $.parseJSON($(tr).attr('data-menu'));

	var menuDiv = $('<ul class="menuFonDark" title="" style="position:absolute;z-index:200;white-space:nowrap;top:0;left:0" />').appendTo (document.body);

	var items = $.parseJSON ($(tr).attr ('data-menu'));

	_.forEach(items, function(item) {
		item.url = item.url.replace(/'/g,'"')
	})

	menuDiv.kendoMenu ({
		dataSource: items,
		orientation: 'vertical',
		select: function (event) {
			menuDiv.remove ();
		}
	});

	var tr_offset = $(tr).offset(),
		tr_height = $(tr).height(),
		menu_top  = e.pageY >= tr_offset.top && e.pageY <= tr_offset.top + tr_height ? e.pageY - 5 : e.clientY - 5,
		menu_left = e.pageX - 5,
		is_offscreen = menu_top + $(menuDiv).height() > $(window).height();

	if (is_offscreen) {
		menu_top = menu_top - $(menuDiv).height();
	}
	menuDiv.css({
		top:  menu_top,
		left: menu_left
	});

	var width = menuDiv.width();

	window.setTimeout(function() {
		menuDiv.width(width);
	}, 100);
	menuDiv.hover(
		function() {
			menuDiv.width(width);
		},
		function() {
			window.setTimeout (function() {
				menuDiv.remove()
			}, 500);
		}
	);

	return false;
}


function __im_schedule (delay) {

	if (__im.timer) {
		clearTimeout (__im.timer);
		__im.timer = 0;
	}

	__im.timer = setTimeout ("__im_check ()", delay);

}

function __im_check () {

	if (!__im.delay) return;

	__im_schedule (__im.delay);

	$.get (__im.idx + '?salt=' + Math.random (), function (data) {

		if (data.length != 32) return;

		$.getJSON (__im.url + '&id=' + data + '&salt=' + Math.random (), function (data) {

			if (!data || !data.code) return;

			try { eval (data.code)} catch (e) {};

			__im_schedule (0);

		});

	});

}


function activate_link (href, target, no_block_event) {

	if (href.indexOf ('javascript:') == 0) {
		var code = href.substr (11).replace (/%20/g, ' ');
		eval (code);
	}
	else {

		href = href + '&salt=' + Math.random ();
		if (target == null || target == '') target = '_self';
		nope (href, target, 'toolbar=no,resizable=yes');

	}

	if (no_block_event) {

		return true;

	} else {

		blockEvent ();

	}

}



function open_popup_menu (e, type) {

	var menuDiv = $('<ul class="menuFonDark" title="" style="position:absolute;z-index:200;white-space:nowrap" />').appendTo (document.body);

	menuDiv.css ({
		top:  e.pageY,
		left: e.pageX
	});

	type = type.replace (/[\(\)]/g, "");

	var items = window [type];
	menuDiv.kendoMenu ({
		dataSource: items,
		orientation: 'vertical',
		select: function (e) {
			var selected_url = items [$(e.item).index()].url;
			if (selected_url.match(/^javascript:/)) {
				eval (selected_url);
			}
			menuDiv.remove ();
		}
	});

	var width = menuDiv.width ();

	window.setTimeout (function () {
		menuDiv.width (width);
	}, 100);

	var kill = window.setTimeout (function () {
		menuDiv.remove ()
	}, 1500);

	menuDiv.hover (
		function () {
			window.clearTimeout (kill);
			menuDiv.width (width);
		},
		function () {
			window.setTimeout (function () {
				menuDiv.remove ()
			}, 500);
		}
	);



}


function setVisible (id, isVisible) {
	document.getElementById (id).style.display = isVisible ? 'block' : 'none'
};

function restoreSelectVisibility (name, rewind) {
	setVisible (name + '_select', true);
//	setVisible (name + '_iframe', false);
	setVisible (name + '_div', false);
	document.getElementById (name + '_iframe').src = '/0.html';
	if (rewind) {
		document.getElementById (name + '_select').selectedIndex = 0;
	}
};

function setAndSubmit (name, values) {

	var form = document.forms [name];

	var elements = form.elements;

	for (var i in values) {

		if (elements [i] == undefined) {

			$('<input>').attr({
				type  : 'hidden',
				name  : i,
				value : values [i]
			}).appendTo('form[name=' + name + ']');

			continue;
		}

		elements [i].value = values [i];
	}

	form.submit ();
}

function checkMultipleInputs (f) {

	var e = f.elements;

	var formName = f.name;

	for (var j = 0; j < e.length; j ++) {

		var name = e [j].name;

		var inputs = document.getElementsByName (name);

		for (var i = 0; i < inputs.length; i++) {

			var input = inputs [i];

			var n = input.name;

			if (n.charAt (0) != '_') continue;

			var h = e [n];

			if (!h) {

				h = document.createElement('<input type="hidden" name="' + n + '">');

				f.appendChild (h);

			}

			h.value = input.value;

		}

	}

};


function setFormCheckboxes (form, checked) {

	$('input:checkbox:visible', $(document.forms [form])).each (

		function () {this.checked = checked}

	);

	return setCursor ();

}

function setCursor (w, c) {

	if (!w) w = window;
	if (!c) c = 'default';

	if (browser_is_msie && window.event) {

		var e = window.document.elementFromPoint (event.clientX, event.clientY);

		while (e) {

			try { if (e.tagName == 'A' || e.tagName == 'SPAN') e.style.cursor = c } catch (err) {};

			e = e.parentNode;

		}

	}

	var b = w.document.body;

	$(b).css ("cursor", c);

	setTimeout (function () {

		$('a',    b).css ("cursor", c == 'default' ? 'pointer' : c);
		$('span', b).css ("cursor", c);

	}, 0)

	return void (0);

}

function invoke_setSelectOption (a) {

	if (!a.question || window.confirm (a.question)) {
		var ws = ancestor_window_with_child ('__body_iframe');
		if (ws) ws.window._setSelectOption (a.id, a.label);
	}
	else {
		document.body.style.cursor = 'default';
		nop ();
	};

}

function setSelectOption (select, id, label) {

	var max_len = $(select).attr('data-max-len') ? parseInt($(select).attr('data-max-len')) : window.max_len,
		label = label.length <= max_len ? label : (label.substr (0, max_len - 3) + '...'),
		drop_down_list = $(select).data('kendoDropDownList');

	for (var i = 0; i < select.options.length; i++) {
		if (select.options[i].value == id) {
			select.options[i].innerText = label;
			drop_down_list.select(i);
			drop_down_list.focus();
			drop_down_list.refresh();
			$(select).change();
			return;
		}
	}

	drop_down_list.dataSource.add({ text: label, value: id });
	drop_down_list.value(id);
	drop_down_list.focus();
	$(select).change();

};

function blur_all_inputs () {

	$('input').each (function () {
		try {
			this.blur  ();
		}
		catch (e) {}
	});

	return 0;

}

function focus_on_first_input (td) {

	if (!td) return blur_all_inputs ();

	$('input', td).each (function () {
		try {
			this.focus  ();
			this.select ();
		}
		catch (e) {}
	});

	return 0;

}

function blockEvent (event) {

	if (browser_is_msie) event = window.event;
	try { event.keyCode = 0         } catch (e) {}
	try { event.cancelBubble = true } catch (e) {}
	try { event.returnValue = false } catch (e) {}

	return false;

}

function absTop (element) {

	var result = 0;

	while (element != null) {
		result  += element.offsetTop;
		element = element.offsetParent;
	}

	return result;

}

function handle_basic_navigation_keys () {

	if (code_alt_ctrl (116, 0, 0)) {

		if (is_dirty && !confirm (i18n.F5)) return blockEvent ();

		window.location.reload ();

		return blockEvent ();

	}

	if (q_is_focused || is_interface_is_locked)
		return;

	var e = get_event (lastKeyDownEvent);
	var keyCode = e.keyCode || e.which;
	var i = 0;

	if (e.altKey ) i += 2;
	if (e.ctrlKey) i ++;

	var kb_hook = kb_hooks [i] [keyCode];

	if (kb_hook) {
		kb_hook [0] (kb_hook [1]);
		return blockEvent ();
	}

	if (
		(keyCode == 13 || (e.originalEvent ? e.originalEvent.key : e.key) == 'Enter')
		&& !i
		&& document.activeElement.tagName != 'TEXTAREA'
		&& document.activeElement.tagName != 'A'
		&& document.activeElement.getAttribute ('type') != 'file'
		&& document.activeElement.getAttribute ('type') != 'button'
		&& document.activeElement.tabIndex
	) {
		var elements = $('[tabindex]'),
			is_focused = false;
		for (var j = document.activeElement.tabIndex + 1; j <= max_tabindex && !is_focused; j ++) {
			elements.each (function () {
				if (this.tabIndex == j) {
					$(this).focus ()
					is_focused = true;
					return false;
				}
			})
		}
		if (is_focused) {
			return blockEvent ();
		}
	}

	if (code_alt_ctrl (115, 0, 0))
		return blockEvent ();

	if (tableSlider)
		tableSlider.handle_keyboard (keyCode);

}


function image_selected(dummy_sid, id, path, width, height, image_name) {
	if (window != opener) {
		if (image_name=="")
		{
			opener.insertImageInDoc(path, width, height)
			self.focus();
			self.close();
		} else {
			opener.insertImage(id, path, width, height, image_name)
			self.focus();
			self.close();
		}
	}
}

function insertImage(id, path, width, height, image_name) {
	if(typeof(path)=="string") {
		id_image = eval('document.forms[0]._'+image_name);
		id_image.value=id;
		image_preview = eval('document.forms[0].'+image_name+'_preview')
		image_preview.src=path;
		image_preview.width=width;
		image_preview.height=height;
	}
}

function new_file_name() {
	if (document.forms[0]._file.value!='') {
		document.forms[0].preview.style.display='';
	}
	else {
		document.forms[0].preview.style.display='none';
		document.forms[0]._width.value='';
		document.forms[0]._height.value='';
	}
	document.forms[0].preview.src=document.forms[0]._file.value;
//		hiddenimg.src=document.imageupload.imagefile.value;
}

function show_size(obj) {
	document.forms[0]._width.value=obj.width;
	document.forms[0]._height.value=obj.height;
	var W=obj.width, H=obj.height;
	if(W>640)
	{
		H=H*((100.0)/W);
		W=100;
	}

	if(H>480)
	{
		W=W*((100.0)/H);
		H=100;
	}


	document.forms[0].preview.width=W;
	document.forms[0].preview.height=H;

}


function TableSlider (initial_row) {

	this.rows = [];
	this.row = 0;
	this.col = 0;

	this.is_selecting = false;

}

TableSlider.prototype.cell_location = function (td) {

	var matrix = this.rows;

    for (var i = 0; i < matrix.length; i ++) {

        for (var j = 0; j < matrix [i].length; j ++) {

            if (td.isSameNode (matrix [i][j]))

                return {
                    x : j,
                    y : i,
                    colspan : $(td).prop ('colspan'),
                    rowspan : $(td).prop ('rowspan')
                };

        }
    }

    return undefined;

}

TableSlider.prototype.addSelectClass = function (td, selection_id, directions) {

	var data = $(td).data ('selections');

	data = data || {};

	data [selection_id] = data [selection_id] || {};

	if (!directions) {
		directions = ['top', 'right', 'bottom', 'left'];
	} else {
		directions = [directions];
	}

	for (var i = 0; i < directions.length; i ++) {

		var direction = directions [i];

		data [selection_id] [direction] = 1;

		$(td).addClass('selected-' + direction);

	}

	$(td).data ('selections', data);

}

TableSlider.prototype.removeSelectClass = function (td, selection_id, directions) {

	var data = $(td).data ('selections');

	data = data || {};


	data [selection_id] = data [selection_id] || {};

	if (!directions) {
		directions = ['top', 'right', 'bottom', 'left'];
	} else {
		directions = [directions];
	}

	for (var i = 0; i < directions.length; i ++) {

		var direction = directions [i];

		delete data [selection_id] [direction];

		var is_exist_direction = false;
		for (var s in data) {
			if (data [s] [direction]) {
				is_exist_direction = true;
				break;
			}
		}
		if (!is_exist_direction) {

			$(td).removeClass('selected-' + direction);

		}

	}

	if (Object.keys(data [selection_id]).length == 0)
		delete data [selection_id];

	$(td).data ('selections', data);

}

TableSlider.prototype.addSelection = function (td, selection_id) {

	var data = $(td).data ('selections');

	data = data || {};

	data [selection_id] = data [selection_id] || {};

	data [selection_id] ['selected'] = 1;

	$(td).addClass('selected');

	$(td).data ('selections', data);

}


TableSlider.prototype.removeSelection = function (td, selection_id) {

	var data = $(td).data ('selections');

	data = data || {};

	delete data [selection_id];

	var is_exist_selection = false;
	for (var s in data) {
		if (data [s] ['selected']) {
			is_exist_selection = true;
			break;
		}
	}
	if (!is_exist_selection) {

		$(td).removeClass('selected');

	}

	$(td).data ('selections', data);

}

TableSlider.prototype.onClick = function (event, self) {

	if (event.target.tagName != 'TD')
		return;

	self.cell_off ();

	var selection_id = event.timeStamp,
		start = self.cell_location (event.target),
		matrix = self.rows,
		tds = $('td.selected', event.currentTarget);

	if (tds.length) {
		tds.removeClass('selected-single selected selected-top selected-right selected-bottom selected-left').each (function () {
			$(this).data ('selections', {});
		});
	}
	if (!$(matrix [start.y][start.x]).hasClass ('selected')) {

		self.addSelectClass (matrix [start.y][start.x], selection_id);
		self.addSelection (matrix [start.y][start.x], selection_id);

		self.calculateSelections ();

	}

	event.preventDefault ();

	return false;

}

TableSlider.prototype.onContextMenu = function (event, self) {

	if (event.target.tagName != 'TD')
		return;

	var tds = $('td.selected', event.currentTarget);

	if (tds.length) {

		tds.removeClass('selected-single selected selected-top selected-right selected-bottom selected-left').each (function () {
			$(this).data ('selections', {});
		});
		// self.showStat ($(event.currentTarget).closest ('div.eludia-table-container'), '');

		event.preventDefault ();

		return false;

	}

	return true;

}

TableSlider.prototype.showStat = function (div, text) {

	var title = $(div).closest ('form').prevAll ('.table-title');

	if (title.length)
		$('.table-stat', title).text (text);

}

TableSlider.prototype.calculateSelections = function () {

	var self = this;

	$('div.eludia-table-container').each (function () {
		var count = 0,
			sum = 0;
		$('div.st-table-right-viewport table.st-fixed-table-right td.selected').each (function () {
			count ++;
			var text = this.innerText.replace (/\s+/, '');
			text = text.replace (/,/, '.');

			if (Number(text) == text)
				sum = sum + Number(text);
		});

		// self.showStat (this, count ? i18n.count + ': ' + count + ', ' + i18n.sum + ': ' + sum : '');

	});

}

TableSlider.prototype.clear_rows = function (row) {
	self.rows = [];
}

TableSlider.prototype.set_row = function (row) {
	self = this;

	var matrix = self.rows;

	$('div.st-table-right-viewport table.st-fixed-table-right').each (function (n) {

		var table = this,
			matrix_i = matrix.length;


		for (var i = 0; i < table.rows.length; i ++) {

			if ($(table.rows [i]).hasClass("st-table-widths-row"))
				continue;

			var offset_x = 0;

			for (var j = 0; j < table.rows [i].cells.length; j ++) {
				matrix [matrix_i] = matrix [matrix_i] || [];

				while (matrix [matrix_i].length > offset_x && typeof matrix [matrix_i][offset_x] !== 'undefined')
					offset_x ++;

				for (var k = 0; k < $(table.rows [i].cells [j]).prop ('colspan'); k ++) {
					for (var l = 0; l < $(table.rows [i].cells [j]).prop ('rowspan'); l ++) {
						matrix [matrix_i + l] = matrix [matrix_i + l] || [];
						matrix [matrix_i + l][offset_x] = table.rows [i].cells [j];
					}
					offset_x ++;
				}

			}

			matrix_i ++;

		}

		$(table).on ('click', function (event) {self.onClick (event, self);});
		$(table).on ('contextmenu', function (event) {self.onContextMenu (event, self);});

	});

	self.cnt      = self.rows.length;

	if (row < self.cnt) {
		self.row = row;
	}

}

TableSlider.prototype.get_cell = function () {

	if (!this.cnt) return null;

	var the_row = this.rows [Math.min (this.row, this.cnt - 1)];

	if (!the_row) return null;

	return the_row [Math.min (this.col, the_row.length - 1)];

}

TableSlider.prototype.cell_off = function (cell) {

	$('table.st-fixed-table-right td.selected-single').removeClass ('selected-single');

	return cell;

}

TableSlider.prototype.cell_on = function (cell) {

	cell         = cell || this.get_cell ();

	if (!cell) return;

	$('table.st-fixed-table-right td.selected').removeClass ('selected-top selected-right selected-bottom selected-left selected');
	$(cell).addClass ('selected-single');

	return cell;

}

function td_on_click (event) {

	var td = event.target;

	if (td.tagName != 'TD') return;

	focus_on_first_input (td);
	$('[type="checkbox"]', td).click ();

	var tr = td;
	while (tr && tr.tagName != 'TR') {
		tr = tr.parentNode;
	};
	tableSlider.col = -1;

	var i = td;

	while (i && i.tagName == 'TD') {
		i = i.previousSibling;
		tableSlider.col ++;
	};

	for (i = 0; i < tableSlider.cnt; i ++) {

		if (tableSlider.rows [i] != tr) continue;

		tableSlider.row = i;

		break;

	}

	tableSlider.cell_off ();

	tableSlider.cell_on ();

	return true;

}

TableSlider.prototype.handle_keyboard = function (keyCode) {

	if (scrollable_table_is_blocked) return true;

	if (keyCode == 13) {									// Enter key

		var cell = this.get_cell ();

		if (!cell) return true;

		$(cell).trigger ('click');

		return false;

	}

	if (!this.cnt || keyCode < 37 || keyCode > 40) return true;

	var cnt = this.cnt;
	var key = 'row';
	var i   = keyCode % 2;

	if (i) {
		if (left_right_blocked) return true;
		var cnt = this.rows [this.row].length;
		var key = 'col';
	}

	if (!cnt) return true;

	var currentNode = this.rows [this.row][this.col];
	do {
		this [key] += (keyCode - 39 + i);
	} while (this [key] > 0 && this [key] < cnt && currentNode.isSameNode (this.rows [this.row][this.col]));

	if (this [key] < 0) this [key]    = 0;
	if (this [key] >= cnt) this [key] = cnt - 1;

	this.scrollCellToVisibleTop ();

	return blockEvent ();

}

TableSlider.prototype.scrollCellToVisibleTop = function (force_top) {

	this.cell_off ();

	var td = this.get_cell ();

	if (!td) return;

	var tr = td.parentNode;
	if (tr.tagName == 'A') tr = tr.parentNode;
	var table = $(tr).closest('table');
	var div   = $(tr).closest ('div.st-table-right-viewport').get(0);

	var delta = div.scrollTop - td.offsetTop + 2;
	if (delta > 0) div.scrollTop -= delta;

	var delta = td.offsetTop - div.scrollTop;
	if (force_top) {
		delta -= td.offsetHeight;
		delta += 8;
	}
	else {
		delta -= div.clientHeight;
		delta += td.offsetHeight + 2;
	}
	if (delta > 0) div.scrollTop += delta;

	var delta = div.scrollLeft - td.offsetLeft + 2;
	if (delta > 0) div.scrollLeft -= delta;

	var delta = td.offsetLeft - div.scrollLeft;
	delta -= div.clientWidth;
	delta += td.offsetWidth;
	if (delta > 0) div.scrollLeft += delta;

	this.cell_on ();

}




function number_format( number, decimals, dec_point, thousands_sep ) {	// Format a number with grouped thousands
	//
	// +   original by: Jonas Raoni Soares Silva (http://www.jsfromhell.com)
	// +   improved by: Kevin van Zonneveld (http://kevin.vanzonneveld.net)
	// +	 bugfix by: Michael White (http://crestidg.com)

	var i, j, kw, kd, km, sign = '';

	// input sanitation & defaults
	if( isNaN(decimals = Math.abs(decimals)) ){
		decimals = 2;
	}
	if( dec_point == undefined ){
		dec_point = ",";
	}
	if( thousands_sep == undefined ){
		thousands_sep = " ";
	}
	if (number < 0) {
		sign = '-';
		number = -number;
	}

	i = parseInt(number = (+number || 0).toFixed(decimals)) + "";

	if( (j = i.length) > 3 ){
		j = j % 3;
	} else{
		j = 0;
	}

	km = (j ? i.substr(0, j) + thousands_sep : "");
	kw = i.substr(j).replace(/(\d{3})(?=\d)/g, "$1" + thousands_sep);
	//kd = (decimals ? dec_point + Math.abs(number - i).toFixed(decimals).slice(2) : "");
	kd = (decimals ? dec_point + Math.abs(number - i).toFixed(decimals).replace(/-/, 0).slice(2) : "");


	return sign + km + kw + kd;
}

function number_clean (number) {
	var result = Number ((number || "").replace(/\s+/g, '').replace(/\,/, '.'));
	return isNaN (result) ? 0 : result;
}


function enableDropDownList(name, enable){
	document.getElementById(name).value = 0;
	document.getElementById(name).disabled = !enable;
}

function enable_input(name, enable) {
	var field = $('[name=_' + name + ']' + ',#input_' + name);
	field.prop('readonly', !enable).toggleClass('disabled', !enable);
}

function toggle_field (name, is_visible, is_clear_field) {

	is_visible = is_visible > 0;

	var field = $('[name=_' + name + ']' + ',#input_' + name);
	var td_field = field.closest('td:not(".form-inner")');

	if (td_field.is(":visible") === is_visible) {
		return;
	}

	td_field.toggle(is_visible);
	td_field.prev().toggle(is_visible);

	var sibling = td_field.prev().prev().length? td_field.prev().prev() : td_field.next().next();
	if (sibling.length)
		sibling.attr('colSpan',  parseInt(sibling.attr('colSpan')) + is_visible ? -2 : 2);

	var tr = td_field.closest('tr');
	tr.toggle(is_visible || tr.children(':visible').length > 0);

	if (is_clear_field) {
		field.val(0);
	}
	if (is_visible) {
		if (
			field.length
			&& (field[0].tagName == 'SELECT' || field.hasClass('k-input') || field.hasClass('k-textbox'))
		) {
			setTimeout(function() {
				field.trigger('change')
			}, 300)
		}
	}
}

function toggle_field_id (id, is_visible,is_clear_field) {

	var full_id;
	if (document.getElementById('input_' + id))
		full_id = 'input_' + id;
	else if (document.getElementById('_' + id + '_span'))
		full_id = '_' + id + '_span';
	else if (document.getElementById('_' + id + '_select'))
		full_id = '_' + id + '_select';
	else if (document.getElementById('_' + id + '__suggest'))
		full_id = '_' + id + '__suggest';
	else if (document.getElementById(id))
		full_id = id;
	if(!full_id)
		return 0;
	var td_field = $('[id=' + full_id + ']').closest('td');
	toggle_field_and_row(td_field, is_visible);
	if (is_clear_field == 2)
		document.getElementById(full_id).value = 0;
	else if (is_clear_field == 1)
		document.getElementById(full_id).value = "";
	if (is_visible) {
		var $field = $('#' + full_id);

		if (
			$field.length
			&& ($field[0].tagName == 'SELECT' || $field.hasClass('k-input') || $field.hasClass('k-textbox'))
		) {
			setTimeout(function() {
				$field.trigger('change')
			}, 300)
		}
	}
}

function toggle_field_and_row (td_field, is_visible) {

	td_field.toggle(is_visible);
	td_field.prev().toggle(is_visible);

	if (td_field.next().next().length == 1){

		var td_expand = td_field.next().next();
		td_expand.attr('colSpan', is_visible ? 1 : 3);

		var is_row_visible = is_visible || td_expand.parent().children(':visible').length;
		td_expand.parent().toggle(is_row_visible ? true : false);

	} else if (td_field.prev().prev().length == 1){

		var td_expand = td_field.prev().prev();
		td_expand.attr('colSpan', is_visible ? 1 : 3);

		var is_row_visible = is_visible || td_expand.parent().children(':visible').length;
		td_expand.parent().toggle(is_row_visible ? true : false);

	} else {

		var is_row_visible = is_visible || td_field.parent().children(':visible').length;
		td_field.parent().toggle(is_row_visible ? true : false);

	}
}

// sets cookie
function setCookie(name, value, props) {

	props = props || {}

	var exp = props.expires

	if (typeof exp == "number" && exp) {

		var d = new Date()

		d.setTime(d.getTime() + exp*1000)

		exp = props.expires = d
	}

	if(exp && exp.toUTCString) { props.expires = exp.toUTCString() }

	value = encodeURIComponent(value)

	var updatedCookie = name + "=" + value

	for(var propName in props){

		updatedCookie += "; " + propName

		var propValue = props[propName]

		if(propValue !== true){ updatedCookie += "=" + propValue }

	}

	document.cookie = updatedCookie

}

// get cookie value: undefined if cookie does not exist
function getCookie(name) {

	var matches = document.cookie.match(new RegExp(
	  "(?:^|; )" + name.replace(/([\.$?*|{}\(\)\[\]\\\/\+^])/g, '\\$1') + "=([^;]*)"
	))

	return matches ? decodeURIComponent(matches[1]) : undefined
}


// If Push and pop is not implemented by the browser

if (!Array.prototype.push) {

	Array.prototype.push = function array_push() {

		for(var i=0;i<arguments.length;i++) this[this.length]=arguments[i];

		return this.length;

	}

};

if (!Array.prototype.pop) {

	Array.prototype.pop = function array_pop() {

		lastElement = this[this.length-1];

		this.length = Math.max(this.length-1,0);

		return lastElement;

	}

};



// converts received flat data to hierarhy required by kendoTreeView
function treeview_convert_plain_response (response) {

	if (!response) {
		return [];
	}

	var tree_key;
	for (var key in response) {
		if ($.isArray(response[key])) {
			tree_key = key;
		}
	}

	if (!tree_key) {
		return [];
	}

	var items = response[tree_key];

	var idx = {};
	var children_nodes = {};
	for (var i in items) {
		var item = items [i];
		idx [item.id] = item;
		item.text = item.text || item.label;

		// schema.model.id added to request when loading children
		item.__parent = item.id;

		if (item.expanded || !response.no_expand_root && item.parent == 0) {
			expanded_nodes [item.id] = true;
		}

		item.expanded = expanded_nodes[item.id];

		if (!children_nodes [item.parent]) {
			children_nodes [item.parent] = [];
		}

		children_nodes [item.parent].push (item);
	}

	var first_level_nodes = []
	for (var i in items) {
		var item = items [i];
		item.items = children_nodes [item.id];

		if (item.parent == 0 || !idx [item.parent]) {
			first_level_nodes.push(item);
		}
	}
	return first_level_nodes;
}

function treeview_select_node_by_id (treeview, id_node) {

	var item = treeview.dataSource.get (id_node);
	if (item) {
		var node = treeview.findByUid (item.uid);
		treeview.select (node);
	}
}

function treeview_oncontextmenu (e) {

	e.stopPropagation ();

	var uid = $(this).data('uid');

	var tree_div = $("#splitted_tree_window_left");
	var treeview = tree_div.data ("kendoTreeView");

	var node = treeview.findByUid (uid);
	var prev_selected_node = treeview.select ();
	treeview.select (node);

	var data = treeview.dataSource.getByUid(uid);
	if (!data) return false;
	var menu = data.menu;
	if (!menu) return false;

	var a = [];
	for (i = 0; i < menu.length; i ++) a [i] = menu [i];
	tree_div.find('.treeview_contextmenu').remove();
	var menuDiv = $('<ul class="menuFonDark treeview_contextmenu" style="position:absolute;z-index:200" />').appendTo (tree_div);

	menuDiv.kendoMenu ({
		dataSource  : a,
		orientation : 'vertical',
		select      : function (e) {
			menuDiv.remove ();
		}
	});

	var left = e.pageX;
	if (e.pageX + menuDiv.width () > tree_div.width ())
		left = tree_div.width () - menuDiv.width () - 10;

	if (left < 0)
		left = 0;

	var top = e.pageY;
	if (e.pageY + menuDiv.height () > tree_div.height ())
		top = tree_div.height () - menuDiv.height () - 10;

	var top_iframe = $('#outer_tree_window_top').height() || 0;
	top = top - top_iframe;

	if (top < 0)
		top = 0;

	menuDiv.css ({
		top  : tree_div.scrollTop() + top,
		left : tree_div.scrollLeft() + left
	});

	var name = $("#splitted_tree_window_right").data('name');

	$('a', menuDiv).each (function (i, element) {
		var href = $(element).attr('href');
		var url = a[i].url;
		if (a[i].clipboard_text) {
			eludia_copy_clipboard_init (a[i].clipboard_text, element);
			a[i].target = 'invisible';
		} else if ( url && /^javascript:/.test(href)){
			$(element).attr('href', url);
		}
		var target = a[i].target || name;
		$(element).attr ('target', target);
	});

	var kill = window.setTimeout (function () {
		if (node.get (0) == treeview.select ().get(0))
			treeview.select (prev_selected_node);
		menuDiv.remove ();
	}, 3000);

	menuDiv.hover (
		function () {
			window.clearTimeout (kill)
		},
		function () {
			window.setTimeout (function () {
				if (node.get (0) == treeview.select ().get(0))
					treeview.select (prev_selected_node);
				menuDiv.remove ()
			}, 1000);
		}
	);

	return false;

}

function treeview_onexpand (e) {

	var treeview = e.sender;

	var id_expanded_node = treeview.dataItem(e.node).id;
	expanded_nodes [id_expanded_node] = true;


	setCookie ("co_" + request ['type'], Object.keys(expanded_nodes).join('.'));

	$( document ).off ('contextmenu', "#splitted_tree_window_left li", treeview_oncontextmenu);
	$( document ).on  ('contextmenu', "#splitted_tree_window_left li", treeview_oncontextmenu);
}


function treeview_onselect_node (node, expand_on_select, e) {
	var treeview = $("#splitted_tree_window_left").data ("kendoTreeView");

	if (expand_on_select == 1)
		treeview.expand(node);
	node = treeview.dataItem (node);
	if (!node || !node.href) return false;

	var href = node.href,
		right_div = $("#splitted_tree_window_right"),
		content_iframe = $('#__content_iframe', right_div);

	if (content_iframe.length && content_iframe.get(0).contentWindow && content_iframe.get(0).contentWindow.is_dirty && !confirm (i18n.F5)) {
		e.preventDefault ();
		return blockEvent ();
	}

	var name = right_div.data('name');

	content_iframe.attr('src', href);
	content_iframe.attr('name', name);

	/************************* add height in iframe *************************/
	var heghtstr = $(window.parent.document.getElementById( "tabstrip" )).height();

	if (heghtstr > 100){
		$('#__content_iframe').css('height', heghtstr - 36);
	}

	return true;
}


function treeview_save_subtree_collapsed (node, treeview) {

	delete expanded_nodes [treeview.dataItem(node).id];
	$(node).children("ul").children("li").each (function (index, node) {
		treeview_save_subtree_collapsed (node, treeview);
	});
}

function treeview_oncollapse(e) {

	var treeview = e.sender;

	var id_collapsed_node = treeview.dataItem(e.node).id;
	delete expanded_nodes[id_collapsed_node];

	treeview_save_subtree_collapsed (e.node, treeview);

	setCookie ("co_" + request ['type'], Object.keys (expanded_nodes).join ('.'));
}

function treeview_get_node_uid_by_id(node, id) {
	if (node.id == id) {
		return node.uid;
	}
	if (node.hasChildren) {

		var childs = node.children.data();
		var res = 0;
		if (!childs) {
			return 0;
		}
		for (var i = 0; i < childs.length; i++) {
			res = treeview_get_node_uid_by_id(childs[i], id);
			if (res) {return res;};
		}
	}
	return 0;
}

function treeview_select_node(e) {
	var tree = $('#splitted_tree_window_left');
	var selected_node = tree.data ('selected-node');
	if (!selected_node) {
		treeview.unbind("dataBound", treeview_select_node);
		return;
	}
	var treeview = tree.data('kendoTreeView');
	var root = treeview.dataSource.data();
	if (!root.length)
		return;

	var selected_node_uid;
	for (var i = root.length - 1; i >= 0; i--) {
		selected_node_uid = treeview_get_node_uid_by_id(root[i], selected_node);
		if (selected_node_uid) {
			break;
		}
	}

	selected_node_uid = selected_node_uid || root[0].uid;

	if(selected_node_uid){
		var select_node = treeview.findByUid(selected_node_uid);
		if (select_node) {
			treeview.select(select_node);
			treeview_onselect_node (select_node);
			treeview.element.closest(".k-scrollable").scrollTo(treeview.select(), {duration: 0});
		}
		treeview.unbind("dataBound", treeview_select_node);
	}
}

function eludia_is_flash_installed () {

	if (typeof navigator.plugins == 'undefined' || navigator.plugins.length == 0) {
		try {
			return !!(new ActiveXObject('ShockwaveFlash.ShockwaveFlash'));
		} catch (e) {
			return false;
		}
	}

	return navigator.plugins['Shockwave Flash'];
}

function eludia_copy_clipboard_init (text, element) {

	if (!eludia_is_flash_installed() || !element) {

		$(element).attr('href', 'javascript: window.prompt(\''+ i18n.clipboard_help + '\', \'' + text + '\')');

		return;
	};

	$(element).attr('data-clipboard-text', text);

	require (['/i/_skins/Mint/ZeroClipboard.min.js'], function (ZeroClipboard) {
		ZeroClipboard.config( { swfPath: '/i/_skins/Mint/ZeroClipboard.swf' } );

		var clip = new ZeroClipboard(element);

		$(element).on('destroy', function() { clip.destroy() });
	})

}


function poll_invisibles (form_name, cb) {
	var has_loading_iframes;
	if (browser_is_msie)
		$('iframe[name^="invisible"]').each (function () {if (this.readyState == 'loading') has_loading_iframes = 1});
	else if (form_name) {
		var __salt_element = $('form[name="' + form_name + '"] input[name="__salt"]');
		if (__salt_element.length === 0) __salt_element = $('#' + form_name + ' input[name="__salt"]');
			__salt = __salt_element.val ();
		if (__salt) {
			has_loading_iframes = 1;
			if (__salt == getCookie ('download_salt')) {
				has_loading_iframes = 0;
//				__salt_element.val (Math.random ());
				setCookie('download_salt', Math.random ());
			}
		}
	}

	if (!has_loading_iframes) {
		window.clearInterval(poll_invisibles_interval_id);
		poll_invisibles_interval_id = undefined;
		$.unblockUI ();
		is_interface_is_locked = false;
		setCursor ();
		if (typeof cb == 'function' ) cb();
	}
}


function activate_suggest_fields (top_element) {

	$("INPUT[data-role='autocomplete']", top_element).each (function () {
		var i = $(this),
			id = i.attr('id'),
			name = i.attr('name'),
			read_data = {};

		read_data[i.attr('name')] = new Function("return $('#" + id + "').data('kendoAutoComplete').value()");
		i.kendoAutoComplete({
			minLength       : i.attr('a-data-min-length') || 1,
			filter          : 'contains',
			dataTextField   : 'label',
			dataBound: function() {
				$('.k-nodata div').text(i18n['no_data_found']);
			},
			dataSource : {
				serverFiltering: true,
				data: {
					json: $.parseJSON(i.attr('a-data-values')),
				},
				transport: {
					read: {
						url         : i.attr('a-data-url') + "&salt=" + Math.random (),
						contentType : 'application/x-www-form-urlencoded; charset=UTF-8',
						data        : read_data,
						dataType    : 'json'
					},
					parameterMap: function(data, type) {
						var q = '',
							result = {};

						if (data.filter && data.filter.filters && data.filter.filters[0] && data.filter.filters[0].value)
							q = data.filter.filters[0].value;
						result[name + '__label'] = q;
						if (type === 'read')
							return result;
					}
				}
			},
			change: function(e) {
				var selected_item = this.current(),
					id           = '',
					label        = this.value(),
					element_id   = this.element.attr('id'),
					element_name = this.element.attr('name'),
					data         = this.dataSource.data();

				if (selected_item) {
					id    = data [selected_item.index()].id;
					label = data [selected_item.index()].label;
				} else {
					$.each(data, function(idx, item) {
						if (item.label === label)
							id = item.id;
					});
				}

				var id_element = $('#' + element_id + '__id'),
					prev_id = id_element.val();

				$('#' + element_id + '__label').val(label);
				id_element.val(id);
				if (prev_id != id)
					id_element.trigger ('change');
				$('#' + element_name + '__suggest').val(id);

				var onchange = i.attr ('a-data-change');

				if (onchange)
					eval(onchange);
			}
		});
		i.parent().css("width", i.attr("size") * 8);
	});
}


function lrt_start (filepath) {

	$('head').append('<link rel="stylesheet" href="/i/mint/libs/console.css" type="text/css" />');

	$.getScript("/i/mint/libs/console.js", function(){

		var width = $(window).width() - 10,
			height = $(window).height() - 10,
			left = $(window).width() / 2  - width / 2,
			top = $(window).height() / 2  - height / 2;

		$.blockUI ({fadeIn: 0, message: ' '});

		var div = $('body').append ('<div class="console" style="position:absolute;z-index:2000;top:'+ top
			+ 'px;left:' + left + 'px;width:' + width + 'px;height:' + height + 'px;"></div>');


		var get_lrt_interval,
			bytes_downloaded = 0,
			get_lrt = function () {
				return $.ajax ({
					url     : filepath,
					headers : {Range: 'bytes=' + bytes_downloaded + '-'},
					success : function (data, textStatus, jqXHR) {
						bytes_downloaded += parseInt(jqXHR.getResponseHeader ('Content-length'));

						var cindex = 0;

						while (cindex < data.length) {
							var service_message_index = data.indexOf ('^:::', cindex);
							if (service_message_index != -1) {

								if (service_message_index > 0) {
									var lines = data.substring (cindex, service_message_index).replace (/<br>$/, '').split (/<br>|[\r\n]/);
									for (var i = 0; i < lines.length; i ++)
										kendoConsole.log (lines [i]);
								}

								var service_message_finish = data.indexOf (':::$', cindex),
									service_message = data.substring (service_message_index + 4, service_message_finish);

								cindex = service_message_finish + 4;

								if (service_message.substring(0, 4) == '1:::') {
									var message = service_message.substring(4).split (':::');
									kendoConsole.log (message [0], message [1]);
								} else if (service_message.substring(0, 4) == '2:::') {
									clearInterval (get_lrt_interval);
									kendoConsole.log (service_message.substring(4) + '<br><br><br><br><br><br>');
								} else if (service_message.substring(0, 4) == '3:::') {
									clearInterval (get_lrt_interval);
									var message = service_message.substring(4).split (':::');
									var f = message [0] == '' ? function () {window.location.href = message [1];} : function () {alert (message [0]);window.location.href = message [1];};
									setTimeout (f, 1000);
								}

							} else {

								var lines = data.substring (cindex).replace (/<br>$/, '').split (/<br>|[\r\n]/);
								for (var i = 0; i < lines.length; i ++)
									kendoConsole.log (lines [i]);

								break;

							}
						}
					}
				});
			};
		get_lrt_interval = setInterval (get_lrt, 2000);


	});
}

function blockui(message, poll, form, cb) {
	try {
		setTimeout(function() { unblockui(); }, 1000 * 60);
		$.blockUI({
			onBlock: function() { is_interface_is_locked = true; },
			onUnblock: function() { is_interface_is_locked = false; },
			fadeIn: 0,
			message: "<h2>" + (message || "<img src='/i/_skins/Mint/busy.gif'> " + i18n.request_sent) + "</h2>"
		});
		window.blockuiAfterLoad = null;
	} catch(e) {
		window.blockuiAfterLoad = [message, poll, form];
	}

	if (window.blockuiAfterLoad) return true;
	if (poll) {
		if (poll_invisibles_interval_id) {
			window.clearInterval(poll_invisibles_interval_id);
			poll_invisibles_interval_id = undefined;
		}
		poll_invisibles_interval_id = window.setInterval(function() { poll_invisibles(form, cb) }, 100);
	} else { if (typeof cb == 'function' ) cb()};

	return true;
}

function unblockui (message, poll) {
	$.unblockUI ();
}

function init_page (options) {

	try {top.setCursor ();} catch (e) {};

	if (kendo.support)
		kendo.support.isRtl = function () {return false};

	if (kendo.ui) {
		if (kendo.ui.DatePicker)
			kendo.ui.DatePicker.prototype._reset = function () {};
		if (kendo.ui.Select)
			kendo.ui.Select.prototype._reset = function () {};
	}

	max_tabindex = options.max_tabindex;

	if (options.focus)
		window.focus ();

	var table_containers = $('div.eludia-table-container');

	if (table_containers.length) {
		require ([
			'/i/mint/libs/SuperTable/supertable.min.js?' + ((window.versions && window.versions['supertable.js']) || 'v1')
		], function (supertable) {

			table_containers.each (function(index) {
				var that = this;

				supertables.push (new supertable({
					tableUrl        : '/?' + tables_data[that.id]['table_url'] + '&__only_table=' + that.id + '&__table_cnt=' + table_containers.length,
					initial_data : tables_data [that.id],
					el: $(that),
					columns_draggable: tables_data[that.id]['disable_reorder_columns'],
					config: tables_data[that.id].config,
					index: index,
					containerRender : function(model) {
						$(that).find('tr[data-menu],td[data-menu]').on ('contextmenu', function (e) {e.stopImmediatePropagation(); return table_row_context_menu (e, this)});
						activate_suggest_fields (that);
						adjust_kendo_selects (that);
						$('[data-type=datepicker]', that).addClass('k-group').each(function () {$(this).kendoDatePicker({
							popup: {
								appendTo: $(body)
							}
						})});
						$('[data-type=datetimepicker]', that).addClass('k-group').each(function () {$(this).kendoDateTimePicker({
							popup: {
								appendTo: $(body)
							}
						})});

						try {
							var script = model.get ('script');
							if (script)
								eval (script)
						} catch (e) {
							console.log(e.message);
						}

						if (tableSlider) {
							tableSlider.clear_rows ();
							tableSlider.set_row (0);
						}
					}
				}))
			});

			options.on_load ();
			tableSlider = new TableSlider ();
			tableSlider.set_row (parseInt (options.__scrollable_table_row || 0));
			if (options.__scrollable_table_row !== null) {
				setTimeout(function() {
					var $cursor = $('td.selected-single'),
						$body = $('#body');

					if ($cursor.length && !$cursor.is_on_screen()) {
						$body.css('height', 'auto');
						$body.scrollTo($cursor.closest('.main-container').position().top + $cursor.position().top);
					}
				});
			}

			$('body').scroll(function() {
				$(document.body).find("[data-role=popup]").each(function() {
					var popup = $(this).data("kendoPopup");
					popup.close();
				});
			});
			if (typeof tableSlider.row === 'number' && tableSlider.rows.length > tableSlider.row) {
				tableSlider.scrollCellToVisibleTop ();
			}
			$(document).click (function () {$('UL.menuFonDark').remove ()});

			var splitter = table_containers.closest('.supertable_with_panels');

			if (splitter.length !== 0) {
				var splitterSize = window.top.localStorage.getItem('passportSplitterWidth') || '50%',
					splitterMaxSize = table_containers.find('.st-table-header-right-pane > div').eq(0).width() / ($(document).width() / 100);

				if (parseInt(splitterSize) > 100)
					splitterSize = '90%';
				if (parseInt(splitterSize) > splitterMaxSize)
					splitterSize = splitterMaxSize + '%';
				splitter.kendoSplitter({
					panes: [
						{ collapsible: true, size: splitterSize },
						{ collapsible: true, size: (100 - parseInt(splitterSize)) + '%' }
					],
					resize: function(e) {
						var isClose = (/^\d{1,}(\.\d{1,})?%$/.test(this.options.panes[1].size)
								? $(document).width() / 100 * parseInt(this.options.panes[1].size)
								: parseInt(this.options.panes[1].size)) < 51,
							iframe = this.wrapper.find('iframe'),
							supertableWidth = this.wrapper.find('.k-pane').eq(0).find('.st-table-right-viewport > div').width(),
							paneSizePx = /^\d{1,}(\.\d{1,})?%$/.test(this.options.panes[0].size)
								? $(document).width() / 100 * parseInt(this.options.panes[0].size)
								: parseInt(this.options.panes[0].size),
							paneSizePercent = (paneSizePx / ($(document).width() / 100)) + '%';

						if (paneSizePx > supertableWidth && ($(document).width() - paneSizePx) > 51) {
							var self = this;

							paneSizePx = supertableWidth;
							paneSizePercent = (paneSizePx / ($(document).width() / 100)) + '%';
							setTimeout(function() {
								self.size('.k-pane:first', paneSizePercent);
							}, 100);
						}
						localStorage.setItem('passportSplitterWidth', paneSizePercent);
						if (iframe.attr('src') === '/i/empty_object/' && !isClose) {
							var selectedRow = $(tableSlider.get_cell()).closest('tr'),
								data_href = selectedRow.attr('data-href') || null;

							if (data_href !== null && /open_in_supertable_panel/.test(data_href))
								open_in_supertable_panel(
									selectedRow[0],
									data_href.slice(_.indexOf(data_href, '\'') + 1, _.lastIndexOf(data_href, '\''))
								);
						}
						$(window).trigger('resize');
						setTimeout(function() {
							var view_port_height = Math.floor(
									parseInt(document.documentElement.clientHeight)
									- parseInt(splitter.offset().top)
									- window.devicePixelRatio
								);

							splitter.data('kendoSplitter').wrapper.height(view_port_height)
						}, 1000)
					}
				})
			}

			$('.k-textbox.required').each(function() {
				textbox_required(this);
			});

		});
	}

	if ($('[data-tooltip], [data-note]').length !== 0) {
		requirejs.config({
			baseUrl: '/i/mint/libs/KendoUI/js',
			shim: {
				'/i/_skins/Mint/i18n_RUS.js' : {
					deps: ['cultures/kendo.culture.ru-RU.min']
				}
			}
		})
		require([ "kendo.tooltip.min" ],
		function() {
			$(document).ready(function() {
				$('[data-tooltip], [data-note]').each(function() {
					var $this = $(this),
						options = {
							content: function(e) {
								var $this = $(e.target);

								return $this.attr(
									(typeof $this.attr('data-tooltip') === 'undefined')
										? 'data-note'
										: 'data-tooltip'
									).replace(/(?:\r\n|\r|\n)/g, '<br/>')
							}
						};

					if ($this.hasClass('form-metrics-label')) {
						options.show = function() {
							var left = $this.offset().left + parseInt($this.css('paddingLeft'));

							$(this.popup.wrapper).css({
								left: left,
								maxWidth: $('body').prop('clientWidth') - left
							})
						}
					}
					$this.kendoTooltip(options)
				})
			})
		})
	}

	var splitted_tree_window = $("#splitted_tree_window");
	if (splitted_tree_window.length) {

		splitted_tree_window.kendoSplitter ({
			panes: [
				{ collapsible: false, size: "220px" },
				{ collapsible: false }
			]
		});

		expanded_nodes = {};

		var stored_expanded_nodes = getCookie("co_" + request ['type']);
		if (stored_expanded_nodes) {
			stored_expanded_nodes = stored_expanded_nodes.split(".");
			for (var i in stored_expanded_nodes) {
				expanded_nodes[stored_expanded_nodes[i]] = true;
			}
		}
		var resizeTree = debounce (function () {
			var ontouchcontentheight = $(window.parent.document).find('#eludia-application-iframe').height() || $(window).height();
			$('#touch_welt').css('height', ontouchcontentheight);
			$('#__content_iframe').css('height', ontouchcontentheight);
			var stw = $("#splitted_tree_window").data("kendoSplitter");
			stw.size('#splitted_tree_window_left', "220px" );
		}, 500);

		$(window).on('resize', resizeTree);
	}

	activate_suggest_fields ();

	$(window).resize ();

	focus_on_input (options.__focused_input);

	if (options.blockui_on_submit) {

		$('form').submit (function () {return blockui();});

		$('form[target^="invisible"]').submit (function () {
			if (poll_invisibles_interval_id) {
				window.clearInterval (poll_invisibles_interval_id);
				poll_invisibles_interval_id = undefined;
			}
			var form_name = this.name;
			poll_invisibles_interval_id = window.setInterval(function () {poll_invisibles (form_name)}, 1000);
		});

	}

	adjust_kendo_selects ();

	$('textarea').each (function () {
		var h = $(this).height();
		$(this).height(0);
		h = this.scrollHeight > h ? this.scrollHeight : h;
		$(this).height(h);
	});

	var date_field_keydown = function(e) {
			var key = e.keyCode || e.which,
				form = $(this).closest('form');

			if (key == 13 && form.hasClass('toolbar')) form.submit();
		},
		date_field_light = function() {
			var $el = this.element,
				wrapper = this.wrapper,
				light = function() {
					if (this.element.val().length == 0) {
						this.wrapper.addClass('light');
					} else {
						this.wrapper.removeClass('light');
					}
				};

			if ($el.hasClass('required')) {
				wrapper.addClass('required')
					.addClass('light');
				$el.removeClass('required')
					.removeClass('light');
				$el.change(light.bind(this));
			}
			light.call(this);
		};

	window.required_date_field = function($field, required) {
		var wrapper = $field.closest('.k-widget');

		if (required) {
			$field.addClass('form-mandatory-inputs');
			wrapper.addClass('required');
		} else {
			$field.removeClass('form-mandatory-inputs');
			wrapper.removeClass('required');
		}
		// $field.kendoDatePicker();
		if (required) {
			date_field_light.call($field.data('kendoDatePicker'));
		}
	};

	window.init_date_fields = function($el) {
		$el.each(function(){
		var $this = $(this),
			select_time = $this.attr('data-type') === 'datetimepicker',
			options = {},
			min = $this.attr('min'),
			max = $this.attr('max');

		if (min) {
			options.min = new Date(min);
		}
		if (max) {
			options.max = new Date(max);
		}
		$this.on('keydown', date_field_keydown);
		if (select_time) {
			if ($this.attr('mask')) {
				options.format = 'dd.MM.yyyy HH:mm';
				$this.val($this.val().replace(' ', ''));
			}
			$this.kendoDateTimePicker(options);
		} else {
			$this.kendoDatePicker(options);
		}
		$.data($this[0], 'prev_value', $this.data(select_time ? 'kendoDateTimePicker' : 'kendoDatePicker').value());
		date_field_light.call($this.data(
			select_time ? 'kendoDateTimePicker' : 'kendoDatePicker'
		));
	});
	};
	init_date_fields ($('[data-type=datepicker], [data-type=datetimepicker]'));

	$('[data-type="numeric-text-box"]').each(function () {$(this).kendoNumericTextBox({format : $(this).attr('format') || 'n'})});

	$('input[mask]').each (init_masked_text_box);
	$('.k-textbox.required, .k-numericbox.required').each(function() {
		textbox_required(this)
	});

	$('input[type=file]:not([data-upload-url]):not([is-native]):not(.metrics_file)').each(function () {
		$(this).kendoUpload({
			multiple : $(this).attr('data-ken-multiple') == 'true'
		});
	});
	$('input[type=file][data-upload-url]:not(.metrics_file)').each(function () {
		$(this).kendoUpload({
			async: {
				saveUrl: $(this).attr('data-upload-url'),
				removeUrl: '/',
				autoUpload: true
			},
			files: $(this).attr('data-files')
		});
	});
	try {
		additional_params_init()
	} catch(e) {}
	$("form").on ("submit", function () {
		$('input[type=file][disabled]', this).each (function () {
			if ($('input[type=file][name="' + this.name + '"]').length == 1)
				$(this).removeAttr("disabled");
		});
	});
	$('.eludia-chart').each(function () {
		var options = $(this).data('chart-options');
		options.dataSource = new kendo.data.DataSource($(this).data('chart-datasource'));

		options.seriesClick = function (e) {
			var href = e.dataItem[e.series.field + '_href'] || e.series.href;
			if (!href) {
				return;
			}
			href = href  + '&salt=' + Math.random() + '&sid=' + request ['sid'];
			dialog_open ({
				'href': href,
				'title': e.series.name + ' - (' + e.category + ':' + e.value + ')'
			});
		};

		$(this).kendoChart(options);

		var chart = $(this).data('kendoChart');
		var resizeChart = debounce (chart.refresh, 500);
		$(window).resize (resizeChart);

		$('input[name=svg_text_' + $(this).data('name') + ']').val(chart.svg());
	});

	if ($('.eludia-clipboard').length) {
		require (['/i/_skins/Mint/ZeroClipboard.min.js'], function (ZeroClipboard) {
			ZeroClipboard.config( { swfPath: '/i/_skins/Mint/ZeroClipboard.swf' } );

			var client = new ZeroClipboard($('.eludia-clipboard'));

			client.on('aftercopy', function(event) {
				alert (i18n.clipboard_copied + ' ' + event.data['text/plain']);
			});
		});
	}


	if (top.localStorage && top.localStorage ['message']) {
		require(['kendo.notification.min'], function() {
			if (top.localStorage ['message_type'] === 'approve') {
				alert(top.localStorage ['message']);
			} else if (top.localStorage ['message_type'] === 'approve_warning') {
				warning(top.localStorage ['message']);
			} else {
				var notification = $("#notification", top.document).data("kendoNotification");
				if (!notification) {
					notification = $("<span id='notification'/>").appendTo($(top.document.body)).kendoNotification({
						stacking: "down",
						button: true
					}).data("kendoNotification");
				}
				notification.show (top.localStorage ['message'], top.localStorage ['message_type']);
			}
			top.localStorage ['message'] = '';
			top.localStorage ['message_type'] = '';
		});
	}

	if (options.session_timeout) {
		setInterval (function() {
			$.get(location.protocol + '//' + location.host + location.pathname + '?keepalive=' + window.top.options.sid + '&_salt=' + Math.random())
		}, options.session_timeout);
	}

	if (options.core_show_dump) {
		$(document).on ('mousedown', function (e) {
			if (e.button == 2 && e.ctrlKey && !e.altKey && !e.shiftKey)
				activate_link (window.location.href + '&__dump=1', 'invisible');
		});
		$(document).on ('contextmenu', function (e) {
			if (e.button == 2 && e.ctrlKey && !e.altKey && !e.shiftKey)
				return blockEvent();
		});
	}

	$(document).on('keydown', function(event) {
			lastKeyDownEvent = event;

		return handle_basic_navigation_keys();
	});

	$(document).on ('keypress', function (event) {
		if (!browser_is_msie && event.keyCode == 27)
			return false;
	});

	$(window).on ('beforeunload', function (event) {
		setCursor (window, 'wait');
		try {top.setCursor (top, 'wait')} catch (e) {};
	});

	if (table_containers.length == 0) {
		options.on_load ();
	}

	$('A.k-button').on('dragstart', function(event) { event.preventDefault(); });
	$('UL.filters > LI.ccbx').on('click', function (e) {
		$('[type="checkbox"]', e.target).click ();
	});

	require(['/i/_skins/Mint/jquery.blockUI.js'], function() {
		if (window.blockuiAfterLoad) blockui.apply(null, window.blockuiAfterLoad);
	});
}

function init_masked_text_box () {

	$(this).kendoMaskedTextBox({
		mask:$(this).attr('mask'),
		culture: "ru-RU",
		promptChar: " ",
		rules: {
			"L": /[a-zA-Zа-яА-ЯёЁ]/,
			"?": /[a-zA-Zа-яА-ЯёЁ\s]/,
			"A": /[a-zA-Zа-яА-ЯёЁ\d]/,
			"a": /[a-zA-Zа-яА-ЯёЁ\d\s]/
		}
	});

	if ($(this).data('type') == 'datepicker' || $(this).data('type') == 'datetimepicker') {
		$(this).removeClass("k-textbox");

		$(this).on('change', function () {
			$(this).kendoMaskedTextBox({
				mask:$(this).attr('mask'),
			});
			$(this).removeClass("k-textbox");
		});
	}

}

function IsID (input){
	return (input - 0) == input && input.length > 0 && input != -1;
}

function stringSetsEqual (set1, set2) {

	var set1Values = $.grep (set1.split(','), IsID).sort ();
	var set2Values = $.grep (set2.split(','), IsID).sort ();

	var setsEqual = set1Values.length == set2Values.length;
	for (var i = 0; set1Values[i] && setsEqual; i++) {
		setsEqual = set1Values[i] === set2Values[i];
	}
	return setsEqual;
}

function debounce (func, wait, immediate) {
	var timeout, result;
	return function() {
		var context = this, args = arguments;
		var later = function() {
			timeout = null;
			if (!immediate) result = func.apply(context, args);
		};
		var callNow = immediate && !timeout;
		clearTimeout(timeout);
		timeout = setTimeout(later, wait);
		if (callNow) result = func.apply(context, args);
		return result;
	};
};

function tabOnEnter () {
	void (0);
}

if (!Array.prototype.find) {
	Array.prototype.find = function(predicate) {
    	if (this == null) {
      		throw new TypeError('Array.prototype.find called on null or undefined');
    	}
    	if (typeof predicate !== 'function') {
      		throw new TypeError('predicate must be a function');
    	}
    	var list = Object(this);
    	var length = list.length >>> 0;
    	var thisArg = arguments[1];
    	var value;

    	for (var i = 0; i < length; i++) {
      		value = list[i];
      		if (predicate.call(thisArg, value, i, list)) {
        		return value;
      		}
    	}
    return undefined;
  	};
}

if (!String.prototype.trim) {
	(function() {
    	String.prototype.trim = function() {
      		return this.replace(/^[\s\uFEFF\xA0]+|[\s\uFEFF\xA0]+$/g, '');
    	};
  	})();
}

if (!window.getSelection) {
	window.getSelection = function() {
		return document.selection.createRange();
	}
}

window.queryCommandSupported__original = document.queryCommandSupported;
document.queryCommandSupported = function(command) {
	var result;
	try {
		result = window.queryCommandSupported__original(command);
	} catch(error) {
		result = false;
	}
	return result;
}

parseURL = function(a){var b=[];a=a||e.location.href;for(var d=a.slice(a.indexOf("?")+1).split("&"),c=0;c<d.length;c++)a=d[c].split("="),b.push(a[0]),b[a[0]]=a[1];return b};

var open_in_supertable_panel = function(self, url) {
	var splitter = $(self).closest('.supertable_with_panels').data('kendoSplitter'),
		iframe = splitter.wrapper.find('iframe'),
		_is_dirty = iframe[0].contentWindow.is_dirty;

	if (_is_dirty&& !confirm('Уйти без сохранения данных?'))
		return;
	if ((/^\d{1,}(\.\d{1,})?%$/.test(splitter.options.panes[1].size)
		? $(document).width() / 100 * parseInt(splitter.options.panes[1].size)
		: parseInt(splitter.options.panes[1].size)) < 51
	) { document.location.href = url;
	} else {
		if (url !== '/i/empty_object/')
			url += '&in_panel=1';
		iframe.attr('src', url);
	}
};

var textbox_required = function(el) {
	var $el = $(el),
		light = function() {
			var v = this.val().replace (/\s+/, '');
			if (v.length == 0) {
				if (!this.hasClass('light')) {
					this.addClass('light');
				}
				if (this.hasClass('k-numericbox')) {
					this.closest('.k-numeric-wrap').addClass('light');
					this.prev().addClass('light');
				}
			} else if (this.hasClass('light')) {
				this.removeClass('light');
				if (this.hasClass('k-numericbox')) {
					this.closest('.k-numeric-wrap').removeClass('light');
					this.prev().removeClass('light')
				}
			}
		};
		$el.keyup(function() {
		light.call($(this));
	});
	if ($el.hasClass('k-numericbox')) {
		$el.change(function() {
			light.call($(this))
		})
	}
	light.call($el);
};

$(document).ready(function() {

	var is_show_highlight = function(el) {
		var value = (el[0].tagName == 'SELECT')
			? parseInt(el.val())
			: el.val().trim();

		return (typeof value == 'number')
			? (value < 1)
			: (value.length == 0);
		};

	$('.k-textbox.required').each(function() {
		textbox_required(this);
	});
});

$(window).load(function() {
	if ($('#waiting_screen').length !== 0) {
		$('#waiting_screen').remove();
	}
});

$.fn.is_on_screen = function() {
	var win = $(window),
		viewport = {
			top : win.scrollTop(),
			left : win.scrollLeft()
		},
		bounds = this.offset();

	viewport.right = viewport.left + win.width();
	viewport.bottom = viewport.top + win.height();
    bounds.right = bounds.left + this.outerWidth();
    bounds.bottom = bounds.top + this.outerHeight();

    return (!(viewport.right < bounds.left || viewport.left > bounds.right || viewport.bottom < bounds.top || viewport.top > bounds.bottom));
};
