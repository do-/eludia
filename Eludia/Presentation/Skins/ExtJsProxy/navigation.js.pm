var sid;

function ajax_failure (response, options) {

	var s = response.responseText;
	
	try {
		m = Ext.decode (s, true).message;
		
		if (m) s = m;
		
	}
	catch (e) {}
			    			    
	Ext.Msg.show({

		title:'Ошибка',
		msg: s,
		buttons: Ext.Msg.OK,
		icon: Ext.window.MessageBox.ERROR

	});

}

function form_failure (form, action) {
			    
	if (action.failureType === 'client') return;
			    
	var field;
	
	if (action.result.field) field = form.findField (action.result.field);

	if (field) {
			    	
		field.markInvalid (action.result.message);
			    	
	}
	else {

		Ext.Msg.show({

			title:'Ошибка',
			msg: action.result.message,
			buttons: Ext.Msg.OK,
			icon: Ext.window.MessageBox.ERROR

		});	

	}

}

function ajax (url, handler, form) {

	if (/type=_boot/.test (url)) return alert ('Session expired');
	
	if (url.charAt (0) === '/') url = url.substr (1);

	if (sid && !/\bsid=[0-9]/.test (url)) url += ('&sid=' + sid);

	Ext.Ajax.request ({

		url: '/handler' + url,
		
		scope: {handler: handler, form: form},

		callback: function (options, success, response) {

			if (!success) return ajax_failure (response, options);
			
			try {

				var data = Ext.decode (response.responseText, true);
				
				if (data.success === 'redirect') return ajax (data.url, this.handler, this.form);

				if (!data.success) return ajax_failure (response, options);
								
			}
			catch (e) {
			
				return ajax_failure (response, options);
			
			}
				
			return this.handler (data, form);

		}
		
	});

}

function submit (form, handler) {

 	form.submit ({
		url     : '/handler',
		waitMsg : 'Обработка запроса...',
		scope   : {handler: handler, form: form},
		failure : form_failure,
		success : function (form, action) {
				   
			if (action.result.success === 'redirect') {
			
				return ajax (action.result.url, this.handler, this.form);
				
			}

    		}

	});

}