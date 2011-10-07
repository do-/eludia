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

function store (options) {

	return new Ext.data.Store ({
	    model: 'UI.model.' + options.type,
		remoteSort : true,
		proxy: {
		type: 'ajax',
		url: '/handler',
		extraParams: options,
		reader: {
		    type: 'json',
		    root: 'content.' + options.type,
		    totalProperty: 'content.cnt'
		}
	    }
	});	

}