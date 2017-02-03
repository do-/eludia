(function($) {
    // START of plugin definition
    $.fn.showModalDialog = function(options) {

        if (window.frameElement && window.parent.$ && window.parent.$.showModalDialog) {
            window.parent.$.showModalDialog (options);
            return;
        }

        // build main options and merge them with default ones
        var optns = $.extend({}, $.fn.showModalDialog.defaults, options);

        var $frame = $('<iframe />');
        $frame.attr({
            'id'        : 'iframe_' + Math.floor(Math.random() * 10000),
            'src'       : optns.url,
            'name'      : '_modal_iframe',
            'scrolling' : optns.scrolling,
            'class'     : 'modal_div'
        });

        // set the padding to 0 to eliminate any padding,
        // set padding-bottom: 10 so that it not overlaps with the resize element
        $frame.css({
            'padding'        : 0,
            'margin'         : 0,
            'padding-bottom' : 10
        });

        // create jquery dialog using recently created iframe
        var $modalWindow = $frame.dialog({
            autoOpen  : true,
            modal     : true,
            width     : optns.width,
            height    : optns.height,
            resizable : optns.resizable,
            closeText : '',
            overlay   : {
                opacity    : 0.5,
                background : "black"
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
                var that = this;
                setTimeout (function () {$(that).dialog ('destroy')}, 10);
            },
            resizeStop: function() { $frame.css("width", "100%"); }
        });

        // set the width of the frame to 100% right after the dialog was created
        // it will not work setting it before the dialog was created
        $frame.css("width", "100%");

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
                var title = $(this).contents().find("title").text(); // get target page's title
                title = $("<div/>").html(title).text();

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
//        position           : [30, 30],
        resizable          : true,
        scrolling          : 'yes',
        onClose            : function() { },
        returnValue        : null
    };
    // END of plugin
})(jQuery);

// do so that the plugin can be called $.showModalDialog({options}) instead of $().showModalDialog({options})
jQuery.showModalDialog = function(options) {$().showModalDialog(options);};
