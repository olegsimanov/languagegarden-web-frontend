$ = require('jquery')
require('jquery.browser')


if $.browser.msie
    # dirty FIX:
    # window won't be focused when focus is on address bar, and we trigger focus
    # event by javascript for element inside window.
    $(window)
    .blur -> $(window).one 'click', window.focus
    .one 'load', window.focus

    # make special class for IE for css usage
    $(document.documentElement)
    .addClass("browser-is-ie browser-is-ie-#{$.browser.version.split('.').shift()}")
