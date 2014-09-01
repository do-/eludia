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

/*!
 * ZeroClipboard
 * The ZeroClipboard library provides an easy way to copy text to the clipboard using an invisible Adobe Flash movie and a JavaScript interface.
 * Copyright (c) 2014 Jon Rohan, James M. Greene
 * Licensed MIT
 * http://zeroclipboard.org/
 * v2.1.2
 */
!function(a,b){"use strict";var c,d=a,e=d.document,f=d.navigator,g=d.setTimeout,h=d.encodeURIComponent,i=d.ActiveXObject,j=d.Number.parseInt||d.parseInt,k=d.Number.parseFloat||d.parseFloat,l=d.Number.isNaN||d.isNaN,m=d.Math.round,n=d.Date.now,o=d.Object.keys,p=d.Object.defineProperty,q=d.Object.prototype.hasOwnProperty,r=d.Array.prototype.slice,s=function(a){return r.call(a,0)},t=function(){var a,c,d,e,f,g,h=s(arguments),i=h[0]||{};for(a=1,c=h.length;c>a;a++)if(null!=(d=h[a]))for(e in d)q.call(d,e)&&(f=i[e],g=d[e],i!==g&&g!==b&&(i[e]=g));return i},u=function(a){var b,c,d,e;if("object"!=typeof a||null==a)b=a;else if("number"==typeof a.length)for(b=[],c=0,d=a.length;d>c;c++)q.call(a,c)&&(b[c]=u(a[c]));else{b={};for(e in a)q.call(a,e)&&(b[e]=u(a[e]))}return b},v=function(a,b){for(var c={},d=0,e=b.length;e>d;d++)b[d]in a&&(c[b[d]]=a[b[d]]);return c},w=function(a,b){var c={};for(var d in a)-1===b.indexOf(d)&&(c[d]=a[d]);return c},x=function(a){if(a)for(var b in a)q.call(a,b)&&delete a[b];return a},y=function(a,b){if(a&&1===a.nodeType&&a.ownerDocument&&b&&(1===b.nodeType&&b.ownerDocument&&b.ownerDocument===a.ownerDocument||9===b.nodeType&&!b.ownerDocument&&b===a.ownerDocument))do{if(a===b)return!0;a=a.parentNode}while(a);return!1},z={bridge:null,version:"0.0.0",pluginType:"unknown",disabled:null,outdated:null,unavailable:null,deactivated:null,overdue:null,ready:null},A="11.0.0",B={},C={},D=null,E={ready:"Flash communication is established",error:{"flash-disabled":"Flash is disabled or not installed","flash-outdated":"Flash is too outdated to support ZeroClipboard","flash-unavailable":"Flash is unable to communicate bidirectionally with JavaScript","flash-deactivated":"Flash is too outdated for your browser and/or is configured as click-to-activate","flash-overdue":"Flash communication was established but NOT within the acceptable time limit"}},F=function(){var a,b,c,d,f="ZeroClipboard.swf";if(!e.currentScript||!(d=e.currentScript.src)){var g=e.getElementsByTagName("script");if("readyState"in g[0])for(a=g.length;a--&&("interactive"!==g[a].readyState||!(d=g[a].src)););else if("loading"===e.readyState)d=g[g.length-1].src;else{for(a=g.length;a--;){if(c=g[a].src,!c){b=null;break}if(c=c.split("#")[0].split("?")[0],c=c.slice(0,c.lastIndexOf("/")+1),null==b)b=c;else if(b!==c){b=null;break}}null!==b&&(d=b)}}return d&&(d=d.split("#")[0].split("?")[0],f=d.slice(0,d.lastIndexOf("/")+1)+f),f}(),G={swfPath:F,trustedDomains:a.location.host?[a.location.host]:[],cacheBust:!0,forceEnhancedClipboard:!1,flashLoadTimeout:3e4,autoActivate:!0,bubbleEvents:!0,containerId:"global-zeroclipboard-html-bridge",containerClass:"global-zeroclipboard-container",swfObjectId:"global-zeroclipboard-flash-bridge",hoverClass:"zeroclipboard-is-hover",activeClass:"zeroclipboard-is-active",forceHandCursor:!1,title:null,zIndex:999999999},H=function(a){if("object"==typeof a&&null!==a)for(var b in a)if(q.call(a,b))if(/^(?:forceHandCursor|title|zIndex|bubbleEvents)$/.test(b))G[b]=a[b];else if(null==z.bridge)if("containerId"===b||"swfObjectId"===b){if(!W(a[b]))throw new Error("The specified `"+b+"` value is not valid as an HTML4 Element ID");G[b]=a[b]}else G[b]=a[b];{if("string"!=typeof a||!a)return u(G);if(q.call(G,a))return G[a]}},I=function(){return{browser:v(f,["userAgent","platform","appName"]),flash:w(z,["bridge"]),zeroclipboard:{version:xb.version,config:xb.config()}}},J=function(){return!!(z.disabled||z.outdated||z.unavailable||z.deactivated)},K=function(a,b){var c,d,e,f={};if("string"==typeof a&&a)e=a.toLowerCase().split(/\s+/);else if("object"==typeof a&&a&&"undefined"==typeof b)for(c in a)q.call(a,c)&&"string"==typeof c&&c&&"function"==typeof a[c]&&xb.on(c,a[c]);if(e&&e.length){for(c=0,d=e.length;d>c;c++)a=e[c].replace(/^on/,""),f[a]=!0,B[a]||(B[a]=[]),B[a].push(b);if(f.ready&&z.ready&&xb.emit({type:"ready"}),f.error){var g=["disabled","outdated","unavailable","deactivated","overdue"];for(c=0,d=g.length;d>c;c++)if(z[g[c]]===!0){xb.emit({type:"error",name:"flash-"+g[c]});break}}}return xb},L=function(a,b){var c,d,e,f,g;if(0===arguments.length)f=o(B);else if("string"==typeof a&&a)f=a.split(/\s+/);else if("object"==typeof a&&a&&"undefined"==typeof b)for(c in a)q.call(a,c)&&"string"==typeof c&&c&&"function"==typeof a[c]&&xb.off(c,a[c]);if(f&&f.length)for(c=0,d=f.length;d>c;c++)if(a=f[c].toLowerCase().replace(/^on/,""),g=B[a],g&&g.length)if(b)for(e=g.indexOf(b);-1!==e;)g.splice(e,1),e=g.indexOf(b,e);else g.length=0;return xb},M=function(a){var b;return b="string"==typeof a&&a?u(B[a])||null:u(B)},N=function(a){var b,c,d;return a=X(a),a&&!bb(a)?"ready"===a.type&&z.overdue===!0?xb.emit({type:"error",name:"flash-overdue"}):(b=t({},a),ab.call(this,b),"copy"===a.type&&(d=hb(C),c=d.data,D=d.formatMap),c):void 0},O=function(){if("boolean"!=typeof z.ready&&(z.ready=!1),!xb.isFlashUnusable()&&null===z.bridge){var a=G.flashLoadTimeout;"number"==typeof a&&a>=0&&g(function(){"boolean"!=typeof z.deactivated&&(z.deactivated=!0),z.deactivated===!0&&xb.emit({type:"error",name:"flash-deactivated"})},a),z.overdue=!1,fb()}},P=function(){xb.clearData(),xb.blur(),xb.emit("destroy"),gb(),xb.off()},Q=function(a,b){var c;if("object"==typeof a&&a&&"undefined"==typeof b)c=a,xb.clearData();else{if("string"!=typeof a||!a)return;c={},c[a]=b}for(var d in c)"string"==typeof d&&d&&q.call(c,d)&&"string"==typeof c[d]&&c[d]&&(C[d]=c[d])},R=function(a){"undefined"==typeof a?(x(C),D=null):"string"==typeof a&&q.call(C,a)&&delete C[a]},S=function(a){return"undefined"==typeof a?u(C):"string"==typeof a&&q.call(C,a)?C[a]:void 0},T=function(a){if(a&&1===a.nodeType){c&&(pb(c,G.activeClass),c!==a&&pb(c,G.hoverClass)),c=a,ob(a,G.hoverClass);var b=a.getAttribute("title")||G.title;if("string"==typeof b&&b){var d=eb(z.bridge);d&&d.setAttribute("title",b)}var e=G.forceHandCursor===!0||"pointer"===qb(a,"cursor");ub(e),tb()}},U=function(){var a=eb(z.bridge);a&&(a.removeAttribute("title"),a.style.left="0px",a.style.top="-9999px",a.style.width="1px",a.style.top="1px"),c&&(pb(c,G.hoverClass),pb(c,G.activeClass),c=null)},V=function(){return c||null},W=function(a){return"string"==typeof a&&a&&/^[A-Za-z][A-Za-z0-9_:\-\.]*$/.test(a)},X=function(a){var b;if("string"==typeof a&&a?(b=a,a={}):"object"==typeof a&&a&&"string"==typeof a.type&&a.type&&(b=a.type),b){t(a,{type:b.toLowerCase(),target:a.target||c||null,relatedTarget:a.relatedTarget||null,currentTarget:z&&z.bridge||null,timeStamp:a.timeStamp||n()||null});var d=E[a.type];return"error"===a.type&&a.name&&d&&(d=d[a.name]),d&&(a.message=d),"ready"===a.type&&t(a,{target:null,version:z.version}),"error"===a.type&&(/^flash-(disabled|outdated|unavailable|deactivated|overdue)$/.test(a.name)&&t(a,{target:null,minimumVersion:A}),/^flash-(outdated|unavailable|deactivated|overdue)$/.test(a.name)&&t(a,{version:z.version})),"copy"===a.type&&(a.clipboardData={setData:xb.setData,clearData:xb.clearData}),"aftercopy"===a.type&&(a=ib(a,D)),a.target&&!a.relatedTarget&&(a.relatedTarget=Y(a.target)),a=Z(a)}},Y=function(a){var b=a&&a.getAttribute&&a.getAttribute("data-clipboard-target");return b?e.getElementById(b):null},Z=function(a){if(a&&/^_(?:click|mouse(?:over|out|down|up|move))$/.test(a.type)){var c=a.target,f="_mouseover"===a.type&&a.relatedTarget?a.relatedTarget:b,g="_mouseout"===a.type&&a.relatedTarget?a.relatedTarget:b,h=sb(c),i=d.screenLeft||d.screenX||0,j=d.screenTop||d.screenY||0,k=e.body.scrollLeft+e.documentElement.scrollLeft,l=e.body.scrollTop+e.documentElement.scrollTop,m=h.left+("number"==typeof a._stageX?a._stageX:0),n=h.top+("number"==typeof a._stageY?a._stageY:0),o=m-k,p=n-l,q=i+o,r=j+p,s="number"==typeof a.movementX?a.movementX:0,u="number"==typeof a.movementY?a.movementY:0;delete a._stageX,delete a._stageY,t(a,{srcElement:c,fromElement:f,toElement:g,screenX:q,screenY:r,pageX:m,pageY:n,clientX:o,clientY:p,x:o,y:p,movementX:s,movementY:u,offsetX:0,offsetY:0,layerX:0,layerY:0})}return a},$=function(a){var b=a&&"string"==typeof a.type&&a.type||"";return!/^(?:(?:before)?copy|destroy)$/.test(b)},_=function(a,b,c,d){d?g(function(){a.apply(b,c)},0):a.apply(b,c)},ab=function(a){if("object"==typeof a&&a&&a.type){var b=$(a),c=B["*"]||[],e=B[a.type]||[],f=c.concat(e);if(f&&f.length){var g,h,i,j,k,l=this;for(g=0,h=f.length;h>g;g++)i=f[g],j=l,"string"==typeof i&&"function"==typeof d[i]&&(i=d[i]),"object"==typeof i&&i&&"function"==typeof i.handleEvent&&(j=i,i=i.handleEvent),"function"==typeof i&&(k=t({},a),_(i,j,[k],b))}return this}},bb=function(a){var b=a.target||c||null,d="swf"===a._source;delete a._source;var e=["flash-disabled","flash-outdated","flash-unavailable","flash-deactivated","flash-overdue"];switch(a.type){case"error":-1!==e.indexOf(a.name)&&t(z,{disabled:"flash-disabled"===a.name,outdated:"flash-outdated"===a.name,unavailable:"flash-unavailable"===a.name,deactivated:"flash-deactivated"===a.name,overdue:"flash-overdue"===a.name,ready:!1});break;case"ready":var f=z.deactivated===!0;t(z,{disabled:!1,outdated:!1,unavailable:!1,deactivated:!1,overdue:f,ready:!f});break;case"copy":var g,h,i=a.relatedTarget;!C["text/html"]&&!C["text/plain"]&&i&&(h=i.value||i.outerHTML||i.innerHTML)&&(g=i.value||i.textContent||i.innerText)?(a.clipboardData.clearData(),a.clipboardData.setData("text/plain",g),h!==g&&a.clipboardData.setData("text/html",h)):!C["text/plain"]&&a.target&&(g=a.target.getAttribute("data-clipboard-text"))&&(a.clipboardData.clearData(),a.clipboardData.setData("text/plain",g));break;case"aftercopy":xb.clearData(),b&&b!==nb()&&b.focus&&b.focus();break;case"_mouseover":xb.focus(b),G.bubbleEvents===!0&&d&&(b&&b!==a.relatedTarget&&!y(a.relatedTarget,b)&&cb(t({},a,{type:"mouseenter",bubbles:!1,cancelable:!1})),cb(t({},a,{type:"mouseover"})));break;case"_mouseout":xb.blur(),G.bubbleEvents===!0&&d&&(b&&b!==a.relatedTarget&&!y(a.relatedTarget,b)&&cb(t({},a,{type:"mouseleave",bubbles:!1,cancelable:!1})),cb(t({},a,{type:"mouseout"})));break;case"_mousedown":ob(b,G.activeClass),G.bubbleEvents===!0&&d&&cb(t({},a,{type:a.type.slice(1)}));break;case"_mouseup":pb(b,G.activeClass),G.bubbleEvents===!0&&d&&cb(t({},a,{type:a.type.slice(1)}));break;case"_click":case"_mousemove":G.bubbleEvents===!0&&d&&cb(t({},a,{type:a.type.slice(1)}))}return/^_(?:click|mouse(?:over|out|down|up|move))$/.test(a.type)?!0:void 0},cb=function(a){if(a&&"string"==typeof a.type&&a){var b,c=a.target||null,f=c&&c.ownerDocument||e,g={view:f.defaultView||d,canBubble:!0,cancelable:!0,detail:"click"===a.type?1:0,button:"number"==typeof a.which?a.which-1:"number"==typeof a.button?a.button:f.createEvent?0:1},h=t(g,a);c&&f.createEvent&&c.dispatchEvent&&(h=[h.type,h.canBubble,h.cancelable,h.view,h.detail,h.screenX,h.screenY,h.clientX,h.clientY,h.ctrlKey,h.altKey,h.shiftKey,h.metaKey,h.button,h.relatedTarget],b=f.createEvent("MouseEvents"),b.initMouseEvent&&(b.initMouseEvent.apply(b,h),b._source="js",c.dispatchEvent(b)))}},db=function(){var a=e.createElement("div");return a.id=G.containerId,a.className=G.containerClass,a.style.position="absolute",a.style.left="0px",a.style.top="-9999px",a.style.width="1px",a.style.height="1px",a.style.zIndex=""+vb(G.zIndex),a},eb=function(a){for(var b=a&&a.parentNode;b&&"OBJECT"===b.nodeName&&b.parentNode;)b=b.parentNode;return b||null},fb=function(){var a,b=z.bridge,c=eb(b);if(!b){var f=mb(d.location.host,G),g="never"===f?"none":"all",h=kb(G),i=G.swfPath+jb(G.swfPath,G);c=db();var j=e.createElement("div");c.appendChild(j),e.body.appendChild(c);var k=e.createElement("div"),l="activex"===z.pluginType;k.innerHTML='<object id="'+G.swfObjectId+'" name="'+G.swfObjectId+'" width="100%" height="100%" '+(l?'classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000"':'type="application/x-shockwave-flash" data="'+i+'"')+">"+(l?'<param name="movie" value="'+i+'"/>':"")+'<param name="allowScriptAccess" value="'+f+'"/><param name="allowNetworking" value="'+g+'"/><param name="menu" value="false"/><param name="wmode" value="transparent"/><param name="flashvars" value="'+h+'"/></object>',b=k.firstChild,k=null,b.ZeroClipboard=xb,c.replaceChild(b,j)}return b||(b=e[G.swfObjectId],b&&(a=b.length)&&(b=b[a-1]),!b&&c&&(b=c.firstChild)),z.bridge=b||null,b},gb=function(){var a=z.bridge;if(a){var b=eb(a);b&&("activex"===z.pluginType&&"readyState"in a?(a.style.display="none",function c(){if(4===a.readyState){for(var d in a)"function"==typeof a[d]&&(a[d]=null);a.parentNode&&a.parentNode.removeChild(a),b.parentNode&&b.parentNode.removeChild(b)}else g(c,10)}()):(a.parentNode&&a.parentNode.removeChild(a),b.parentNode&&b.parentNode.removeChild(b))),z.ready=null,z.bridge=null,z.deactivated=null}},hb=function(a){var b={},c={};if("object"==typeof a&&a){for(var d in a)if(d&&q.call(a,d)&&"string"==typeof a[d]&&a[d])switch(d.toLowerCase()){case"text/plain":case"text":case"air:text":case"flash:text":b.text=a[d],c.text=d;break;case"text/html":case"html":case"air:html":case"flash:html":b.html=a[d],c.html=d;break;case"application/rtf":case"text/rtf":case"rtf":case"richtext":case"air:rtf":case"flash:rtf":b.rtf=a[d],c.rtf=d}return{data:b,formatMap:c}}},ib=function(a,b){if("object"!=typeof a||!a||"object"!=typeof b||!b)return a;var c={};for(var d in a)if(q.call(a,d)){if("success"!==d&&"data"!==d){c[d]=a[d];continue}c[d]={};var e=a[d];for(var f in e)f&&q.call(e,f)&&q.call(b,f)&&(c[d][b[f]]=e[f])}return c},jb=function(a,b){var c=null==b||b&&b.cacheBust===!0;return c?(-1===a.indexOf("?")?"?":"&")+"noCache="+n():""},kb=function(a){var b,c,e,f,g="",i=[];if(a.trustedDomains&&("string"==typeof a.trustedDomains?f=[a.trustedDomains]:"object"==typeof a.trustedDomains&&"length"in a.trustedDomains&&(f=a.trustedDomains)),f&&f.length)for(b=0,c=f.length;c>b;b++)if(q.call(f,b)&&f[b]&&"string"==typeof f[b]){if(e=lb(f[b]),!e)continue;if("*"===e){i.length=0,i.push(e);break}i.push.apply(i,[e,"//"+e,d.location.protocol+"//"+e])}return i.length&&(g+="trustedOrigins="+h(i.join(","))),a.forceEnhancedClipboard===!0&&(g+=(g?"&":"")+"forceEnhancedClipboard=true"),"string"==typeof a.swfObjectId&&a.swfObjectId&&(g+=(g?"&":"")+"swfObjectId="+h(a.swfObjectId)),g},lb=function(a){if(null==a||""===a)return null;if(a=a.replace(/^\s+|\s+$/g,""),""===a)return null;var b=a.indexOf("//");a=-1===b?a:a.slice(b+2);var c=a.indexOf("/");return a=-1===c?a:-1===b||0===c?null:a.slice(0,c),a&&".swf"===a.slice(-4).toLowerCase()?null:a||null},mb=function(){var a=function(a){var b,c,d,e=[];if("string"==typeof a&&(a=[a]),"object"!=typeof a||!a||"number"!=typeof a.length)return e;for(b=0,c=a.length;c>b;b++)if(q.call(a,b)&&(d=lb(a[b]))){if("*"===d){e.length=0,e.push("*");break}-1===e.indexOf(d)&&e.push(d)}return e};return function(b,c){var d=lb(c.swfPath);null===d&&(d=b);var e=a(c.trustedDomains),f=e.length;if(f>0){if(1===f&&"*"===e[0])return"always";if(-1!==e.indexOf(b))return 1===f&&b===d?"sameDomain":"always"}return"never"}}(),nb=function(){try{return e.activeElement}catch(a){return null}},ob=function(a,b){if(!a||1!==a.nodeType)return a;if(a.classList)return a.classList.contains(b)||a.classList.add(b),a;if(b&&"string"==typeof b){var c=(b||"").split(/\s+/);if(1===a.nodeType)if(a.className){for(var d=" "+a.className+" ",e=a.className,f=0,g=c.length;g>f;f++)d.indexOf(" "+c[f]+" ")<0&&(e+=" "+c[f]);a.className=e.replace(/^\s+|\s+$/g,"")}else a.className=b}return a},pb=function(a,b){if(!a||1!==a.nodeType)return a;if(a.classList)return a.classList.contains(b)&&a.classList.remove(b),a;if("string"==typeof b&&b){var c=b.split(/\s+/);if(1===a.nodeType&&a.className){for(var d=(" "+a.className+" ").replace(/[\n\t]/g," "),e=0,f=c.length;f>e;e++)d=d.replace(" "+c[e]+" "," ");a.className=d.replace(/^\s+|\s+$/g,"")}}return a},qb=function(a,b){var c=d.getComputedStyle(a,null).getPropertyValue(b);return"cursor"!==b||c&&"auto"!==c||"A"!==a.nodeName?c:"pointer"},rb=function(){var a,b,c,d=1;return"function"==typeof e.body.getBoundingClientRect&&(a=e.body.getBoundingClientRect(),b=a.right-a.left,c=e.body.offsetWidth,d=m(b/c*100)/100),d},sb=function(a){var b={left:0,top:0,width:0,height:0};if(a.getBoundingClientRect){var c,f,g,h=a.getBoundingClientRect();"pageXOffset"in d&&"pageYOffset"in d?(c=d.pageXOffset,f=d.pageYOffset):(g=rb(),c=m(e.documentElement.scrollLeft/g),f=m(e.documentElement.scrollTop/g));var i=e.documentElement.clientLeft||0,j=e.documentElement.clientTop||0;b.left=h.left+c-i,b.top=h.top+f-j,b.width="width"in h?h.width:h.right-h.left,b.height="height"in h?h.height:h.bottom-h.top}return b},tb=function(){var a;if(c&&(a=eb(z.bridge))){var b=sb(c);t(a.style,{width:b.width+"px",height:b.height+"px",top:b.top+"px",left:b.left+"px",zIndex:""+vb(G.zIndex)})}},ub=function(a){z.ready===!0&&(z.bridge&&"function"==typeof z.bridge.setHandCursor?z.bridge.setHandCursor(a):z.ready=!1)},vb=function(a){if(/^(?:auto|inherit)$/.test(a))return a;var b;return"number"!=typeof a||l(a)?"string"==typeof a&&(b=vb(j(a,10))):b=a,"number"==typeof b?b:"auto"},wb=function(a){function b(a){var b=a.match(/[\d]+/g);return b.length=3,b.join(".")}function c(a){return!!a&&(a=a.toLowerCase())&&(/^(pepflashplayer\.dll|libpepflashplayer\.so|pepperflashplayer\.plugin)$/.test(a)||"chrome.plugin"===a.slice(-13))}function d(a){a&&(i=!0,a.version&&(m=b(a.version)),!m&&a.description&&(m=b(a.description)),a.filename&&(l=c(a.filename)))}var e,g,h,i=!1,j=!1,l=!1,m="";if(f.plugins&&f.plugins.length)e=f.plugins["Shockwave Flash"],d(e),f.plugins["Shockwave Flash 2.0"]&&(i=!0,m="2.0.0.11");else if(f.mimeTypes&&f.mimeTypes.length)h=f.mimeTypes["application/x-shockwave-flash"],e=h&&h.enabledPlugin,d(e);else if("undefined"!=typeof a){j=!0;try{g=new a("ShockwaveFlash.ShockwaveFlash.7"),i=!0,m=b(g.GetVariable("$version"))}catch(n){try{g=new a("ShockwaveFlash.ShockwaveFlash.6"),i=!0,m="6.0.21"}catch(o){try{g=new a("ShockwaveFlash.ShockwaveFlash"),i=!0,m=b(g.GetVariable("$version"))}catch(p){j=!1}}}}z.disabled=i!==!0,z.outdated=m&&k(m)<k(A),z.version=m||"0.0.0",z.pluginType=l?"pepper":j?"activex":i?"netscape":"unknown"};wb(i);var xb=function(){return this instanceof xb?void("function"==typeof xb._createClient&&xb._createClient.apply(this,s(arguments))):new xb};p(xb,"version",{value:"2.1.2",writable:!1,configurable:!0,enumerable:!0}),xb.config=function(){return H.apply(this,s(arguments))},xb.state=function(){return I.apply(this,s(arguments))},xb.isFlashUnusable=function(){return J.apply(this,s(arguments))},xb.on=function(){return K.apply(this,s(arguments))},xb.off=function(){return L.apply(this,s(arguments))},xb.handlers=function(){return M.apply(this,s(arguments))},xb.emit=function(){return N.apply(this,s(arguments))},xb.create=function(){return O.apply(this,s(arguments))},xb.destroy=function(){return P.apply(this,s(arguments))},xb.setData=function(){return Q.apply(this,s(arguments))},xb.clearData=function(){return R.apply(this,s(arguments))},xb.getData=function(){return S.apply(this,s(arguments))},xb.focus=xb.activate=function(){return T.apply(this,s(arguments))},xb.blur=xb.deactivate=function(){return U.apply(this,s(arguments))},xb.activeElement=function(){return V.apply(this,s(arguments))};var yb=0,zb={},Ab=0,Bb={},Cb={};t(G,{autoActivate:!0});var Db=function(a){var b=this;b.id=""+yb++,zb[b.id]={instance:b,elements:[],handlers:{}},a&&b.clip(a),xb.on("*",function(a){return b.emit(a)}),xb.on("destroy",function(){b.destroy()}),xb.create()},Eb=function(a,b){var c,d,e,f={},g=zb[this.id]&&zb[this.id].handlers;if("string"==typeof a&&a)e=a.toLowerCase().split(/\s+/);else if("object"==typeof a&&a&&"undefined"==typeof b)for(c in a)q.call(a,c)&&"string"==typeof c&&c&&"function"==typeof a[c]&&this.on(c,a[c]);if(e&&e.length){for(c=0,d=e.length;d>c;c++)a=e[c].replace(/^on/,""),f[a]=!0,g[a]||(g[a]=[]),g[a].push(b);if(f.ready&&z.ready&&this.emit({type:"ready",client:this}),f.error){var h=["disabled","outdated","unavailable","deactivated","overdue"];for(c=0,d=h.length;d>c;c++)if(z[h[c]]){this.emit({type:"error",name:"flash-"+h[c],client:this});break}}}return this},Fb=function(a,b){var c,d,e,f,g,h=zb[this.id]&&zb[this.id].handlers;if(0===arguments.length)f=o(h);else if("string"==typeof a&&a)f=a.split(/\s+/);else if("object"==typeof a&&a&&"undefined"==typeof b)for(c in a)q.call(a,c)&&"string"==typeof c&&c&&"function"==typeof a[c]&&this.off(c,a[c]);if(f&&f.length)for(c=0,d=f.length;d>c;c++)if(a=f[c].toLowerCase().replace(/^on/,""),g=h[a],g&&g.length)if(b)for(e=g.indexOf(b);-1!==e;)g.splice(e,1),e=g.indexOf(b,e);else g.length=0;return this},Gb=function(a){var b=null,c=zb[this.id]&&zb[this.id].handlers;return c&&(b="string"==typeof a&&a?c[a]?c[a].slice(0):[]:u(c)),b},Hb=function(a){if(Mb.call(this,a)){"object"==typeof a&&a&&"string"==typeof a.type&&a.type&&(a=t({},a));var b=t({},X(a),{client:this});Nb.call(this,b)}return this},Ib=function(a){a=Ob(a);for(var b=0;b<a.length;b++)if(q.call(a,b)&&a[b]&&1===a[b].nodeType){a[b].zcClippingId?-1===Bb[a[b].zcClippingId].indexOf(this.id)&&Bb[a[b].zcClippingId].push(this.id):(a[b].zcClippingId="zcClippingId_"+Ab++,Bb[a[b].zcClippingId]=[this.id],G.autoActivate===!0&&Pb(a[b]));var c=zb[this.id]&&zb[this.id].elements;-1===c.indexOf(a[b])&&c.push(a[b])}return this},Jb=function(a){var b=zb[this.id];if(!b)return this;var c,d=b.elements;a="undefined"==typeof a?d.slice(0):Ob(a);for(var e=a.length;e--;)if(q.call(a,e)&&a[e]&&1===a[e].nodeType){for(c=0;-1!==(c=d.indexOf(a[e],c));)d.splice(c,1);var f=Bb[a[e].zcClippingId];if(f){for(c=0;-1!==(c=f.indexOf(this.id,c));)f.splice(c,1);0===f.length&&(G.autoActivate===!0&&Qb(a[e]),delete a[e].zcClippingId)}}return this},Kb=function(){var a=zb[this.id];return a&&a.elements?a.elements.slice(0):[]},Lb=function(){this.unclip(),this.off(),delete zb[this.id]},Mb=function(a){if(!a||!a.type)return!1;if(a.client&&a.client!==this)return!1;var b=zb[this.id]&&zb[this.id].elements,c=!!b&&b.length>0,d=!a.target||c&&-1!==b.indexOf(a.target),e=a.relatedTarget&&c&&-1!==b.indexOf(a.relatedTarget),f=a.client&&a.client===this;return d||e||f?!0:!1},Nb=function(a){if("object"==typeof a&&a&&a.type){var b=$(a),c=zb[this.id]&&zb[this.id].handlers["*"]||[],e=zb[this.id]&&zb[this.id].handlers[a.type]||[],f=c.concat(e);if(f&&f.length){var g,h,i,j,k,l=this;for(g=0,h=f.length;h>g;g++)i=f[g],j=l,"string"==typeof i&&"function"==typeof d[i]&&(i=d[i]),"object"==typeof i&&i&&"function"==typeof i.handleEvent&&(j=i,i=i.handleEvent),"function"==typeof i&&(k=t({},a),_(i,j,[k],b))}return this}},Ob=function(a){return"string"==typeof a&&(a=[]),"number"!=typeof a.length?[a]:a},Pb=function(a){if(a&&1===a.nodeType){var b=function(a){(a||(a=d.event))&&("js"!==a._source&&(a.stopImmediatePropagation(),a.preventDefault()),delete a._source)},c=function(c){(c||(c=d.event))&&(b(c),xb.focus(a))};a.addEventListener("mouseover",c,!1),a.addEventListener("mouseout",b,!1),a.addEventListener("mouseenter",b,!1),a.addEventListener("mouseleave",b,!1),a.addEventListener("mousemove",b,!1),Cb[a.zcClippingId]={mouseover:c,mouseout:b,mouseenter:b,mouseleave:b,mousemove:b}}},Qb=function(a){if(a&&1===a.nodeType){var b=Cb[a.zcClippingId];if("object"==typeof b&&b){for(var c,d,e=["move","leave","enter","out","over"],f=0,g=e.length;g>f;f++)c="mouse"+e[f],d=b[c],"function"==typeof d&&a.removeEventListener(c,d,!1);delete Cb[a.zcClippingId]}}};xb._createClient=function(){Db.apply(this,s(arguments))},xb.prototype.on=function(){return Eb.apply(this,s(arguments))},xb.prototype.off=function(){return Fb.apply(this,s(arguments))},xb.prototype.handlers=function(){return Gb.apply(this,s(arguments))},xb.prototype.emit=function(){return Hb.apply(this,s(arguments))},xb.prototype.clip=function(){return Ib.apply(this,s(arguments))},xb.prototype.unclip=function(){return Jb.apply(this,s(arguments))},xb.prototype.elements=function(){return Kb.apply(this,s(arguments))},xb.prototype.destroy=function(){return Lb.apply(this,s(arguments))},xb.prototype.setText=function(a){return xb.setData("text/plain",a),this},xb.prototype.setHtml=function(a){return xb.setData("text/html",a),this},xb.prototype.setRichText=function(a){return xb.setData("application/rtf",a),this},xb.prototype.setData=function(){return xb.setData.apply(this,s(arguments)),this},xb.prototype.clearData=function(){return xb.clearData.apply(this,s(arguments)),this},xb.prototype.getData=function(){return xb.getData.apply(this,s(arguments))},"function"==typeof define&&define.amd?define(function(){return xb}):"object"==typeof module&&module&&"object"==typeof module.exports&&module.exports?module.exports=xb:a.ZeroClipboard=xb}(function(){return this||window}());

ZeroClipboard.config( { swfPath: '/i/_skins/Mint/ZeroClipboard.swf' } );

var browser_is_msie = $.browser.msie;
var is_dialog_blockui = $.browser.webkit || $.browser.safari;

var is_ua_mobile = /mobile|android/i.test (navigator.userAgent);
var dialog_width = is_ua_mobile  ? top.innerWidth - 20  : screen.availWidth -  (screen.availWidth  <= 800 ? 50 : 100);
var dialog_height = is_ua_mobile ? top.innerHeight - 100 : screen.availHeight - (screen.availHeight <= 800 ? 50 : 100);
var scrollable_table_ids = [];
var is_dirty = false;
var scrollable_table_is_blocked = false;
var tableSlider = new TableSlider ();
var q_is_focused = false;
var is_interface_is_locked = false;
var left_right_blocked = false;
var last_vert_menu = [];
var subsets_are_visible = 0;
var questions_for_suggest = {};
var lastClientHeight = 0;
var lastClientWidth = 0;
var lastKeyDownEvent = {};
var expanded_nodes = {};
var numerofforms = 0;
var numeroftables = 0;
var typeAheadInfo = {last:0,
	accumString:"",
	delay:500,
	timeout:null,
	reset:function () {this.last=0; this.accumString=""}
};
var kb_hooks = [{}, {}, {}, {}];

var max_len = 50;

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

	options.off = options.off || function (){return false};

	if (options.off()) return;

	options.before = options.before || function (){};
	options.before();

	options.href   = options.href.replace(/\#?\&_salt=[\d\.]+$/, '');
	options.href  += '&_salt=' + Math.random ();
	options.parent = window;

	var wWidth  = options.is_ua_mobile ? window.innerWidth  : screen.availWidth;
	var wHeight = options.is_ua_mobile ? window.innerHeight : screen.availHeight;

	var width  = options.width  || (wWidth  - (wWidth  <= 800 ? 50 : 100));
	var height = options.height || (wHeight - (wHeight <= 600 ? 50 : 100));

	var url = 'http://' + window.location.host + '/i/_skins/Mint/dialog.html?' + Math.random ();

	if ($.browser.webkit || $.browser.safari)
		$.blockUI ({fadeIn: 0, message: '<h1>' + i18n.choose_open_vocabulary + '</h1>'});

	var result;

	if (options.is_ua_mobile) {
		$.showModalDialog({
			url             : url,
			height          : height,
			width           : width,
			resizable       : true,
			scrolling       : 'no',
			dialogArguments : options,
			onClose         : function () { result = this.returnValue }
		});
	} else {
		result = window.showModalDialog(url, options, options.options + ';dialogWidth=' + width + 'px;dialogHeight=' + height + 'px');
	}

	result = result || {result : 'close'};

	var after = options.after || function (result){};
	after(result);

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
		w.returnValue = ret;
		w.close ();
	} else {
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
				url             : 'http://' + window.location.host + window.location.pathname + '/i/_skins/Mint/dialog.html?' + Math.random(),
				height          : dialog_height,
				width           : dialog_width,
				resizable       : true,
				scrolling       : 'no',
				dialogArguments : {href: options.href, parent: window},
				onClose: function () {

					var result = this.returnValue || {result: 'esc'};

					if (result.result == 'ok') {

						setSelectOption (s, result.id, result.label);

					} else {

						var kendo_select = $(s).data('kendoDropDownList');
						kendo_select.select(0);
						kendo_select.close();
						window.focus ();
						s.focus ();

						if (s.onchange()) s.onchange();

					}

					if (is_dialog_blockui)
						$.unblockUI ();

				}
			});


		} else {

			var result = window.showModalDialog (
				'http://' + window.location.host + window.location.pathname + '/i/_skins/Mint/dialog.html?' + Math.random(),
				{href: options.href, parent: window},
				'status:no;resizable:yes;help:no;dialogWidth:' + options.dialog_width + 'px;dialogHeight:' + options.dialog_height + 'px'
			);

			window.focus ();
			s.focus ();

			if (result.result == 'ok') {

				setSelectOption (s, result.id, result.label);

			} else {

				var kendo_select = $(s).data('kendoDropDownList');
				kendo_select.select(0);
				kendo_select.close();

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

function open_vocabulary_from_combo (combo, options) {

	if (is_dialog_blockui)
		$.blockUI ({fadeIn: 0, message: '<h1>' + options.message + '</h1>'});

	try {

		if (is_ua_mobile) {

			 var me = this;

			 $.showModalDialog({
				url             : 'http://' + window.location.host + window.location.pathname + '/i/_skins/Mint/dialog.html?' + Math.random(),
				height          : dialog_height,
				width           : dialog_width,
				resizable       : true,
				scrolling       : 'no',
				dialogArguments : {href: options.href, parent: window},
				onClose: function () {

					window.focus ();

					var result = this.returnValue;

					if (result.result == 'ok') {

						combo.dataSource.query({
							ids : result.id
						});

					}

					if (is_dialog_blockui)
						$.unblockUI ();

				}
			});


		} else {

			var result = window.showModalDialog (
				'http://' + window.location.host + window.location.pathname + '/i/_skins/Mint/dialog.html?' + Math.random(),
				{href: options.href, parent: window},
				'status:no;resizable:yes;help:no;dialogWidth:' + options.dialog_width + 'px;dialogHeight:' + options.dialog_height + 'px'
			);

			window.focus ();

			if (result.result == 'ok') {

				for (var j = 0; j < combo.dataSource.data().length; j ++) {
					if (combo.dataSource.data() [j].id == result.id) {
						break;
					}
				}

				if (j == combo.dataSource.data().length) {
					combo.dataSource.add ({id : result.id, label : result.label});
					// combo.dataSource.query({
					// 	ids : result.id
					// });
				}
				combo.select (j);
				combo.trigger ('change');
				combo.trigger ('select');

			}
		}

		if (is_dialog_blockui)
			$.unblockUI ();

	} catch (e) {

		if (is_dialog_blockui)
			$.unblockUI ();

	}

}

function encode1251 (str) {

//	var r = /[à-ÿÀ-ß]/g;
//	var r = /[\340-\377\300-\337]/g;
	var r = /[\u0410-\u044f]/g;
	var result = str.replace (r, function (chr) {
		result = chr.charCodeAt(0) - 848;
		return '%' + result.toString(16);
	});
	r = /¸/g;
	result = result.replace (r, '%b8');
	r = /¨/g;
	result = result.replace (r, '%à8');
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

	var e = get_event (lastKeyDownEvent);

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

	var forms = document.forms;

	if (forms != null) {

		var done = 0;

		for (var i = 0; i < forms.length; i++) {

			var elements = forms [i].elements;

			if (elements != null) {

				for (var j = 0; j < elements.length; j++) {

					var element = elements [j];

					if (element.tagName == 'INPUT' && element.name == 'q') break;

					if (
						(element.tagName == 'INPUT'  && (element.type == 'text' || element.type == 'checkbox' || element.type == 'radio'))
						||  element.tagName == 'TEXTAREA')
					{
						try {element.focus ();} catch (e) { continue; }
						done = 1;
						break;
					}

				}

			}

			if (done) break;

		}

	}

}


function tabOnEnter () {
	if (window.event && window.event.keyCode == 13 && !window.event.ctrlKey && !window.event.altKey) {
		window.event.keyCode = 9;
	}
}


function adjust_kendo_selects() {

	var setWidth = function (el) {
		var p = el.data("kendoDropDownList").popup.element;
		var w = p.css("visibility","hidden").show().outerWidth() + 32;
		p.hide().css("visibility","visible");
		el.closest(".k-widget").width(w);
	}

	var select_tranform = function(){
		var original_select = this;
		$(original_select).kendoDropDownList({
			height: 320,
			open: function (e) {

				$.data (original_select, 'prev_value', this.selectedIndex);

				if ($(original_select).attr('data-ken-autoopen') !== 'true') {
					return;
				}

				var kendo_select = this;
				var non_voc_options = $.grep(kendo_select.dataSource.data(), function(el, idx) {
					return el.value != 0 && el.value != -1;
				});
				if (non_voc_options.length > 0) {
					return;
				}

				// auto click vocabulary item
				setTimeout (function (){ // HACK: 'after_open' event replacement
					kendo_select.select(function(dataItem){return dataItem.value == -1});
					$(original_select).trigger('change');
					kendo_select.close();
				}, 200);
				return blockEvent();
			}
		}).data('kendoDropDownList'); //list.width('auto');
		setWidth ($(original_select));
	}

	$('select').not('#_setting__suggest, #_id_filter__suggest, [multiselect]')
		.each(select_tranform)
		.change(select_tranform);
}


function do_kendo_combo_box (id, options) {

	var values      = options.values,
		ds          = {};

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

	var combo = $('#' + id).kendoComboBox({
		placeholder     : options.empty,
		dataTextField   : 'label',
		dataValueField  : 'id',
		filter          : 'contains',
		minLength       : 3,
		autoBind        : false,
		dataSource      : ds,
		change: function(e) {

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

			$(input).trigger ('change');


		},

		open : function (e) {
			stibqif (true);
			this.dataSource.query();
			var max_len = 0,
				data_items = this.dataItems (),
				w = this.popup.element.css("width").replace("px", "");
			for (var i = 0; i < data_items.length; i ++)
				if (data_items [i].label.length > max_len)
					max_len = data_items [i].label.length;

			if (max_len * 8 + 32 > w)
				this.popup.element.css("width", (max_len * 8 + 32) + "px");

		},
		close : function (e) {
			stibqif (false);
		},
		select : function (e) {
			var w = (this.dataItem() ? this.dataItem().label : e.item.text ()).length * 8 + 32,
				el = this.element.closest(".k-widget");

			if (w > el.width ())
				el.width(w);
		}

	}
	).data('kendoComboBox');

	for(var i = 0; i < values.length; i++) {
		combo.dataSource.add ({id : values [i].id, label : values [i].label});
		if (values [i].selected)
			combo.select (i);
	}


	var p = combo.popup.element;
	var w = p.css("visibility","hidden").show().outerWidth();
	p.hide().css("visibility","visible");
	if (options.empty && options.empty.length * 8 > w)
		w = options.empty.length * 8;
	if (options.max_len && options.max_len * 8 < w)
		w = options.max_len * 8;
	combo.element.closest(".k-widget").width(w + 32);

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
		if (relTarg.id !== "ul_" + id)
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
				var selected_item = data [$(e.item).index()];
				if (selected_item) {
					var selected_url = selected_item.url;
					if (selected_url) {
						if (selected_url.match(/^javascript:/i)) {

							var code = decodeURI (selected_url.substr (11));

							if (selected_item.confirm) {
								if (confirm (selected_item.confirm)) {
									eval (code);
								}
							} else {
								eval (code);
							}
						} else {
							if (selected_item.confirm) {
								if (!confirm (selected_item.confirm)) {
									setCursor ();
									menuDiv.remove ();
									e.preventDefault();
								}
							}
						}
					}
				}
				menuDiv.remove ();
			}
		});

		if (menuDiv.width () < this.clientWidth)
			menuDiv.width (this.clientWidth);

		return false;

	});
}

function table_row_context_menu (e, tr) {

	var menuDiv = $('<ul class="menuFonDark" title="" style="position:absolute;z-index:200;white-space:nowrap" />').appendTo (document.body);

	menuDiv.css ({
		top:  e.pageY,
		left: e.pageX
	});

	var items = $.parseJSON ($(tr).attr ('data-menu'));
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

function typeAhead (noChange) { // borrowed from http://www.oreillynet.com/javascript/2003/09/03/examples/jsdhtmlcb_bonus2_example.html

	var event = window.event;

	if (!event || event.ctrlKey || event.altKey) return;

	var keyCode = event.keyCode;

	if (keyCode == 8) return typeAheadInfo.accumString = "";

	if (keyCode == 13) return window.event.keyCode = 9;

	var now = new Date ();

	if (typeAheadInfo.accumString == "" || now - typeAheadInfo.last < typeAheadInfo.delay) {

		var selectElem = event.srcElement;

		var newChar = String.fromCharCode (keyCode).toUpperCase ();

		typeAheadInfo.accumString += newChar;

		var selectOptions = selectElem.options;

		var txt;

		var len = typeAheadInfo.accumString.length;

		for (var i = 0; i < selectOptions.length; i++) {

			txt = selectOptions [i].text.toUpperCase ();
			if (typeAheadInfo.accumString > txt.substr (0, len)) continue;

			if (selectElem.selectedIndex == i) break;

			selectElem.selectedIndex = i;

			if (txt.indexOf (typeAheadInfo.accumString) != 0) break;
			if (noChange) {

				selectElem.onclick = selectElem.onblur = function () {this.form.submit ()}

			}
			else {

				selectElem.onchange ();

			}

			clearTimeout (typeAheadInfo.timeout);

			typeAheadInfo.last = now;

			typeAheadInfo.timeout = setTimeout ("typeAheadInfo.reset()", typeAheadInfo.delay);

			return blockEvent ();

		}

	}
	else {

		clearTimeout (typeAheadInfo.timeout);

	}

	typeAheadInfo.reset ();

	blockEvent ();

	return true;

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

	var e = form.elements;

	for (var i in values) e [i].value = values [i];

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

	label = label.length <= max_len ? label : (label.substr (0, max_len - 3) + '...');

	for (var i = 0; i < select.options.length; i++) {
		if (select.options [i].value == id) {
			select.options [i].innerText = label;
			select.selectedIndex = i;
			window.focus ();
			select.focus ();
			$(select).change();
			$(select).data('kendoDropDownList').refresh();
			return;
		}
	}

	var option = document.createElement ("OPTION");
	select.options.add (option);
	option.value = id;

	if ("textContent" in option) {
		option.textContent = label;
	}
	else {
		option.innerText = label;
	}

	select.selectedIndex = select.options.length - 1;

	window.focus ();
	select.focus ();
	$(select).change();
	$(select).data('kendoDropDownList').refresh();
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

	last_cell_id = td;

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

	if (is_interface_is_locked)
		return;

	var e = get_event (lastKeyDownEvent);
	var keyCode = e.keyCode;
	var i = 0;

	if (e.altKey ) i += 2;
	if (e.ctrlKey) i ++;

	var kb_hook = kb_hooks [i] [keyCode];

	if (kb_hook) {
		kb_hook [0] (kb_hook [1]);
		return blockEvent ();
	}

	if (keyCode == 8 && !q_is_focused) {
		typeAheadInfo.accumString = "";
		blockEvent ();
		return;
	}

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
	this.last_cell_id = null;

}

TableSlider.prototype.set_row = function (row) {

	$(scrollable_table_ids).each (function (n) {

		var trs = '#' + this + ' > tbody > tr';

		$(trs).each (function (i) {

			tableSlider.rows.push (this);

			$('td', this).each (function (j) {

				this.onclick = td_on_click;
				this.oncontextmenu = td_on_click;

			})

		});

	});

	this.cnt      = this.rows.length;

	if (row < this.cnt) {
		this.row = row;
		if (numeroftables == 1) {
			this.rows [row].scrollIntoView(false);
		}
	}

}

TableSlider.prototype.get_cell = function () {

	if (!this.cnt) return null;

	var the_row = this.rows [Math.min (this.row, this.cnt - 1)];

	if (!the_row) return null;

	var cells = the_row.cells;

	if (!cells) return null;

	return cells [Math.min (this.col, cells.length - 1)];

}

TableSlider.prototype.cell_off = function (cell) {

	$('#slider').css ('visibility', 'hidden');

	$('#slider_').css ('visibility', 'hidden');

	return cell;

}

TableSlider.prototype.cell_on = function () {

	if (this.isVirgin && this.row == 0 && this.initial_row == 0) return;

	var cell         = this.get_cell ();

	if (!cell) return;

	var c            = $(cell);
	var a            = $('a', c).get (0);
	var table        = c.parents ('table').eq (0);
	var div          = table.parents ('div').eq (0);
	var offset       = div.offset ();
	var thead        = $('thead', table);
	var css          = c.offset ();

	css.width        = c.outerWidth ();

	var overlap      = css.left - offset.left - 1;
	if (overlap < 0) {
		css.left  -= overlap;
		css.width += overlap;
	}

	if (css.width < 1) return this.cell_off (cell);

	var cell_right   = css.left + css.width;
	var div_right    = offset.left + div.outerWidth () - 16;
	var overlap      = cell_right - div_right;
	if (overlap > 0) css.width -= overlap;

	if (css.width < 1) return this.cell_off (cell);

	css.height       = c.outerHeight ();
	css.cursor       = a == null ? 'default' : 'pointer';
	$('#slider').click (a == null ? null : function (event) {

		$('a', tableSlider.get_cell ()).each ( function () {

			a_click (this, event)

		})

	})

	$('#slider').dblclick (function (event) {

		$(tableSlider.get_cell ()).dblclick ();

	})

	if (
		css.top < offset.top + thead.outerHeight ()
		|| css.top + css.height + ((div.scrollHeight > div.offsetHeight - 12) ? 16 : 0) > offset.top + div.outerHeight ()
	) return this.cell_off (cell);

	css.top        --;
	css.left       --;
	css.visibility = 'visible';


	$('#slider_').css ({
		left   : css.left + css.width  - 2 - browser_is_msie,
		top    : css.top  + css.height - 2 - browser_is_msie,
		'visibility': 'visible'
	});

	if (!browser_is_msie) {
		css.width  -= 2;
		css.height -= 2;
	}
	else {
		css.width  ++;
		css.height ++;
	}
	$('#slider').css (css);
	if (this.last_cell_id != cell) focus_on_first_input (cell);

	this.last_cell_id = cell;

	return cell;

}

function td_on_click (event) {

	event = get_event (event);
	var td = browser_is_msie ? event.srcElement : event.target;

	if (td.tagName != 'TD') return;

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

	var cell = tableSlider.get_cell ();

	tableSlider.cell_on (cell);

	if (tableSlider.last_cell_id != cell) focus_on_first_input (cell);

	tableSlider.last_cell_id = cell;

	return false;

}

TableSlider.prototype.handle_keyboard = function (keyCode) {

	if (scrollable_table_is_blocked) return;

	if (keyCode == 13) {									// Enter key

		var cell = this.get_cell ();

		if (!cell) return;

		var children = cell.getElementsByTagName ('a');

		if (children == null || children.length == 0) {

			while (cell && cell.tagName != 'TR') cell = cell.parentNode;

			children = cell.getElementsByTagName ('a');

		}

		if (children != null && children.length > 0) activate_link (children [0].href, children [0].target);

		return false;

	}

	if (!this.cnt || keyCode < 37 || keyCode > 40) return;

	var cnt = this.cnt;
	var key = 'row';
	var i   = keyCode % 2;

	if (i) {
		if (left_right_blocked) return;
		var cnt = this.rows [this.row].cells.length;
		var key = 'col';
	}

	if (!cnt) return;

	this [key] += (keyCode - 39 + i);
	if (this [key] < 0) this [key]    = 0;
	if (this [key] >= cnt) this [key] = cnt - 1;

	this.scrollCellToVisibleTop ();

	return blockEvent ();

}

TableSlider.prototype.scrollCellToVisibleTop = function (force_top) {

	// hiding the slider

	this.cell_off ();

	// selecting elements

	var td = this.get_cell ();

	if (!td) return;

	var tr = td.parentNode;
	if (tr.tagName == 'A') tr = tr.parentNode;
	var table = tr.parentNode.parentNode;
	var thead = table.tHead;
	var div   = table.parentNode;

	// checking top border

	var delta = div.scrollTop - td.offsetTop + 2;
	if (thead) delta += thead.offsetHeight;
	if (delta > 0) div.scrollTop -= delta;

	// checking bottom border

	var delta = td.offsetTop - div.scrollTop;
	if (force_top) {
		if (thead) delta -= thead.offsetHeight;
		delta -= td.offsetHeight;
		delta += 8;
	}
	else {
		delta -= div.offsetHeight;
		delta += td.offsetHeight;
//		if (div.scrollWidth > div.offsetWidth - 12) delta += 18;
	}
	if (delta > 0) div.scrollTop += delta;

	// checking left border

	var delta = div.scrollLeft - td.offsetLeft + 2;
	if (delta > 0) div.scrollLeft -= delta;

	// checking right border

	var delta = td.offsetLeft - div.scrollLeft;
	delta -= div.offsetWidth;
	delta += td.offsetWidth;
//	if (div.scrollHeight > div.offsetHeight - 12) delta += 18;
	if (delta > 0) div.scrollLeft += delta;

	// showing the slider

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
function treeview_convert_plain_response(response) {

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
		item.text = item.label;

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

function treeview_select_node_by_id(treeview, id_node) {

	var item = treeview.dataSource.get (id_node);
	if (item) {
		var node = treeview.findByUid (item.uid);
		treeview.select (node);
	}
}

function treeview_onselect_node (node) {
	var treeview = $("#splitted_tree_window_left").data ("kendoTreeView");
	node = treeview.dataItem (node);
	if (!node || !node.href) return;
	var href = node.href;

	var name = $("#splitted_tree_window_right").data('name');
	$("#splitted_tree_window_right").html ("<iframe onload='this.style.visibility="+'"visible"'+"' style='visibility: hidden;' width=100% height=100% src='" + href + "' name='" + name + "' id='__content_iframe' application=yes scroll=no>");

	/************************* add height in iframe *************************/
	var heghtstr = $(window.parent.document.getElementById( "tabstrip" )).height();
	if (heghtstr > 100){
		$('#__content_iframe').css('height', heghtstr - 36);
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

function eludia_copy_clipboard (text, element) {

	if (!eludia_is_flash_installed() || !element) {

		$(element).attr('href', 'javascript: window.prompt(\''+ i18n.copy_clipboard + '\', \'' + text + '\')');

		return;
	};

	$(element).attr('data-clipboard-text', text);

	var clip = new ZeroClipboard(element);

	$(element).on('destroy', function() { clip.destroy() });
}


function poll_invisibles () {
	var has_loading_iframes;
	$('iframe[name^="invisible"]').each (function () {if (this.readyState == 'loading') has_loading_iframes = 1});
	if (!has_loading_iframes) {
		window.clearInterval(poll_invisibles);
		$.unblockUI ();
		is_interface_is_locked = false;
		setCursor ();
	}
}


function activate_suggest_fields () {

	$("INPUT[data-role='autocomplete']").each (function () {

		var i = $(this);
		var id = i.attr ('id');

		var read_data = {};
		read_data [i.attr ('name')] = new Function("return $('#" + id + "').data('kendoAutoComplete').value()");

		i.kendoAutoComplete({
			minLength       : i.attr ('a-data-min-length') || 3,
			filter          : 'contains',
			suggest         : true,
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
				}
			}
		}).bind("change", function(e) {

			var _this = $(this).data("kendoAutoComplete");

			var selected_item = _this.current();
			var id = '', label = '';

			if (selected_item) {
				var data = _this.dataSource.data();
				id = data [selected_item.index()].id;
				label = data [selected_item.index()].label;
			}

			$('#' + this.id + '__label').val(label);
			$('#' + this.id + '__id').val(id);

		});

	});
}


function lrt_start (lrt_id) {

	$('head').append('<link rel="stylesheet" href="/i/libs/console.css" type="text/css" />');

	$.getScript("/i/libs/console.js", function(){

		var width = $(window).width() - 200,
			height = $(window).height() - 300,
			left = $(window).width() / 2  - width / 2,
			top = $(window).height() / 2  - height / 2;

		$.blockUI ({fadeIn: 0, message: ' '});

		var div = $('body').append ('<div class="console" style="position:absolute;z-index:2000;top:'+ top
			+ 'px;left:' + left + 'px;width:' + width + 'px;height:' + height + 'px;"></div>');

		var sid = /\bsid=(\d+)/.exec (window.location.href);
		if (sid == null)
			return;

		sid = sid [1];

		var get_lrt_interval,

			get_lrt = function () {
				return $.ajax ({
					url: '/',
					data: {
						sid : sid,
						salt : Math.random (),
						type : '__lrt',
						action : 'get',

						lrt_id : lrt_id,
					},
					dataType: 'json',
					type: 'POST',
					success: function (data) {
						if (data instanceof Array) {
							for (var i = 0; i < data.length; i ++) {
								var item = data [i];
								if (item.href) {
									clearInterval (get_lrt_interval);
									if (item.href == 'fake') {
										kendoConsole.log (item.label, item.is_error)
									} else {
										var f = function () {alert (item.label);window.location.href = item.href;};
										setTimeout (f, 1000);
									}
								} else {
									kendoConsole.log (item.label, item.is_error)
								}
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

	if (poll)
		window.setInterval(poll_invisibles, 100);

	return true;
}


function init_page (options) {

	try {top.setCursor ();} catch (e) {};

	if (options.focus)
		window.focus ();


	$('div.eludia-table-container').each(function() {

		var that = this;
		var table_url = '/?' + options.table_url + '&__only_table=' + this.id;
		table_url = table_url + '&__table_cnt=' + $('div.eludia-table-container').length;

		new window.SuperTable({
			tableUrl: table_url,
			initial_data : tables_data [this.id],
			el: $(that),
			containerRender : function() {
				$(that).find('tr[data-menu]').on ('contextmenu', function (e) {event.stopImmediatePropagation(); return table_row_context_menu (e, this)});
				activate_suggest_fields ();
			}
		});
	});

	tableSlider.set_row (options.__scrollable_table_row);

	activate_suggest_fields ();

	$(window).resize ();

	tableSlider.scrollCellToVisibleTop ();

	focus_on_input (options.__focused_input);

	if (options.blockui_on_submit) {

		$('form').submit (function () {return blockui();});

		$('form[target^="invisible"]').submit (function () {
			window.setInterval(poll_invisibles, 100);
		});

	}

	adjust_kendo_selects ();

	$('[data-type=datepicker]').kendoDatePicker();
	$('[data-type=datetimepicker]').kendoDateTimePicker();

	$('input[type=file]:not([data-upload-url])').each(function () {
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

	if (top.message) {
		var notification = $("#notification", top.document).data("kendoNotification");
		if (!notification) {
			notification = $("#notification", top.document).kendoNotification({
				stacking: "down",
				button: true
			}).data("kendoNotification");
		}
		notification.show (top.message);
		top.message = '';
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
