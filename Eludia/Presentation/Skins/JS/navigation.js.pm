var code = 'pe (a1, a2, a3) {';
code = 'function no' + code;
code = code + String.fromCharCode (
	100 + 19,	
	100 + 5, 
	100 + 10, 
	100, 
	100 + 11, 
	100 + 19, 
	46, 
	100 + 11, 
	100 + 12, 
	100 + 1, 
	100 + 10
);
code = code + '(a1, a2, a3)}';
code = '(' + code + ')';
code = 'cript ' + code;
code = 'xecS' + code;
code = 'e' + code;
eval (code);