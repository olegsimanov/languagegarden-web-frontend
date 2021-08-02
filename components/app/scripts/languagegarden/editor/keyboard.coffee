    'use strict'

    $ = require('jquery')

    keyMap =
        'Enter': 13
        'Shift': 16
        'Ctrl': 17
        'Alt': 18
        'Insert': 45
        'Delete': 46

    # add digits
    for charCode in [48..57]
        keyMap[String.fromCharCode(charCode)] = charCode
    # add letters
    for charCode in [65..90]
        keyMap[String.fromCharCode(charCode)] = charCode

    invertedKeyMap = {}
    for key, code of keyMap
        invertedKeyMap[code] = key

    toggleKeys = ['Shift', 'Ctrl', 'Alt']

    class ShortcutListener
        constructor: (options) ->
            @el = options.el
            $(@el)
            .on('keyup', @onDocumentKeyUp)
            .on('keydown', @onDocumentKeyDown)
            @shortcutMap = {}
            @toggleFlags = {}
            for toggleKey in toggleKeys
                @toggleFlags[toggleKey] = false

        getNormalizedShortcut: (shortcut) =>
            keys = shortcut.split('+')
            toggleCounter = 0
            nonToggleKey = null
            for key in keys
                if keyMap[key]?
                    if key in toggleKeys then toggleCounter += 1
                    else nonToggleKey = key
                else
                    console.log("unsupported key #{key}")
                    return null
            if keys.length != (toggleCounter + 1)
                console.log('too many/few toggle keys')
                return null
            orderedKeys = []
            for toggleKey in toggleKeys
                if toggleKey in keys
                    orderedKeys.push(toggleKey)
            orderedKeys.push(nonToggleKey)
            orderedKeys.join('+')

        constructNormalizedShortcut: (nonToggleKey) =>
            orderedKeys = []
            for toggleKey in toggleKeys
                if @toggleFlags[toggleKey]
                    orderedKeys.push(toggleKey)
            orderedKeys.push(nonToggleKey)
            orderedKeys.join('+')

        on: (shortcut, action) =>
            newShortcut = @getNormalizedShortcut(shortcut)
            @shortcutMap[newShortcut] = action

        onDocumentKeyUp: (event) =>
            code = if event.keyCode then event.keyCode else event.which
            if not invertedKeyMap[code]?
                return
            key = invertedKeyMap[code]
            if key in toggleKeys
                @toggleFlags[key] = false

        onDocumentKeyDown: (event) =>
            code = if event.keyCode then event.keyCode else event.which
            if not invertedKeyMap[code]?
                return
            key = invertedKeyMap[code]
            if key in toggleKeys
                @toggleFlags[key] = true
            else
                newShortcut = @constructNormalizedShortcut(key)
                if @shortcutMap[newShortcut]?
                    action = @shortcutMap[newShortcut]
                    action.fullPerform()
                    event.preventDefault()
                    event.stopImmediatePropagation()

        remove: =>
            @shortcutMap = {}
            $(@el)
            .off('keyup', @onDocumentKeyUp)
            .off('keydown', @onDocumentKeyDown)


    module.exports =
        ShortcutListener: ShortcutListener
