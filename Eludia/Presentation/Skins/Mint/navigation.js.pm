/*!
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

/* trim polyfill */
if (!String.prototype.trim) {
	(function() {
		// Вырезаем BOM и неразрывный пробел
		String.prototype.trim = function() {
			return this.replace(/^[\s\uFEFF\xA0]+|[\s\uFEFF\xA0]+$/g, '');
		};
	})();
}

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


window.__original_alert   = window.alert;
window.alert = function (s) {

	window.__original_alert (s);

	window.setCursor (top);
	window.setCursor (window);

};

window.__original_confirm = window.confirm;
window.confirm = function (s) {

	var r = window.__original_confirm (s);

	window.setCursor (top);
	window.setCursor (window);

	return r;

};

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

	if (typeof options.off === 'function') {
		options.off = options.off();
	}

	if (options.off)
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

	if (is_ua_mobile) {
		$.showModalDialog({
			url             : url,
			height          : options.height || dialog_height,
			width           : options.width || dialog_width,
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

function open_vocabulary_from_select (s, options) {

	if (is_dialog_blockui)
		$.blockUI ({fadeIn: 0, message: '<h1>' + options.message + '</h1>'});

	try {


		if (is_ua_mobile) {

			 $.showModalDialog({
				url             : window.location.protocol + '//' + window.location.host + '/i/_skins/Mint/dialog.html?' + Math.random(),
				height          : dialog_height,
				width           : dialog_width,
				resizable       : true,
				scrolling       : 'no',
				dialogArguments : {href: options.href, parent: window, title: options.title},
				onClose: function () {

					var result = this.returnValue || {result: 'esc'};

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

function open_vocabulary_from_combo(combo, options) {
	if (is_dialog_blockui)
		$.blockUI ({fadeIn: 0, message: '<h1>' + options.message + '</h1>'});

	var setComboValue = function (result) {
		if (result.result == 'ok') {
			for (var j = 0; j < combo.dataSource.data().length; j ++) {
				if (combo.dataSource.data()[j].id == result.id) {
					break;
				}
			}
			if (j == combo.dataSource.data().length) {
				combo.dataSource.add(
					{id: result.id, label: result.label}
				);
			}
			combo.select(j);
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

	var div = document.getElementById ('radio_div_' + id);

	if (document.getElementById (id).checked) {

		div.style.display = 'block';

	}
	else {

		div.style.display = 'none';

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
		try {this.focus ();} catch (e) { return true; } return false;
	})

}


function adjust_kendo_selects(top_element) {
	var setWidth = function(el, width) {
		var p = el.data('kendoDropDownList').popup.element,
			w = width || p.css('visibility','hidden').outerWidth() + 32;

		p.css('visibility', 'visible');
		el.closest('.k-widget').width(w);
	}

	var select_tranform = function() {
		var original_select = this,
			$original_select = $(this);

		$original_select.addClass('k-group').kendoDropDownList({
			height: 320,
			popup : {
				appendTo: $(body),
			},
			dataBound: function() {
				var self = this,
					list = this.ul.find('li');

				$.each(this.dataSource.data(), function(index, item) {
					if (item.attributes && item.attributes.length) {
						var $option = $original_select.find('option[value=' + item.value + ']'),
							$li = list.eq(index);

						$.each(item.attributes, function(_index, _item) {
							$option.attr(_item.name, _item.value);
							$li.attr(_item.name, _item.value);
						})
					}
				})
			},
			change: function(e) {
				var value = this.value(),
					valueItem = _.find(this.dataSource.data(), function(i) { return i.value == value }),
					tooltip = (valueItem && valueItem.attributes)
						? _.find(valueItem.attributes, function(i) { return i.name === 'data-tooltip' })
						: null;

				if (tooltip)
					this.wrapper.find('.k-input').attr(tooltip.name, tooltip.value)
			},
			dataSource: (function($select) {
				var dataSource = [];

				$select.find('option').each(function() {
					var $this = $(this),
						item  = {
							value: $this.attr('value').trim(),
							label: $this.text().trim(),
							attributes: []
						};

					$.each(this.attributes, function(index, attribute) {
						var name = attribute.nodeName || attribute.name;

						if (name !== 'value' && name !== 'style' && name !== 'selected')
							item.attributes.push({
								name: name,
								value: attribute.value.trim()
							})
					});
					dataSource.push(item)
				});

				return dataSource
			})($original_select),
			dataTextField: 'label',
			dataValueField: 'value',
			open: function(e) {
				$.data(original_select, 'prev_value', this.selectedIndex);
				if (!$(original_select).attr('data-ken-autoopen'))
					return;

				var kendo_select = this,
					non_voc_options = $.grep(kendo_select.dataSource.data(), function(el, idx) {
						return el.value != 0 && el.value != -1;
					});

				if (non_voc_options.length > 0)
					return;
				// auto click vocabulary item
				setTimeout(function () { // HACK: 'after_open' event replacement
					kendo_select.select(function(dataItem) {
						return dataItem.value == -1
					});
					$original_select.trigger('change');
					kendo_select.close();
				}, 200);

				return blockEvent();
			}
		}).data('kendoDropDownList');
		setWidth($original_select, $original_select.attr('data-width'));

		var kendoDropDownList = $original_select.data('kendoDropDownList'),
			$kInput = kendoDropDownList.wrapper.find('.k-input'),
			value = kendoDropDownList.value(),
			valueItem = _.find(kendoDropDownList.dataSource.data(), function(i) { return i.value == value }),
			tooltip = (valueItem && valueItem.attributes)
				? _.find(valueItem.attributes, function(i) { return i.name === 'data-tooltip' })
				: null;

		if (tooltip)
			$kInput.attr(tooltip.name, tooltip.value);
		$kInput.on('mouseenter', function() {
			var $this = $(this),
				textHasOverflown = this.scrollWidth > $this.innerWidth(),
				showTooltip = function() {
					$this.kendoTooltip({
						content: $this.attr('data-tooltip') || $this.text()
					})
					.data('kendoTooltip')
					.show();
				};

			if (textHasOverflown || $this.attr('data-tooltip')) {
				if ($.fn.kendoTooltip) {
					showTooltip()
				} else {
					require(['kendo.tooltip.min'], showTooltip)
				}
			}
		});
		$kInput.on('mouseout', function() {
			var $this = $(this);

			if ($this.data('kendoTooltip'))
				$this.data('kendoTooltip').destroy()
		});
	}

	$('select', top_element).not('#_setting__suggest, #_id_filter__suggest, [multiselect]')
		.each(select_tranform)
		.change(select_tranform);
}


function do_kendo_combo_box (id, options) {
	var values = options.values,
		ds = {};

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

	var input_change = {
		is_changed : true,
		on_change  : function () {
			this.is_changed = true;
		}
	};

	var combo = $('#' + id).kendoComboBox({
		placeholder    : options.empty,
		dataTextField  : 'label',
		dataValueField : 'id',
		filter         : 'contains',
		minLength      : 3,
		autoBind       : false,
		dataSource     : ds,
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
		open: function (e) {
			stibqif (true);
			if (input_change.is_changed)
				this.dataSource.query();
			input_change.is_changed = false;
		},
		close: function (e) {
			stibqif (false);
		}
	}).data('kendoComboBox');
	$('#' + id + '_input').on('keypress', $.proxy(input_change.on_change, input_change));
	for (var i = 0; i < values.length; i++) {
		combo.dataSource.add({id: values[i].id,label: values[i].label});
		if (values[i].selected)
			combo.select(i);
	}
	combo.element.closest(".k-widget").width(
		options.width || options.empty.length * 8 + 32
	);
	combo.input.on('mouseover', function() {
		var $this = $(this),
			textHasOverflown = this.scrollWidth > $this.innerWidth();

		if (textHasOverflown) {
			$this.kendoTooltip({
				content: $this.val()
			})
			.data('kendoTooltip')
			.show();
		}
	});
	combo.input.on('mouseout', function() {
		var $this = $(this);

		if ($this.data('kendoTooltip'))
			$this.data('kendoTooltip').destroy()
	});
}

function hide_dropdown_button (id) {
	if (document.getElementById ("ul_" + id)) {
		$("#ul_" + id).remove();
		return true;
	}
};

function setup_drop_down_button (id, data) {
	$("#" + id).on ('blur', function (e) {
		var relTarg = e.relatedTarget || e.toElement
		if (relTarg == undefined || relTarg == null) {
			window.setTimeout(function () {hide_dropdown_button (id);}, 100);
			return;
		}
		if (relTarg.id !== "ul_" + id && $(relTarg).closest('#ul_' + id).length == 0)
			hide_dropdown_button (id);
	});

	$("#" + id).on ('click', function (e) {

		if (hide_dropdown_button (id)) {
			return false;
		}

		var menuDiv = $('<ul id="ul_' + id + '" title="" style="position:absolute;z-index:200;white-space:nowrap" />').appendTo (document.body);

		var a_offset = $(this).offset ();

		menuDiv.css ({
			top:  a_offset.top + this.clientHeight,
			left: a_offset.left,
		});

		menuDiv.kendoMenu ({
			dataSource: data,
			orientation: 'vertical',
			select: function (e) {
				var selected_url = data [$(e.item).index()].url;
				if (selected_url.match(/^javascript:/)) {
					eval (selected_url);
				}
				menuDiv.remove ();
				return true;
			}
		});

		if (menuDiv.width () < this.clientWidth)
			menuDiv.width (this.clientWidth);

		return false;

	});
}

function table_row_context_menu (e, tr) {

	var menuDiv = $('<ul class="menuFonDark" title="" style="position:absolute;z-index:200;white-space:nowrap;top:0;left:0" />').appendTo (document.body);

	var items = $.parseJSON ($(tr).attr ('data-menu'));
	menuDiv.kendoMenu ({
		dataSource: items,
		orientation: 'vertical',
		select: function (event) {
			var selected_url = items [$(event.item).index()].url;
			if (selected_url.match(/^javascript:/)) {
				eval (selected_url);
			}
			menuDiv.remove ();
		}
	});

	var tr_offset = $(tr).offset ();
	var tr_height = $(tr).height ();

	var menu_top  = e.pageY >= tr_offset.top && e.pageY <= tr_offset.top + tr_height ? e.pageY - 5 : e.clientY - 5;
	var menu_left = e.pageX - 5;

	var is_offscreen = menu_top + $(menuDiv).height() > $(window).height();
	if (is_offscreen) {
		menu_top = menu_top - $(menuDiv).height();
	}


	menuDiv.css ({
		top:  menu_top,
		left: menu_left
	});

	var width = menuDiv.width ();

	window.setTimeout (function () {
		menuDiv.width (width);
	}, 100);

	menuDiv.hover (
		function () {
			menuDiv.width (width);
		},
		function () {
			window.setTimeout (function () {
				menuDiv.remove ()
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
	var $select = $(select),
		maxLen = $select.attr('data-max-len') ? parseInt($select.attr('data-max-len')) : window.max_len,
		label = label.length <= maxLen ? label : (label.substr (0, maxLen - 3) + '...'),
		dropDownList = $select.data('kendoDropDownList'),
		item = _.find(select.options, function(option) { return option.value == id });

	if (!item) {
		var newItem = {};

		newItem[dropDownList.options.dataTextField] = label;
		newItem[dropDownList.options.dataValueField] = id;
		dropDownList.dataSource.add(newItem);
	}
	dropDownList.value(id);
	dropDownList.focus();
	$select.change();
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

	if (event.target.tagName != 'TD' || !event.ctrlKey)
		return;

	self.cell_off ();

	var selection_id = event.timeStamp,
		start = self.cell_location (event.target),
		matrix = self.rows;

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
		self.showStat ($(event.currentTarget).closest ('div.eludia-table-container'), '');

		event.preventDefault ();

		return false;

	}

	return true;

}

TableSlider.prototype.onMouseDown = function (event, self) {

	if (event.target.tagName != 'TD' || event.which != 1)
		return;

	if (!event.ctrlKey)
		$(event.currentTarget).find('td').removeClass('selected-single selected selected-top selected-right selected-bottom selected-left').each (function () {
			$(this).data ('selections', {});
		});


	var selection_id = event.timeStamp,
		start = self.cell_location (event.target),
		matrix = self.rows;

	$(event.currentTarget).mouseover(function (event) {

		if (event.target.tagName != 'TD')
			return;

		self.cell_off ();

		var td = event.target,
			finish = self.cell_location (td);

		$(this).addClass ('selected');

		var x1 = Math.min(start.x, finish.x);
		var y1 = Math.min(start.y, finish.y);
		var x2 = Math.max(start.x + start.colspan - 1, finish.x + finish.colspan - 1);
		var y2 = Math.max(start.y + start.rowspan - 1, finish.y + finish.rowspan - 1);

		var should_be_restarted;

		do {

			should_be_restarted = false;

TOP:
			for (var i = y1 > 0 ? y1 - 1 : 0; i <= y2 + 1 && i < matrix.length; i ++) {

				for (var j = x1 > 0 ? x1 - 1 : 0; j <= x2 + 1 && j < matrix [i].length; j ++) {

					if (i < y1 || i > y2 || j < x1 || j > x2) {
						self.removeSelection (matrix [i][j], selection_id);
						self.removeSelectClass (matrix [i][j], selection_id);

						continue;
					}

					self.addSelection (matrix [i][j], selection_id);

					if (i == y1)
						self.addSelectClass (matrix [i][j], selection_id, 'top');
					else
						self.removeSelectClass (matrix [i][j], selection_id, 'top');

					if (i == y2)
						self.addSelectClass (matrix [i][j], selection_id, 'bottom');
					else
						self.removeSelectClass (matrix [i][j], selection_id, 'bottom');

					if (j == x1)
						self.addSelectClass (matrix [i][j], selection_id, 'left');
					else
						self.removeSelectClass (matrix [i][j], selection_id, 'left');

					if (j == x2)
						self.addSelectClass (matrix [i][j], selection_id, 'right');
					else
						self.removeSelectClass (matrix [i][j], selection_id, 'right');


					var shift_x_left = 0,
						shift_x_right = 0,
						shift_y_up = 0,
						shift_y_down = 0;

					if ($(matrix [i][j]).prop ('colspan') > 1) {

						for (var k = x1 - 1; k >= 0; k --) {
							if (matrix [i][j].isSameNode (matrix [i][k]))
								shift_x_left ++;
							else {
								break;
							}
						}

						for (var k = x2 + 1; k < matrix [i].length; k ++) {
							if (matrix [i][j].isSameNode (matrix [i][k]))
								shift_x_right ++;
							else {
								break;
							}
						}


						for (var k = y1 - 1; k >= 0; k --) {
							if (matrix [i][j].isSameNode (matrix [k][j]))
								shift_y_up ++;
							else {
								break;
							}
						}

						for (var k = y2 + 1; k < matrix.length; k ++) {
							if (matrix [i][j].isSameNode (matrix [k][j]))
								shift_y_down ++;
							else {
								break;
							}
						}

					}

					if (shift_x_left || shift_x_right || shift_y_up || shift_y_down) {
						x1 = x1 - shift_x_left;
						x2 = x2 + shift_x_right;
						y1 = y1 - shift_y_up;
						y2 = y2 + shift_y_down;
						should_be_restarted = true;

						break TOP;

					}

				}

			}

		} while (should_be_restarted);

	});

	var table = event.currentTarget;

	$(document).mouseup(function (event) {

		$(table).unbind('mouseover');
		$(table).removeClass ('selected');
		$(document).unbind('mouseup');

		self.calculateSelections ();

		return false;

	});

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

		self.showStat (this, count ? i18n.count + ': ' + count + ', ' + i18n.sum + ': ' + sum : '');

	});

}

TableSlider.prototype.clear_rows = function (row) {
	self.rows = [];
}

TableSlider.prototype.set_row = function (row) {

	var self = this,
		matrix = self.rows;

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

		$(table).on ('mousedown', function (event) {self.onMouseDown (event, self);});
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
	if (sibling.length) {
		var colspan = sibling.attr('colSpan') + (is_visible? -2 : 2);
		sibling.attr('colSpan', colspan);
	}

	var tr = td_field.closest('tr');
	tr.toggle(is_visible || tr.children(':visible').length > 0);

	if (is_clear_field) {
		field.val(0);
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

		if (item.parent == 0 || item.expanded) {
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
	var menuDiv = $('<ul class="menuFonDark" style="position:absolute;z-index:200" />').appendTo (tree_div);

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

	$( document ).on ('contextmenu', "#splitted_tree_window_left li", treeview_oncontextmenu);
}


function treeview_onselect_node (node, expand_on_select, e) {

	var treeview = $("#splitted_tree_window_left").data ("kendoTreeView");

	if (expand_on_select == 1)
		treeview.expand(node);

	node = treeview.dataItem (node);
	if (!node || !node.href) return false;
	var href = node.href;

	var right_div = $("#splitted_tree_window_right"),
		content_iframe = $('#__content_iframe', right_div);

	if (content_iframe.length && content_iframe.get(0).contentWindow && content_iframe.get(0).contentWindow.is_dirty && !confirm (i18n.F5)) {
		e.preventDefault ();
		return blockEvent ();
	}

	var name = right_div.data('name');
	right_div.html ("<iframe onload='this.style.visibility="+'"visible"'+"' style='visibility: hidden;' width=100% height=100% src='" + href + "' name='" + name + "' id='__content_iframe' application=yes scroll=no>");

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

	var selected_node_uid = treeview_get_node_uid_by_id(root[0], selected_node) || root[0].uid;
	if(selected_node_uid){
		var select_node = treeview.findByUid(selected_node_uid);
		if (select_node) {
			treeview.select(select_node);
			treeview_onselect_node (select_node);
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


function poll_invisibles (form_name) {
	var has_loading_iframes;
	if (browser_is_msie)
		$('iframe[name^="invisible"]').each (function () {if (this.readyState == 'loading') has_loading_iframes = 1});
	else if (form_name) {
		var __salt_element = $('form[name="' + form_name + '"] input[name="__salt"]'),
			__salt = __salt_element.val ();
		if (__salt) {
			has_loading_iframes = 1;
			if (__salt == getCookie ('download_salt')) {
				has_loading_iframes = 0;
				__salt_element.val (Math.random ());
			}
		}
	}

	if (!has_loading_iframes) {
		window.clearInterval(poll_invisibles_interval_id);
		poll_invisibles_interval_id = undefined;
		$.unblockUI ();
		is_interface_is_locked = false;
		setCursor ();
	}
}


function activate_suggest_fields (top_element) {

	$("INPUT[data-role='autocomplete']", top_element).each (function () {
		var i = $(this);
		var id = i.attr ('id');

		var read_data = {};
		read_data [i.attr ('name')] = new Function("return $('#" + id + "').data('kendoAutoComplete').value()");

		i.kendoAutoComplete({
			minLength       : i.attr ('a-data-min-length') || 1,
			filter          : 'contains',
			dataTextField   : 'label',
			dataSource      : {
				serverFiltering : true,
				data: {
					json: $.parseJSON (i.attr ('a-data-values')),
				},
				transport: {
					read            : {
						url         : i.attr ('a-data-url') + "&salt=" + Math.random (),
						contentType : 'application/x-www-form-urlencoded; charset=UTF-8',
						data        : read_data,
						dataType    : 'json'
					},
					parameterMap: function(data, type) {
						var q = '';
						if (data.filter && data.filter.filters && data.filter.filters [0] && data.filter.filters [0].value)
							q = data.filter.filters [0].value;

						var result = {};
						result [$('#' + id).attr ('name') + '__label'] = q;

						if (type == 'read') {
							return result;
						}
					}
				}
			},
			change          : function(e) {
				var selected_item = this.current();
				var id           = '',
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

				var
					id_element = $('#' + element_id + '__id'),
					prev_id = id_element.val();

				$('#' + element_id + '__label').val(label);
				id_element.val(id);
				if (prev_id != id)
					id_element.trigger ('change');
				$('#' + element_name + '__suggest').val(id);

				var onchange = i.attr ('a-data-change');
				if (onchange) {
					eval (onchange);
				}
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
									var f = function () {alert (message [0]);window.location.href = message [1];};
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

function blockui (message, poll) {

	$.blockUI ({
		onBlock: function(){ is_interface_is_locked = true; },
		onUnblock: function(){ is_interface_is_locked = false; },
		fadeIn: 0,
		message: "<h2>" + (message || "<img src='/i/_skins/Mint/busy.gif'> " + i18n.request_sent) + "</h2>"
	});

	if (poll) {
		if (poll_invisibles_interval_id) {
			window.clearInterval (poll_invisibles_interval_id);
			poll_invisibles_interval_id = undefined;
		}
		poll_invisibles_interval_id = window.setInterval(poll_invisibles, 100);
	}

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
		require (['/i/mint/libs/SuperTable/supertable.min.js'], function (supertable) {

			table_containers.each (function() {
				var that = this;

				supertables.push (new supertable({
					tableUrl        : '/?' + tables_data [that.id]['table_url'] + '&__only_table=' + that.id + '&__table_cnt=' + table_containers.length,
					initial_data : tables_data [that.id],
					el: $(that),
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
			tableSlider.set_row (parseInt (options.__scrollable_table_row));

			$(body).scroll(function() {
				$(document.body).find("[data-role=popup]").each(function() {
					var popup = $(this).data("kendoPopup");
					popup.close();
				});
			});

			if (typeof tableSlider.row === 'number' && tableSlider.rows.length > tableSlider.row) {
				tableSlider.scrollCellToVisibleTop ();
			}

			$(document).click (function () {$('UL.menuFonDark').remove ()});

		});
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
			var ontouchcontentheight = $(window.parent.document).find('iframe').height() || $(window).height();
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

	$('[data-type=datepicker]').each(function () {$(this).kendoDatePicker()});
	$('[data-type=datetimepicker]').each(function () {$(this).kendoDateTimePicker()});

	$('input[mask]').each (init_masked_text_box);

	$('input[type=file]:not([data-upload-url]):not([is-native])').each(function () {
		$(this).kendoUpload({
			multiple : $(this).attr('data-ken-multiple') == 'true'
		});
	});
	$('input[type=file][data-upload-url]').each(function () {
		$(this).kendoUpload({
			async: {
				saveUrl: $(this).attr('data-upload-url'),
				autoUpload: true
			}
		});
	});

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
			var notification = $("#notification", top.document).data("kendoNotification");
			if (!notification) {
				notification = $("<span id='notification'/>").appendTo($(top.document.body)).kendoNotification({
					stacking: "down",
					button: true
				}).data("kendoNotification");
			}
			notification.show (top.localStorage ['message'], top.localStorage ['message_type']);
			top.localStorage ['message'] = '';
			top.localStorage ['message_type'] = '';
		});
	}

	if (options.session_timeout) {
		setInterval (function () {
			$.get (location.protocol + '//' + location.host + location.pathname + '?keepalive=' + request ['sid'] + '&_salt=' + Math.random ())
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

	$(document).on ('keydown', function (event) {
		lastKeyDownEvent = event;
		return handle_basic_navigation_keys ();
	});

	$(document).on ('keypress', function (event) {
		if (!browser_is_msie && event.keyCode == 27)
			return false;
	});

	if (options.help_url) {
		$(document).on ('help', function (event) {
			nope (options.help_url, '_blank', 'toolbar=no,resizable=yes');
			blockEvent ();
		});
	}

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

	require (['/i/_skins/Mint/jquery.blockUI.js']);

}

function init_masked_text_box () {

	$(this).kendoMaskedTextBox({
		mask:$(this).attr('mask')
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

$(document).on('mouseenter', '.k-popup .k-item', function() {
	var $this = $(this),
		textHasOverflown = this.scrollWidth > $this.innerWidth(),
		showTooltip = function() {
			$this.kendoTooltip({
				content: $this.attr('data-tooltip') || $this.text()
			})
			.data('kendoTooltip')
			.show();
		};

	if ($this.data('kendoTooltip')) {
		$this.data('kendoTooltip').show()
	} else {
		if (textHasOverflown || $this.attr('data-tooltip')) {
			if ($.fn.kendoTooltip) {
				showTooltip()
			} else {
				require(['kendo.tooltip.min'], showTooltip)
			}
		}
	}
});

$(document).on('mouseout', '.k-popup .k-item', function() {
	$('[data-role=tooltip]').each(function() {
		var kendoTooltip = $(this).data('kendoTooltip');

		if (kendoTooltip && typeof kendoTooltip.hide !== 'undefined') {
			$(this).data('kendoTooltip').hide()
		}
	})
});