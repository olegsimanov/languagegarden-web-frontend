    'use strict'

    {ClickBehavior} = require('./base')
    {ColorMode} = require('./../constants')


    class ColorBehavior extends ClickBehavior

        id: 'color'

        storeMetric: =>
            # disabling metric logging
            # this one is logged by coloring action

        onClick: (view, event, {letterIndex}) =>
            action = @parentView.getPaletteToolAction()

            # if in letter mode, just continue action for the selected letter
            # regardless of selection, pass letter as it's position in the word
            if @parentView.colorPalette.get('colorMode') == ColorMode.LETTER
                action.fullPerform(view.model, letterIndex)
            else
                action.fullPerform([view.model])
            super


    module.exports =
        ColorBehavior: ColorBehavior
