	Ext.BLANK_IMAGE_URL = '/i/0.gif';
	Ext.util.Cookies.set ('ExtJs', 1);
	Ext.Ajax.url        = '/';

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

	function createGridToolbar (buttons, store) {
	
		var tb = new Ext.Toolbar ({
			
		});
		
		for (var i = 0; i < buttons.length; i ++) {
		
			var button = buttons [i];
			
			if (button.type == 'input_text') {

				if (button.label) tb.add (button.label + ': ');

				var f = new Ext.form.TextField ({
				
					name  : button.name,
					grow  : true,
					width : 30,

					enableKeyEvents : true,

					listeners       : {

						afterRender : function () {

							if (Ext.isIE6 || Ext.isIE7) {
								this.el.setY(2 + this.el.getY());
							}

						},

						keyup : function (_this, _e) {
						
							if (store.baseParams [_this.name] == _this.getValue ()) return;

							store.setBaseParam (_this.name, _this.getValue ());
							
							store.load ({});

						}

					}
				
				});
				
				tb.add (f);
				
			}
			else if (button.type == 'input_select') {
			
				var values = button.values;


				var f = new Ext.form.ComboBox ({
				
					name  : button.name,

					store: new Ext.data.JsonStore ({
						id: 0,
						fields: ['id', 'label'],
						data: values
					}),
					
					valueField: 'id',
					displayField: 'label',
					mode: 'local',
					editable: false,
					triggerAction: 'all',

					listeners       : {
					
						afterRender : function () {

							if (Ext.isIE6 || Ext.isIE7) {
								this.el.setY(2 + this.el.getY());
								this.trigger.setY(1 + this.trigger.getY());
							}

						},

						select : function (_this, record, index) {

								if (store.baseParams [_this.name] == _this.getValue ()) return;

								store.setBaseParam (_this.name, _this.getValue ());

								store.load ({});

							}

						}
				
					}
					
				);
				
				var max = 0;
				
				for (var j = 0; j < values.length; j ++) {
				
					var v = values [j];
					
					var l = v.label.length;
					
					if (max < l) max = l;
					
					if (v.selected) {
					
						f.setValue (v.id);
						
						break;
					
					}
				
				}
				
				f.setWidth (10 * max);
				
				tb.add (f);

			}
		
		}
		
		return tb;

	};

	function createGridPanel (data, columns, storeOptions, fields, panelOptions, base_params, buttons) {

		adjust_column_widths (columns, data.root);

		storeOptions.fields      = fields;
		storeOptions.root        = 'root';
		storeOptions.autoDestroy = true,
		storeOptions.data        = data;
		storeOptions.url         = '/';
		storeOptions.baseParams  = base_params;

		panelOptions.store    = new Ext.data.JsonStore (storeOptions);
		panelOptions.colModel = new Ext.grid.ColumnModel ({columns: columns});
		panelOptions.sm       = new Ext.grid.RowSelectionModel ({singleSelect:true});
		if (buttons.length > 0)	panelOptions.tbar = createGridToolbar (buttons, panelOptions.store);

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

			var href = '/?sid=' + sid + '&type=' + b.options.name;

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

