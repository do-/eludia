(function($) {
    // START of plugin definition
    $.fn.showModalDialog = function(options) {

        if (window.frameElement && window.parent.$ && window.parent.$.showModalDialog) {
            options.position = [10, 50];
            window.parent.$.showModalDialog (options);
            return;
        }

        // build main options and merge them with default ones
        var optns = $.extend({}, $.fn.showModalDialog.defaults, options);

        var $div = $('<div />')
        $div.attr({
            'class': 'modal_div'
        });
        $div.css({
            'padding': 0,
            'margin': 0,
            'overflow' : 'scroll',
            '-webkit-overflow-scrolling' :'touch'
        });

        // create the iframe which will open target page
        var $frame = $('<iframe />');
        $frame.attr({
            'src': optns.url,
            'name': '_modal_iframe',
            'scrolling': optns.scrolling
        });

        // set the padding to 0 to eliminate any padding,
        // set padding-bottom: 10 so that it not overlaps with the resize element
        $frame.css({
            'padding': 0,
            'margin': 0,
            'padding-bottom': 10
        });

        $div.append ($frame);

        // create jquery dialog using recently created iframe
        var $modalWindow = $div.dialog({
            autoOpen: true,
            modal: true,
            width: optns.width,
            height: optns.height,
            resizable: optns.resizable,
            position: optns.position,
            overlay: {
                opacity: 0.5,
                background: "black"
            },
            open: function(event, ui) {
                // close on click outside dialog
                $('.ui-widget-overlay').on('click', function () {
                    $(this).siblings('.ui-dialog').find('.ui-dialog-content').dialog('close');
                });
            },

            close: function() {
                // save the returnValue in options so that it is available in the callback function
                optns.returnValue = $frame[0].contentWindow.window.returnValue;
                optns.onClose();
            },
            resizeStop: function() { $frame.css("width", "100%"); }
        });

        // set the width of the frame to 100% right after the dialog was created
        // it will not work setting it before the dialog was created
        $div.css("width", "100%");
        $div.css("height", "100%");
        $frame.css("width", "100%");
        $frame.css("height", "100%");

        var close_dialog = function() {$modalWindow.dialog('close')};
        $('.ui-dialog-titlebar-close').on("touchend", close_dialog);
        $('.ui-dialog-titlebar-close').on("mouseup", close_dialog);

        var adjust_dialog_iframe = function () {
            // pass dialogArguments to target page
            $frame[0].contentWindow.window.dialogArguments = optns.dialogArguments;
            // override default window.close() function for target page
            $frame[0].contentWindow.window.close = close_dialog;
        };
        adjust_dialog_iframe ();

        $frame.load(function() {
            if ($modalWindow) {

                var maxTitleLength = 50; // max title length
                var title = $(this).contents().find("title").html(); // get target page's title

                if (title.length > maxTitleLength) {
                    // trim title to max length
                    title = title.substring(0, maxTitleLength) + '...';
                }

                // set the dialog title to be the same as target page's title
                $modalWindow.dialog('option', 'title', title);

                adjust_dialog_iframe ();
            }
        });

        return null;
    };

    // plugin defaults
    $.fn.showModalDialog.defaults = {
        url                : null,
        dialogArguments    : null,
        height             : 'auto',
        width              : 'auto',
        position           : [0, 0],
        resizable          : true,
        scrolling          : 'yes',
        onClose            : function() { },
        returnValue        : null
    };
    // END of plugin
})(jQuery);

// do so that the plugin can be called $.showModalDialog({options}) instead of $().showModalDialog({options})
jQuery.showModalDialog = function(options) { $().showModalDialog(options); };

function dialog_open (options) {

    if (typeof (options) === 'number') {
        options = dialogs[options];
    }

    if (typeof options.off === 'function') {
        options.off = options.off();
    }

    if (options.off) {
        return;
    }

    options.before = options.before || function (){};
    options.before();
    options.after = options.after || function (result){};

    options.href   = options.href.replace(/\#?\&_salt=[\d\.]+$/, '');
    options.href  += '&_salt=' + Math.random ();
    options.parent = window;

    var url = 'http://' + window.location.host + '/i/_skins/Mint/dialog.html?' + Math.random ();

    if (is_ua_mobile) {

        $.showModalDialog({
            url       : url,
            height    : options.height || window.innerHeight - 100,
            width     : options.width || window.innerWidth - 50,
            resizable : true,
            scrolling : 'no',
            dialogArguments: options,
            onClose: function () {
                var result = this.returnValue || {result : 'esc'};
                options.after(result);
            }
        });
        return;
    }


    var width  = options.width  || (screen.availWidth - (screen.availWidth <= 800 ? 50 : 100));
    var height = options.height || (screen.availHeight - (screen.availHeight <= 600 ? 50 : 100));

    var result = window.showModalDialog(url, options, options.options + ';dialogWidth=' + width + 'px;dialogHeight=' + height + 'px');
    result = result || {result : 'esc'};

    options.after(result);

    document.body.style.cursor='default';
}
