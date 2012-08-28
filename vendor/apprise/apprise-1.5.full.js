// Apprise 1.5 by Daniel Raftery
// http://thrivingkings.com/apprise
//
// Button text added by Adam Bezulski
//
// Cached jQuery variables, position center added by Josiah Ruddell

function apprise(string, args, callback) {
    var default_args =
    {
        'confirm': false,     // Ok and Cancel buttons
        'verify': false,  // Yes and No buttons
        'input': false,     // Text input (can be true or string for default text)
        'animate': false,   // Groovy animation (can true or number, default is 400)
        'textOk': 'Ok',   // Ok button default text
        'textCancel': 'Cancel', // Cancel button default text
        'textYes': 'Yes',   // Yes button default text
        'textNo': 'No',   // No button default text
        'position': 'center'// position center (y-axis) any other option will default to 100 top
    }

    if (args) {
        for (var index in default_args)
        { if (typeof args[index] == "undefined") args[index] = default_args[index]; }
    }

    var aHeight = $(document).height(),
    aWidth = $(document).width(),
    apprise = $('<div class="appriseOuter"></div>'),
    overlay = $('<div class="appriseOverlay" id="aOverlay"></div>'),
    inner = $('<div class="appriseInner"></div>'),
        buttons = $('<div class="aButtons"></div>'),
    posTop = 100;

    overlay.css({ height: aHeight, width: aWidth })
    .appendTo('body')
        .fadeIn(100,function(){$(this).css('filter','alpha(opacity=70)');});

    apprise.appendTo('body');

    inner.append(string)
    .appendTo(apprise);



    if (args) {
        if (args['input']) {
            if (typeof (args['input']) == 'string') {
                inner.append('<div class="aInput"><input type="text" class="aTextbox" t="aTextbox" value="' + args['input'] + '" /></div>');
            }
            if (typeof (args['input']) == 'object') {
                inner.append($('<div class="aInput"></div>').append(args['input']));
            }
            else {
                inner.append('<div class="aInput"><input type="text" class="aTextbox" t="aTextbox" /></div>');
            }
            $('.aTextbox').focus();
        }
    }

    inner.append(buttons);
    if (args) {
        if (args['confirm'] || args['input']) {
            buttons.append('<button value="ok">' + args['textOk'] + '</button>');
            buttons.append('<button value="cancel">' + args['textCancel'] + '</button>');
        }
        else if (args['verify']) {
            buttons.append('<button value="ok">' + args['textYes'] + '</button>');
            buttons.append('<button value="cancel">' + args['textNo'] + '</button>');
        }
        else { buttons.append('<button value="ok">' + args['textOk'] + '</button>'); }
    }
    else { buttons.append('<button value="ok">Ok</button>'); }

    // position after adding buttons

    apprise.css("left", ($(window).width() - $('.appriseOuter').width()) / 2 + $(window).scrollLeft() + "px");
    // get center
    if (args) {
        if (args['position'] && args['position'] === 'center') {
            posTop = (aHeight - apprise.height()) / 2;
        }

        if (args['animate']) {
            var aniSpeed = args['animate'];
            if (isNaN(aniSpeed)) { aniSpeed = 400; }
            apprise.css('top', '-200px').show().animate({ top: posTop }, aniSpeed);
        }
        else { apprise.css('top', posTop).fadeIn(200); }
    }
    else { apprise.css('top', posTop).fadeIn(200); }


    $(document).keydown(function (e) {
        if (overlay.is(':visible')) {
            if (e.keyCode == 13)
            { $('.aButtons > button[value="ok"]').click(); }
            if (e.keyCode == 27)
            { $('.aButtons > button[value="cancel"]').click(); }
        }
    });

    var aText = $('.aTextbox').val();
    if (!aText) { aText = false; }
    $('.aTextbox').keyup(function ()
    { aText = $(this).val(); });

    $('.aButtons > button').click(function () {
        overlay.remove();
        apprise.remove();
        if (callback) {
            $(this).text("");
            var wButton = $(this).attr("value");
            if (wButton == 'ok') {
                if (args) {
                    if (args['input']) { callback(aText); }
                    else { callback(true); }
                }
                else {
                    callback(true);
                }
            }
            else if (wButton == 'cancel') {
                callback(false);
            }
        }
    });
}
