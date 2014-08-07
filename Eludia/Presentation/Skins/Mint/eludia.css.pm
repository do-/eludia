
HTML, BODY {
	FONT-FAMILY: Tahoma, 'MS Sans Serif';
	FONT-WEIGHT: normal;
	FONT-SIZE: 8pt;
	COLOR: #000000;
	background-color: #FFFFFF;
	height:100%;
	margin:0px;
	padding:0px;
}

IFRAME {
	height:100%;
	width:100%;
	display:block;
	margin:0;
	padding:0;
	border: 0;
}


FORM {
	margin: 0px;
}

.tbbg0 {background-color: #b9c5d7; font-size: 1px;}
.tbbg1 {background-color: #6f7681; font-size: 1px;}
.tbbg2 {background-color: #949eac; font-size: 1px;}
.tbbg3 {background-color: #adb8c9; font-size: 1px;}
.tbbg4 {background-color: #c5d2df; font-size: 1px;}
.tbbg5 {background-color: #8c9ab1; font-size: 1px;}
.tbbg6 {background-color: #b9c5d7;}
.tbbg7 {background-color: #454a7c;}
.tbbg8 {background-color: #5d6496;}
.tbbg9 {background-color: #888888;}
.tbbga {background-color: #e5e5e5;}
.tbbgb {background-color: #e4e9ee; font-size: 1px;}

.form-article {

	FONT-SIZE:  12pt;
	FONT-FAMILY: Tahoma, 'MS Sans Serif';
	COLOR: #000000;
	background-color: #FFFFFF;

	padding-left: 10px;
	padding-right: 10px;
	padding-top: 5px;
	padding-bottom: 5px;

	border-color: #d6d3ce;
	border-style:solid;

	border-left-width: 0px;
	border-top-width: 0px;
	border-right-width: 1px;
	border-bottom-width: 1px;
}

.form-active-ellipsis {
	FONT-SIZE: 8pt;
	FONT-FAMILY: Tahoma, 'MS Sans Serif';
	background-color: #ffffff;
}

div.checkboxes {

      	OVERFLOW: auto;

	scrollbar-base-color:#d6d3ce;
	scrollbar-arrow-color:#485f70;
	scrollbar-3dlight-color: #efefef;
	scrollbar-darkshadow-color:#b0b0b0;

}

.filters {
	display: table;
	padding: 0;
	margin: 0;
}
.filters li {
	height: 38px;
	padding-top: 4px;
	padding-left: 10px;
	float: left;
}

ol, ul {list-style: none;}

.nowrap {white-space:nowrap}

.k-grouping-header {
	background-image: url(/i/ken/images/highlight.png);
	background-position: 0px -258px;
	background-color: #efefef;
	border-top-width: 1px;
	border-top-style: solid;
	border-top: 1px solid #C5C5C5;
	border-bottom: 1px solid #C5C5C5;
}

.bgBreadcrumbsIcon{
	display: block;
	float: left;
	position: relative;
	top: 5px;
	width:18px;
	height:18px;
	margin-left: 10px;
	background-repeat: no-repeat;
}
.path {
	font-size: 95%;
	font-weight: bold;
	text-decoration: none;
	color: #000000;
}


.k-pager-wrap{
	border-width: 0px !important;
}

.k-tabstrip-items .k-tab-on-top, .k-tabstrip-items .k-state-active, .k-panelbar .k-tabstrip-items .k-state-active {
	border-bottom: 0px;
	margin-bottom: -1px;
	padding-bottom: 1px;
	font-weight: bold;
}

.k-grid-toolbar {
	border-bottom: 1px solid #C5C5C5;
}

A.k-button {
	line-height: 26px;
}

FORM.toolbar {
	background-color: #cacaca;
}

.menuFonDark.k-header {
       background-color:#A6AFBE;
       border-color: #A6AFBE;
       border-width: 2px;
}
.menuFonDark .k-state-hover{
       background-color:#117cc0 !important;
}
.menuFonDark  .k-state-hover>.k-link:link {
       color: #ffffff;
}
.menuFonDark  .k-link:link {
       color: #263248;
}

div.modal_div  > * {
    -webkit-transform: translateZ(0px);
}

/*jquery ui dialog*/
.ui-dialog .ui-dialog-titlebar {
	background: #b9c5d7 !important;
	color: black !important;
	border: black !important;
}

.ui-dialog .ui-dialog-title {
	font-weight: bold;
	font-size: 8pt;
	font-family: Tahoma, 'MS Sans Serif';
}

.ui-dialog .ui-dialog-titlebar .ui-state-focus {
	border: none !important;
}

.ui-dialog .ui-dialog-titlebar .ui-state-hover {
	border: none !important;
	background-image: none !important;
}

.ui-dialog .ui-dialog-titlebar .ui-dialog-titlebar-close {
	background: url(dialog_close.png) no-repeat center !important;
	background-size: cover !important;
}

.ui-widget-header, .ui-widget-header .ui-icon, .ui-widget-content, .ui-widget-overlay {
	background-image: none !important;
}

/* Calendar styles */


/* The main calendar widget.  DIV containing a table. */

.calendar {
  position: absolute;
  z-index: 200;
  display: none;
  border-top: 2px solid #fff;
  border-right: 2px solid #000;
  border-bottom: 2px solid #000;
  border-left: 2px solid #fff;
  font-size: 11px;
  color: #000;
  cursor: default;
  background: #D7DFE6;
  font-family: tahoma,verdana,sans-serif;
}

.calendar table {
  border-top: 1px solid #000;
  border-right: 1px solid #fff;
  border-bottom: 1px solid #fff;
  border-left: 1px solid #000;
  font-size: 11px;
  color: #000;
  cursor: default;
  background: #D7DFE6;
  font-family: tahoma,verdana,sans-serif;
}

/* Header part -- contains navigation buttons and day names. */

.calendar .button { /* "<<", "<", ">", ">>" buttons have this class */
  text-align: center;
  padding: 1px;
  border-top: 1px solid #fff;
  border-right: 1px solid #000;
  border-bottom: 1px solid #000;
  border-left: 1px solid #fff;
}

.calendar thead .title { /* This holds the current "month, year" */
  font-weight: bold;
  padding: 1px;
  border: 1px solid #000;
  background: #595F95;
  color: #fff;
  text-align: center;
}

.calendar thead .headrow { /* Row <TR> containing navigation buttons */
}

.calendar thead .daynames { /* Row <TR> containing the day names */
}

.calendar thead .name { /* Cells <TD> containing the day names */
  border-bottom: 1px solid #000;
  padding: 2px;
  text-align: center;
  background: #F9F9FF;
}

.calendar thead .weekend { /* How a weekend day name shows in header */
  color: #f00;
}

.calendar thead .hilite { /* How do the buttons in header appear when hover */
  border-top: 2px solid #fff;
  border-right: 2px solid #000;
  border-bottom: 2px solid #000;
  border-left: 2px solid #fff;
  padding: 0px;
  background-color: #e8e5f0;
}

.calendar thead .active { /* Active (pressed) buttons in header */
  padding: 2px 0px 0px 2px;
  border-top: 1px solid #000;
  border-right: 1px solid #fff;
  border-bottom: 1px solid #fff;
  border-left: 1px solid #000;
  background-color: #95A3B9;
}

/* The body part -- contains all the days in month. */

.calendar tbody .day { /* Cells <TD> containing month days dates */
  width: 2em;
  text-align: right;
  padding: 2px 4px 2px 2px;
}

.calendar table .wn {
  padding: 2px 3px 2px 2px;
  border-right: 1px solid #000;
  background: #F9F9FF;
}

.calendar tbody .rowhilite td {
  background: #e8e5f0;
}

.calendar tbody .rowhilite td.wn {
  background: #D7DFE6;
}

.calendar tbody td.hilite { /* Hovered cells <TD> */
  padding: 1px 3px 1px 1px;
  border-top: 1px solid #fff;
  border-right: 1px solid #000;
  border-bottom: 1px solid #000;
  border-left: 1px solid #fff;
}

.calendar tbody td.active { /* Active (pressed) cells <TD> */
  padding: 2px 2px 0px 2px;
  border-top: 1px solid #000;
  border-right: 1px solid #fff;
  border-bottom: 1px solid #fff;
  border-left: 1px solid #000;
}

.calendar tbody td.selected { /* Cell showing selected date */
  font-weight: bold;
  border-top: 1px solid #000;
  border-right: 1px solid #fff;
  border-bottom: 1px solid #fff;
  border-left: 1px solid #000;
  padding: 2px 2px 0px 2px;
  background: #e8e5f0;
}

.calendar tbody td.weekend { /* Cells showing weekend days */
  color: #f00;
}

.calendar tbody td.today { /* Cell showing today date */
  font-weight: bold;
  color: #00f;
}

.calendar tbody .disabled { color: #999; }

.calendar tbody .emptycell { /* Empty cells (the best is to hide them) */
  visibility: hidden;
}

.calendar tbody .emptyrow { /* Empty row (some months need less than 6 rows) */
  display: none;
}

/* The footer part -- status bar and "Close" button */

.calendar tfoot .footrow { /* The <TR> in footer (only one right now) */
}

.calendar tfoot .ttip { /* Tooltip (status bar) cell <TD> */
  padding: 1px;
  border: 1px solid #000;
  background: #595F95;
  color: #fff;
  text-align: center;
}

.calendar tfoot .hilite { /* Hover style for buttons in footer */
  border-top: 1px solid #fff;
  border-right: 1px solid #000;
  border-bottom: 1px solid #000;
  border-left: 1px solid #fff;
  padding: 1px;
  background: #e8e5f0;
}

.calendar tfoot .active { /* Active (pressed) style for buttons in footer */
  padding: 2px 0px 0px 2px;
  border-top: 1px solid #000;
  border-right: 1px solid #fff;
  border-bottom: 1px solid #fff;
  border-left: 1px solid #000;
}

/* Combo boxes (menus that display months/years for direct selection) */

.combo {
  position: absolute;
  display: none;
  width: 4em;
  top: 0px;
  left: 0px;
  cursor: default;
  border-top: 1px solid #fff;
  border-right: 1px solid #000;
  border-bottom: 1px solid #000;
  border-left: 1px solid #fff;
  background: #e8e5f0;
  font-size: smaller;
  padding: 1px;
}

.combo .label,
.combo .label-IEfix {
  text-align: center;
  padding: 1px;
}

.combo .label-IEfix {
  width: 4em;
}

.combo .active {
  background: #95A3B9;
  padding: 0px;
  border-top: 1px solid #000;
  border-right: 1px solid #fff;
  border-bottom: 1px solid #fff;
  border-left: 1px solid #000;
}

.combo .hilite {
  background: #048;
  color: #fea;
}

.calendar td.time {
  border-top: 1px solid #000;
  padding: 1px 0px;
  text-align: center;
  background-color: #F9F9FF;
}

.calendar td.time .hour,
.calendar td.time .minute,
.calendar td.time .ampm {
  padding: 0px 3px 0px 4px;
  border: 1px solid #889;
  font-weight: bold;
  background-color: #fff;
}

.calendar td.time .ampm {
  text-align: center;
}

.calendar td.time .colon {
  padding: 0px 2px 0px 3px;
  font-weight: bold;
}

.calendar td.time span.hilite {
  border-color: #000;
  background-color: #766;
  color: #fff;
}

.calendar td.time span.active {
  border-color: #f00;
  background-color: #000;
  color: #0f0;
}



BODY {
	FONT-FAMILY: Tahoma, 'MS Sans Serif';
	FONT-WEIGHT: normal;
	FONT-SIZE: 8pt;
	COLOR: #000000;
	background-color: #FFFFFF
}

.header_0 {
	FONT-WEIGHT: bold;
	FONT-SIZE: 12pt;
	COLOR: #63a014;
	FONT-FAMILY: 'Trebuchet MS', 'MS Sans Serif';
}

.header_1 {
	FONT-WEIGHT: bold; FONT-SIZE: 10pt; COLOR: #2f3237; FONT-FAMILY: Tahoma, 'MS Sans Serif';
}

.header_2 {
	FONT-WEIGHT: bold; FONT-SIZE: 8pt; COLOR: #ffffff; FONT-FAMILY: Tahoma, 'MS Sans Serif';
}

.header_3 {
	FONT-WEIGHT: bold;
	FONT-SIZE: 10pt;
	COLOR: #2f3237;
	FONT-FAMILY: Tahoma, 'MS Sans Serif';
	background-color: #edf1f5;
}

.header_4 {
	FONT-WEIGHT: normal;
	FONT-SIZE: 25pt;
	COLOR: #484e9d;
	FONT-FAMILY: 'Trebuchet MS', 'MS Sans Serif';
}

.header_5 {
	FONT-WEIGHT: normal;
	FONT-SIZE: 16pt;
	COLOR: #7c7c7c;
	FONT-FAMILY: 'Trebuchet MS', 'MS Sans Serif';
}

.bgr8 {
	FONT-SIZE: 8pt; FONT-FAMILY: Tahoma, 'MS Sans Serif';
}

A.button, A.button:link, A.button:active, A.button:hover, A.button:visited {
	FONT-WEIGHT: normal; FONT-SIZE: 8pt; COLOR: #232324; FONT-FAMILY: Tahoma, 'MS Sans Serif'; TEXT-DECORATION: none
}


a.main-menu, a.main-menu:link, a.main-menu:active, a.main-menu:visited, a.main-menu:hover {
	font-family: Tahoma, 'MS Sans Serif';
	FONT-WEIGHT: bold;
	font-size: 8pt;
	color: #ffffff;
	text-decoration: none;
}

a.tab-0, a.tab-0:link, a.tab-0:active, a.tab-0:visited, a.tab-0:hover {
	font-family: Tahoma, 'MS Sans Serif';
	FONT-WEIGHT: normal;
	font-size: 9pt;
	color: #363638;
	text-decoration: none;
}

a.tab-1, a.tab-1:link, a.tab-1:active, a.tab-1:visited, a.tab-1:hover {
	font-family: Tahoma, 'MS Sans Serif';
	FONT-WEIGHT: normal;
	font-size: 9pt;
	color: #000000;
	text-decoration: none;
}

.txt0 {
	FONT-WEIGHT: bold; FONT-SIZE: 8pt; COLOR: #000000; FONT-FAMILY: Tahoma, 'MS Sans Serif';
}

.txt1 {
	FONT-WEIGHT: normal; FONT-SIZE: 8pt; COLOR: #000000; FONT-FAMILY: Tahoma, 'MS Sans Serif';
}

.txt2 {
	FONT-WEIGHT: normal; FONT-SIZE: 8pt; COLOR: #323233; FONT-FAMILY: Tahoma, 'MS Sans Serif';
}

.bgr0 {
	FONT-SIZE: 8pt; FONT-FAMILY: Tahoma, 'MS Sans Serif'; background-color: #b9c5d7;
}

table.list {
	border-spacing: 1px;
}

.row-cell {
	FONT-FAMILY: Tahoma, 'MS Sans Serif';
	FONT-WEIGHT: normal;
	FONT-SIZE:  10pt;
	COLOR: #000000;
	background-color: #ffffff;
	padding-top: 3px;
	padding-bottom: 2px;

	padding-left: 5px;
	padding-right: 5px;

	border-right:solid 1px #D6D3CE;
	border-bottom:solid 1px #D6D3CE;

	COLOR: #293869;

}
.row-cell-no-scroll {
	FONT-FAMILY: Tahoma, 'MS Sans Serif';
	FONT-WEIGHT: normal;
	FONT-SIZE:  10pt;
	COLOR: #000000;
	background-color: #ffffff;
	padding-top: 3px;
	padding-bottom: 2px;

	padding-left: 5px;
	padding-right: 5px;

	border-right:solid 1px #D6D3CE;
	border-bottom:solid 1px #D6D3CE;

	COLOR: #293869;

	position: relative;
	left: expression(this.parentElement.parentElement.parentElement.parentElement.scrollLeft);

}
.row-cell-transparent-no-scroll {
	FONT-FAMILY: Tahoma, 'MS Sans Serif';
	FONT-WEIGHT: normal;
	FONT-SIZE:  10pt;
	COLOR: #000000;
	padding-top: 3px;
	padding-bottom: 2px;

	padding-left: 5px;
	padding-right: 5px;

	border-right:solid 1px #D6D3CE;
	border-bottom:solid 1px #D6D3CE;

	COLOR: #293869;

	position: relative;
	left: expression(this.parentElement.parentElement.parentElement.parentElement.scrollLeft);

}
.row-cell-transparent {
	FONT-FAMILY: Tahoma, 'MS Sans Serif';
	FONT-WEIGHT: normal;
	FONT-SIZE:  10pt;
	COLOR: #000000;
	padding-top: 3px;
	padding-bottom: 2px;

	padding-left: 5px;
	padding-right: 5px;

	border-right:solid 1px #D6D3CE;
	border-bottom:solid 1px #D6D3CE;

	COLOR: #293869;

}
.row-button {
	FONT-FAMILY: Tahoma, 'MS Sans Serif';
	FONT-WEIGHT: normal;
	FONT-SIZE: 10pt;
	COLOR: #000000;
	background-color: #efefef;
	padding-top: 3px;
	padding-bottom: 2px;

	border-right:solid 1px #D6D3CE;
	border-bottom:solid 1px #D6D3CE;

}
.row-cell-total {
	FONT-FAMILY: Tahoma, 'MS Sans Serif';
	FONT-WEIGHT: bold;
	FONT-SIZE: 10pt;
	COLOR: #000000;
	background-color: #efefef;
	padding-top: 5px;
	padding-bottom: 5px;

}
.row-cell-total-no-scroll {
	FONT-FAMILY: Tahoma, 'MS Sans Serif';
	FONT-WEIGHT: bold;
	FONT-SIZE: 10pt;
	COLOR: #000000;
	background-color: #efefef;
	padding-top: 5px;
	padding-bottom: 5px;

	position: relative;
	left: expression(this.parentElement.parentElement.parentElement.parentElement.scrollLeft);

}

.row-cell-header {
	FONT-FAMILY: Tahoma, 'MS Sans Serif';
	FONT-WEIGHT: bold;
	FONT-SIZE: 10pt;
	COLOR: #000000;
	background-color: #efefef;
	padding-top: 3px;
	padding-bottom: 2px;

	border-right:solid 1px #D6D3CE;
	border-bottom:solid 1px #D6D3CE;
	border-top:solid 1px #D6D3CE;

}
.row-cell-header-no-scroll {
	FONT-FAMILY: Tahoma, 'MS Sans Serif';
	FONT-WEIGHT: bold;
	FONT-SIZE: 10pt;
	COLOR: #000000;
	background-color: #efefef;
	padding-top: 3px;
	padding-bottom: 2px;

	position: relative;
	top: expression(this.parentElement.parentElement.parentElement.parentElement.scrollTop);

	border-right:solid 1px #D6D3CE;
	border-bottom:solid 1px #D6D3CE;
	border-top:solid 1px #D6D3CE;

	position: relative;
	top: expression(this.parentElement.parentElement.parentElement.parentElement.scrollTop);
	left: expression(this.parentElement.parentElement.parentElement.parentElement.scrollLeft);

}

a.row-cell-header-a, a.row-cell-header-a:link, a.row-cell-header-a:hover, a.row-cell-header-a:visited {
	FONT-FAMILY: Tahoma, 'MS Sans Serif';
	FONT-WEIGHT: bold;
	FONT-SIZE: 10pt;
	COLOR: #000000;
	TEXT-DECORATION: none;
}

.row-cell-hilite {
	background-color: #dededc;
}
.row-cell-hilite-no-scroll {

	background-color: #dededc;

	position: relative;
	top: expression(this.parentElement.parentElement.parentElement.parentElement.scrollTop);
	left: expression(this.parentElement.parentElement.parentElement.parentElement.scrollLeft);

}

A.lnk0, A.lnk0:link, A.lnk0:active, A.lnk0:hover, A.lnk0:visited {
	FONT-SIZE: 8pt;
	COLOR: #000000;
	FONT-FAMILY: Tahoma, 'MS Sans Serif';
	TEXT-DECORATION: none;
}

A.lnk4, A.lnk4:link, A.lnk4:active, A.lnk4:hover, A.lnk4:visited {
	FONT-FAMILY: Tahoma, 'MS Sans Serif';
	FONT-WEIGHT: bold;
	FONT-SIZE:  8pt;
	COLOR: #000000;
	TEXT-DECORATION: none
}

A.lnk15 {
	FONT-FAMILY: Tahoma, 'MS Sans Serif';
	FONT-SIZE: 10pt;
	COLOR: #293869;
	TEXT-DECORATION: none;
	border:none;

	background-color: transparent;
}

A.row-cell, A.row-cell:link, A.row-cell:active, A.row-cell:hover, A.row-cell:visited {
	FONT-FAMILY: Tahoma, 'MS Sans Serif';
	FONT-SIZE: 10pt;
	COLOR: #293869;
	TEXT-DECORATION: none;
      	margin: 0px;
      	padding: 0px;
      	border: 0px;
	background-color: transparent;
}

A.row-button, A.row-button:link, A.row-button:active, A.row-button:hover, A.row-button:visited {
	FONT-FAMILY: Tahoma, 'MS Sans Serif';
	FONT-SIZE: 10pt;
	COLOR: #000000;
	TEXT-DECORATION: none;
	border:none;

	background-color: transparent;
}


.form-active-label, .form-passive-label {
	FONT-WEIGHT: bold;
	FONT-SIZE:  8pt;
	FONT-FAMILY: Tahoma, 'MS Sans Serif';
	COLOR: #000000;
	background-color: #ececec;

	padding-left: 10px;
	padding-right: 10px;
	padding-top: 5px;
	padding-bottom: 5px;

	border-color: #d6d3ce;
	border-style:solid;

	border-left-width: 0px;
	border-top-width: 0px;
	border-right-width: 1px;
	border-bottom-width: 1px;
}

.form-active-banner, .form-passive-banner {
	FONT-WEIGHT: bold;
	FONT-SIZE:  8pt;
	FONT-FAMILY: Tahoma, 'MS Sans Serif';
	COLOR: #000000;
	background-color: #ececec;

	padding-left: 10px;
	padding-right: 10px;
	padding-top: 5px;
	padding-bottom: 5px;

	border-color: #d6d3ce;
	border-style:solid;

	border-left-width: 0px;
	border-top-width: 0px;
	border-right-width: 1px;
	border-bottom-width: 1px;
}

.form-deleted-banner {
	FONT-WEIGHT: bold;
	FONT-SIZE:  8pt;
	FONT-FAMILY: Tahoma, 'MS Sans Serif';
	COLOR: #000000;
	background-color: #dadae0;

	padding-left: 10px;
	padding-right: 10px;
	padding-top: 5px;
	padding-bottom: 5px;

	border-color: #d6d3ce;
	border-style:solid;

	border-left-width: 0px;
	border-top-width: 0px;
	border-right-width: 1px;
	border-bottom-width: 1px;
}







.form-deleted-label {
	FONT-WEIGHT: bold;
	FONT-SIZE:  8pt;
	FONT-FAMILY: Tahoma, 'MS Sans Serif';
	COLOR: #000000;
	background-color: #dadae0;
	padding-left: 10px;
	padding-right: 10px;
	padding-top: 5px;
	padding-bottom: 5px;

	border-color: #d6d3ce;
	border-style:solid;

	border-left-width: 0px;
	border-top-width: 0px;
	border-right-width: 1px;
	border-bottom-width: 1px;

}

.form-deleted-inputs {
	FONT-SIZE:  8pt;
	FONT-FAMILY: Tahoma, 'MS Sans Serif';
	background-color: #dadae0;
	padding-left: 5px;
	padding-right: 10px;

	border-color: #d6d3ce;
	border-style:solid;

	border-left-width: 0px;
	border-top-width: 0px;
	border-right-width: 1px;
	border-bottom-width: 1px;

}
.form-deleted-deleted {
	FONT-SIZE:  8pt;
	FONT-FAMILY: Tahoma, 'MS Sans Serif';
	background-color: #dadae0;
	padding-left: 5px;
	padding-right: 10px;

	border: 2px solid black;

}

A.form-deleted-inputs, A.form-deleted-inputs:link, A.form-deleted-inputs:hover, A.form-deleted-inputs:visited {
	FONT-WEIGHT: normal;
	FONT-SIZE:  8pt;
	FONT-FAMILY: Tahoma, 'MS Sans Serif';
	background-color: #dadae0;
	COLOR: #293869;
	TEXT-DECORATION: none;
	padding-left: 0px;
	padding-right: 0px;

	border-color: #d6d3ce;
	border-style:solid;

	border-left-width: 0px;
	border-top-width: 0px;
	border-right-width: 1px;
	border-bottom-width: 1px;

}
A.form-deleted-deleted, A.form-deleted-deleted:link, A.form-deleted-deleted:hover, A.form-deleted-deleted:visited {
	FONT-WEIGHT: normal;
	FONT-SIZE:  8pt;
	FONT-FAMILY: Tahoma, 'MS Sans Serif';
	background-color: #dadae0;
	COLOR: #293869;
	TEXT-DECORATION: none;
	padding-left: 0px;
	padding-right: 0px;

	border: 1px solid black;

}




















.form-inner {
	FONT-SIZE:  8pt;
	FONT-FAMILY: Tahoma, 'MS Sans Serif';
}

.form-active-inputs, .form-passive-inputs {
	FONT-SIZE:  8pt;
	FONT-FAMILY: Tahoma, 'MS Sans Serif';
	background-color: #f9f9ff;
	padding-left: 5px;
	padding-right: 10px;

	border-color: #d6d3ce;
	border-style:solid;

	border-left-width: 0px;
	border-top-width: 0px;
	border-right-width: 1px;
	border-bottom-width: 1px;
}
.form-active-deleted, .form-passive-deleted {
	FONT-SIZE:  8pt;
	FONT-FAMILY: Tahoma, 'MS Sans Serif';
	background-color: #f9f9ff;
	padding-left: 5px;
	padding-right: 10px;

	border: 2px solid black;
}

A.form-active-inputs, A.form-active-inputs:link, A.form-active-inputs:hover, A.form-active-inputs:visited, A.form-passive-inputs, A.form-passive-inputs:link, A.form-passive-inputs:hover, A.form-passive-inputs:visited{
	FONT-SIZE:  8pt;
	FONT-FAMILY: Tahoma, 'MS Sans Serif';
	COLOR: #293869;
	background-color: #f9f9ff;
	padding-left: 0px;
	padding-right: 0px;
	TEXT-DECORATION: none;
	border-style:none;
}
A.form-active-deleted, A.form-active-deleted:link, A.form-active-deleted:hover, A.form-active-deleted:visited, A.form-passive-deleted, A.form-passive-deleted:link, A.form-passive-deleted:hover, A.form-passive-deleted:visited{
	FONT-SIZE:  8pt;
	FONT-FAMILY: Tahoma, 'MS Sans Serif';
	COLOR: #293869;
	background-color: #f9f9ff;
	padding-left: 0px;
	padding-right: 0px;
	TEXT-DECORATION: none;
	border: 2px solid black;
}

INPUT {
	FONT-SIZE: 8pt;
	COLOR: #000000;
	FONT-FAMILY: Tahoma, 'MS Sans Serif';
}

.cbx {
	border: 0px solid;
}

li.toolbar > .cbx{
	margin: 8px;
	vertical-align: middle;
}
span.get_down_the_text_1 {
	display: inline-block;
	margin: 4px;
	vertical-align: middle;
}

SELECT {
	FONT-SIZE: 8pt;
	FONT-FAMILY: Tahoma, 'MS Sans Serif';
}

input.form-active-inputs, select.form-active-inputs, textarea.form-active-inputs {
	FONT-SIZE: 8pt;
	COLOR: #000000;
	background-color: #ffffff;
	FONT-FAMILY: Tahoma, 'MS Sans Serif';
	border: 1px #7f9db9 solid;
	padding-left: 3px;
	padding-right: 3px;
}
input.form-active-deleted, select.form-active-deleted, textarea.form-active-deleted {
	FONT-SIZE: 8pt;
	COLOR: #000000;
	background-color: #ffffff;
	FONT-FAMILY: Tahoma, 'MS Sans Serif';
	border: 1px #7f9db9 solid;
	padding-left: 3px;
	padding-right: 3px;
}

input.form-mandatory-inputs, select.form-mandatory-inputs, textarea.form-mandatory-inputs {
	FONT-SIZE: 8pt;
	COLOR: #000000;
	background-color: #f4ff00;
	FONT-FAMILY: Tahoma, 'MS Sans Serif';
	border: 2px solid black;
	padding-left: 3px;
	padding-right: 3px;
}
input.form-mandatory-deleted, select.form-mandatory-deleted, textarea.form-mandatory-deleted {
	FONT-SIZE: 8pt;
	COLOR: #000000;
	background-color: #f4ff00;
	FONT-FAMILY: Tahoma, 'MS Sans Serif';
	border: 2px solid black;
	padding-left: 3px;
	padding-right: 3px;
}

td.toolbar {
	FONT-SIZE: 8pt;
	COLOR: #000000;
	FONT-FAMILY: Tahoma, 'MS Sans Serif';
	TEXT-DECORATION: none;
	background-color: #b9c5d7;
}

a.hint {
	FONT-WEIGHT: normal;
	FONT-SIZE: 8pt;
	COLOR: #3a6ebb;
	FONT-FAMILY: Tahoma, 'MS Sans Serif';
}











#admin a {color:#000000;text-decoration:none;font-family: Tahoma, Verdana, sans-serif;font-size:8pt;font-style:normal}

#Menu {position:absolute;top:0;left:0;z-index:100;display:none}
#Menu .mm {background-color:#C4C7C9;padding:6px 5px 6px 9px;border-bottom:solid 1px #E2E3E4;}
#Menu .mm0 {background-color:#C4C7C9;padding:6px 5px 0px 9px;}
#Menu a {color:#23385A;text-decoration:none;font-family: Tahoma, Verdana, sans-serif;font-size:8pt;font-style:normal}
#Menu a:hover {color:#23385A;text-decoration:underline;font-family: Tahoma, Verdana, sans-serif;font-size:8pt;font-style:normal}

div.grey-submit a {color:#222323;text-decoration:none;}
div.grey-submit a:hover {color:#222323;text-decoration:underline;}

a.grey-submit {color:#222323;text-decoration:none;FONT-SIZE: 8pt;}
a.grey-submit:hover {color:#222323;text-decoration:underline;FONT-SIZE: 8pt;}

.logon {
	font-family: Tahoma, Verdana, sans-serif;
	font-size:8pt;
	font-style:normal;
	font-weight: normal;
	color:#414141;
	text-decoration: none;
}












/*--------------------------------------------------|
| dTree 2.05 | www.destroydrop.com/javascript/tree/ |
|---------------------------------------------------|
| Copyright (c) 2002-2003 Geir Landrö               |
|--------------------------------------------------*/

.dtree {
	font-family: Verdana, Geneva, Arial, Helvetica, sans-serif;
	font-size: 11px;
	white-space: nowrap;
	float: left;

	PADDING: 3px;
	MARGIN: 0px;

	scrollbar-base-color:#d6d3ce;
	scrollbar-arrow-color:#485f70;
	scrollbar-3dlight-color: #efefef;
	scrollbar-darkshadow-color:#b0b0b0;

}

.dtree img {
	border: 0px;
	vertical-align: middle;
}
.dtree a, a:visited, a:hover {
	color: #333;
	text-decoration: none;
}

.dtree a:active {
	color: #596084;
}

.dtree a.node, .dtree a.nodeSel {
	white-space: nowrap;
	padding: 1px 2px 1px 2px;
}
.dtree a.node:hover, .dtree a.nodeSel:hover {
	color: #333;
	text-decoration: underline;
}
.dtree a.nodeSel {
	background-color: #c0d2ec;
}
.dtree .clip {
	overflow: hidden;
}
