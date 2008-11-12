function nope (a1, a2, a3) {
   try {
	var w = window;
	w.open (a1, a2, a3);
   } catch (e) {}
}