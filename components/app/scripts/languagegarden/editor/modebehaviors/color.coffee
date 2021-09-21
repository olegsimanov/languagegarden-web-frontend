    'use strict'

    {BaseModeBehavior} = require('./../../common/modebehaviors/base')
    {ColorBehavior} = require('./../letterbehaviors/color')
    {EditorMode} = require('./../constants')


    ###When in color mode, only coloring is possible. Items will lose their
    selection, at least visually.
    ###
    class ColorModeBehavior extends BaseModeBehavior

        boundLettersClasses: [
            ColorBehavior
        ]
        middleLettersClasses: [
            ColorBehavior
        ]


    module.exports =
        ColorBehavior: ColorModeBehavior
