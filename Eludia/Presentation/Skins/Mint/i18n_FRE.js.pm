define(

	['kendo.core.min'],

	function () {

		var kendo = window.kendo;

		window.i18n = {
			F5: "Attention! Vous avez changé le contenu de certains champs d'entrée. Rechargant la page, vous perdrez cette information. Continuer l'opération?"
		};

		kendo.culture("ru-RU");

		return {};
	}
);
