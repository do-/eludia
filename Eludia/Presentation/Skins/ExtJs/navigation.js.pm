	Ext.BLANK_IMAGE_URL = '/i/0.gif';
	Ext.util.Cookies.set ('ExtJs', 1);

	var sid			= null;
	var fio			= null;
	var menu_md5	= '';
	var target		= null;

/////////////// CORE

	function nope (url, _target, options) {

		target = _target ? _target : center;

		clear (target);

		Ext.Ajax.request ({

			url: url,

			success: function (response, options) {

				var s = response.responseText;

				try {

					eval (s);

				}
				catch (e) {

					Ext.MessageBox.alert ('Ошибка', '<pre>' + e.description + "\n" + s + '</pre>');

				}



			}

		});

		target.doLayout ();

	}

/////////////// TABLE

	function adjust_column_widths (columns, data) {

		for (var i = 0; i < columns.length; i ++) {

			var c = columns [i];

			if (c.width > 0) continue;

			c.width = 1;

			for (var j = 0; j < data.length; j ++) {

				var r = data [j];

				var d = r ['f' + i];

				if (d == null || d == '') continue;

				var w = 7 * d.length;

				if (c.width < w) c.width = w;

			}

		}

	}

	function createGridPanel (data, columns, storeOptions, fields, panelOptions, base_params) {

		adjust_column_widths (columns, data.root);

		storeOptions.fields      = fields;
		storeOptions.root        = 'root';
		storeOptions.autoDestroy = true,
		storeOptions.data        = data;
		storeOptions.url         = '/content';
		storeOptions.baseParams  = base_params;

		panelOptions.store    = new Ext.data.JsonStore (storeOptions);
		panelOptions.colModel = new Ext.grid.ColumnModel ({columns: columns});
		panelOptions.sm       = new Ext.grid.RowSelectionModel ({singleSelect:true});

		if (data.total) {

			panelOptions.bbar     = new Ext.PagingToolbar ({
				store    : panelOptions.store,
				pageSize : data.cnt
			});

		}

		return new Ext.grid.GridPanel (panelOptions);

	}

/////////////// MENU

	function createSubMenuItem (m) {

		if (m == 'BREAK') return new Ext.menu.Separator ({});

		return new Ext.menu.Item ({

			text    : m.label,
			options : m,
			handler : menuButtonHandler

		});

	}

	var menuButtonHandler = function (b, e) {

		var options = b.options;

		if (options.no_page) return;

		if (options.name) {

			var href = '/content/?sid=' + sid + '&type=' + b.options.name;

			href += '&_salt=' + Math.random ();

			nope (href);

		}

	}

	function createMenuButton (mi) {

		var b = new Ext.Button ({

			text    : mi.label.replace ("&", ""),
			options : mi,
			handler : menuButtonHandler

		});

		var ii = mi.items;

		if (!ii) return b;

		var sm = new Ext.menu.Menu ({
			plain: true,
			showSeparator  : false
		});

		for (var j = 0; j < ii.length; j ++) sm.add (createSubMenuItem (ii [j]));

		b.menu = sm;

		return b;

	}

	function clear (container) {

		var items = container.items;

		items.each (function (item) {

			this.remove (item);
			item.destroy ();

		}, items);

	}

	function createMenu (tb, m, showFirstPage) {

		clear (tb);

		for (var i = 0; i < m.length; i ++) {

			if (m [i].off) continue;

			var button = createMenuButton (m [i]);

			tb.add (button);

			if (!showFirstPage) continue;

			menuButtonHandler (button, null);

			showFirstPage = false;

		}

		tb.doLayout ();

	}
	
/////////////// MISC

	var applicationExit = function (e) {

		Ext.MessageBox.confirm (

			'Завершение работы',

			'Вы уверены, что хотите завершить работу с приложением?',

			function (btn) { if (btn == 'yes') window.close () }

		);

	}
