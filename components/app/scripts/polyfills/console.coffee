# console object is not always available, so create one with dummy method
if not window.console?
    window.console =
        log: ->

window.console.warn ?= window.console.log
window.console.error ?= window.console.log
