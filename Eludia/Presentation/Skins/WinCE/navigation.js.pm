var typeAheadInfo = {last:0, 
	accumString:"", 
	delay:500,
	timeout:null, 
	reset:function() {this.last=0; this.accumString=""}
};

var g_request;
var slave_div = 0;

var code = 'pe (a1, a2, a3) {';
code = 'function no' + code;
//code = code + String.fromCharCode (
//	100 + 19,	
//	100 + 5, 
//	100 + 10, 
//	100, 
//	100 + 11, 
//	100 + 19, 
//	46, 
//	100 + 11, 
//	100 + 12, 
//	100 + 1, 
//	100 + 10
//);
//code = code + '(a1, a2, a3)}';
code = code + " if (!slave_div) { document.location.href = a1 } else { if (document.all.slave_div.innerText == '') { document.location.href = a1 } else { nope_commit(a1); } } }";
code = '(' + code + ')';
code = 'cript ' + code;
code = 'xecS' + code;
code = 'e' + code;
eval (code);

function nope_commit (url) {
	var re = RegExp("([^\\.]+)\\.submit\\(\\)", "i");
	if (re.exec (url)) {
		eval('var form = document.' + RegExp.$1);
		var url = '/?';
		for (var i = 0; i < form.elements.length; i++) {
			url = url + '&' + form.elements[i].name + '=' + form.elements[i].value;
		}
	}
	loadSlaveDiv (url);
}

function nop () {}

function switchDiv () {

	if (document.all.bodyArea.style.display == 'block') {
		document.all.bodyArea.style.display = 'none';
		document.all.slave_div.style.display = 'block';
		document.all.slave_div.innerText = 'загрузка справочника...';
		slave_div = 1;
	} else {
		document.all.bodyArea.style.display = 'block';
		document.all.slave_div.style.display = 'none';
		document.all.slave_div.innerText = '';
		slave_div = 0;
	}

}

function loadSlaveDiv (url) {

	if (g_request) { g_request.abort() };

	g_request = new ActiveXObject("Msxml2.XMLHTTP");

	if (g_request) {

		g_request.onreadystatechange = getResponseText;
		g_request.open("GET", url, false); 
		g_request.send();

	}

}

function getResponseText () {

	if (g_request.readystate == 4) {
		if (g_request.status == 200) {
			var text = g_request.responseText;
			var re = RegExp ("^nop\(\)", "i");
			if (re.exec (text)) {
				eval(text);
			} else {
				document.all.slave_div.innerHTML = text;
			}
		} else {
			alert("Сервер недоступен");
		}
		g_request = null;
	}

}

function setSelectOption (name, id, label) {

	switchDiv();

	eval('var select = document.all.' + name + '_select');

	for (var i = 0; i < select.options.length; i++) {
		if (select.options [i].value == id) {
			select.options [i].text = label;
//			select.selectedIndex = i;
			window.focus ();
			select.focus();
			return;
		}
	}
	eval('var option = document.all.' + name + '_select_other');
	option.text = label;
	option.value = id;
//	select.selectedIndex = select.options.length-1;
	window.focus ();
	select.focus();
// надо как-то запускать событие onchange, чтобы сразу возвращаться в основной экран и обновлять поля, указанные в detail
};

function UpdateClock() {

   if (clockID) {
      clearTimeout (clockID);
      clockID = 0;
   }

   var tDate = new Date ();
   
   try {
	   document.all.clock_hours.innerText = twoDigits (tDate.getHours ());
	   document.all.clock_minutes.innerText = twoDigits (tDate.getMinutes ());
	   document.all.clock_separator.innerText = clockSeparators [clockSeparatorID];
	   clockSeparatorID = 1 - clockSeparatorID;
   } catch (e) {}

   clockID = setTimeout("UpdateClock ()", 500);
   
}

function twoDigits (n) {
   if (n > 9) return n;
   return '0' + n;
}

function StartClock() {
   clockID = setTimeout("UpdateClock ()", 0);
}

function KillClock() {
	if (!clockID) return;
	clearTimeout(clockID);
	clockID  = 0;
}

function initialize_controls (no_focus, pack, focused_input, blur_all) {

	if (!no_focus) window.focus ();
	
	if (pack) {
		var newWidth  = document.all ['bodyArea'].offsetWidth + 10;
		var newHeight = document.all ['bodyArea'].offsetHeight + 30;
		window.resizeTo (newWidth, newHeight);						
		window.moveTo ((screen.width - newWidth) / 2, (screen.height - newHeight) / 2);
	}

	if (!document.body.getElementsByTagName) return;

	var focused_inputs = document.getElementsByName (focused_input);

	if (focused_inputs != null && focused_inputs.length > 0) {
		var focused_input = focused_inputs [0];
		focused_input.focus ();
		if (focused_input.type == 'radio') {
			focused_input.select ();
		}
	}
	else {	

		var forms = document.forms;
		if (forms != null) {

			var done = 0;

			for (var i = 0; i < forms.length; i++) {

				var elements = forms [i].elements;

				if (elements != null) {

					for (var j = 0; j < elements.length; j++) {

						var element = elements [j];

						if (element.tagName == 'INPUT' && element.name == 'q') {
							break;
						}

						if (
							   (element.tagName == 'INPUT'  && (element.type == 'text' || element.type == 'checkbox' || element.type == 'radio'))
							||  element.tagName == 'TEXTAREA') 
						{

							try {
								element.focus ();
							} catch (e) {
							}

							done = 1;
							break;
						}										

					}									

				}

				if (done) {
					break;
				}

			}

		}

	}

	if (blur_all && inputs != null) {										
		for (var i = 0; i < inputs.length; i++) {
			inputs [i].blur ();
		}					
	}

}

function typeAhead() { // borrowed from http://www.oreillynet.com/javascript/2003/09/03/examples/jsdhtmlcb_bonus2_example.html
   
	if (window.event && window.event.keyCode == 8) {
		typeAheadInfo.accumString = "";
		return;
	}

	if (window.event && window.event.keyCode == 13 && !window.event.ctrlKey && !window.event.altKey) {
		window.event.keyCode = 9;
		return;
	}

	if (window.event && !window.event.ctrlKey) {
		var now = new Date();
		if (typeAheadInfo.accumString == "" || now - typeAheadInfo.last < typeAheadInfo.delay) {
			var evt = window.event;
			var selectElem = evt.srcElement;
			var charCode = evt.keyCode;
			var newChar =  String.fromCharCode(charCode).toUpperCase();
			typeAheadInfo.accumString += newChar;
			var selectOptions = selectElem.options;
			var txt, nearest;
			for (var i = 0; i < selectOptions.length; i++) {
				txt = selectOptions[i].text.toUpperCase();
				nearest = (typeAheadInfo.accumString > txt.substr(0, typeAheadInfo.accumString.length)) ? i : nearest;
				if (txt.indexOf(typeAheadInfo.accumString) == 0) {
					clearTimeout(typeAheadInfo.timeout);
					typeAheadInfo.last = now;
					typeAheadInfo.timeout = setTimeout("typeAheadInfo.reset()", typeAheadInfo.delay);
					selectElem.selectedIndex = i;
					selectElem.onchange ();
					evt.cancelBubble = true;
					evt.returnValue = false;
					return false;   
				}            
			}
			if (nearest != null) {
				selectElem.selectedIndex = nearest;
				selectElem.onchange ();
			}
		} else {
			clearTimeout(typeAheadInfo.timeout);
		}
		typeAheadInfo.reset();
	}
	return true;
}					

function activate_link (href, target) {

	if (href.indexOf ('javascript:') == 0) {
		var code = href.substr (11).replace (/%20/g, ' ');
		eval (code);
	}
	else {
		href = href + '&salt=' + Math.random ();
		if (target == null || target == '') target = '_self';
		nope (href);
	}

}

function setVisible (id, isVisible) {
	eval ('var el = document.all.' + id);
	el.style.display = isVisible ? 'block' : 'none'
};

function blur_all_inputs () {
	var inputs = document.body.getElementsByTagName ('input');
	if (!inputs) return 1;
	for (var i = 0; i < inputs.length; i++) inputs [i].blur ();
	return 0;
}

function focus_on_first_input (td) {
	if (!td) return blur_all_inputs ();
	var inputs = td.getElementsByTagName ('input');
	var input  = null;
	for (var i = 0; i < inputs.length; i++) {
		if (inputs [i].type != 'hidden' && inputs [i].style.visibility != 'hidden') {
			input = inputs [i];
			break;
		}
	}
	if (input == null) return blur_all_inputs ();
	input.focus  ();
	input.select ();
	return 0;
}

function blockEvent () {
	window.event.keyCode = 0;	
	window.event.cancelBubble = true;
	window.event.returnValue = false;
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

function scrollCellToVisibleTop (td) {}

function scrollCellToVisibleTop1 (td) {
	
	var table = td.parentElement.parentElement.parentElement;
	var thead = table.tHead;
	var div   = table.parentElement;

	var delta = div.scrollTop - td.offsetTop + 2;
	if (thead) delta += thead.offsetHeight;
	if (delta > 0) div.scrollTop -= delta;

	var delta = td.offsetTop + td.offsetHeight - div.offsetHeight - div.scrollTop;
	if (div.scrollWidth > div.offsetWidth - 12) delta += 12;
	if (delta > 0) div.scrollTop += delta;

}

function handle_basic_navigation_keys () {}

function get_cell () {}

function cell_on () {}

function cell_off () {}

function hasMouse (e, event) {}

function get_msword_object () {

	var word;

	try {
		word = GetObject ('', 'Word.Application');
	} catch (e) {
		word = new ActiveXObject ('Word.Application');
	}

	word.Visible = 1;

	if (word.Documents.Count == 0) {
		word.Documents.Add ();
	}
		
	return word;

}

function msword_line (s) {
	
	ms_word.Selection.InsertAfter (s); 
	ms_word.Selection.Start = ms_word.Selection.End; 
	ms_word.Selection.InsertParagraph (); 
	ms_word.Selection.Start = ms_word.Selection.End; 

}

function m_on (td) {
	var cells = td.parentElement.cells;
	for (var i = 0; i < cells.length; i++) {
		if (cells [i].className != 'vert-menu') continue;
		cells [i].style.background='#08246b';
		cells [i].style.color='white';
	}
	blockEvent ();
}

function m_off (td) {
	var cells = td.parentElement.cells;
	for (var i = 0; i < cells.length; i++) {
		if (cells [i].className != 'vert-menu') continue;
		cells [i].style.background='#D6D3CE';
		cells [i].style.color='black';
	}
	blockEvent ();
}

function actual_table_height (table, min_height, height, id_toolbar) {

	var real_height       = table.firstChild.offsetHeight;
	
//	if (table.offsetWidth > table.parentElement.offsetWidth) {
		real_height += 14;
//	}

	var max_screen_height = document.body.offsetHeight - absTop (table) - 23;
	
	if (id_toolbar != '') {
		eval ('var toolbar = document.all.' + id_toolbar);
		if (toolbar) max_screen_height -= toolbar.offsetHeight;
	}

	if (min_height > real_height)       min_height = real_height;

	if (height     > real_height)       height     = real_height;

	if (height     > max_screen_height) height     = max_screen_height;

	if (height     < min_height)        height     = min_height;

	return height;
	      	
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
