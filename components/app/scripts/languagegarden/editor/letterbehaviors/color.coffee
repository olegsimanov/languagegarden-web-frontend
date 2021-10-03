    'use strict'

    {ClickBehavior} = require('./base')
    {ColorMode} = require('./../constants')


    class ColorBehavior extends ClickBehavior

        id: 'color'

        onClick: (view, event, {letterIndex}) =>
            action = @parentView.getPaletteToolAction()

            if @parentView.colorPalette.get('colorMode') == ColorMode.LETTER
                action.fullPerform(view.model, letterIndex)
            else
                action.fullPerform([view.model])
            super


    module.exports =
        ColorBehavior: ColorBehavior
