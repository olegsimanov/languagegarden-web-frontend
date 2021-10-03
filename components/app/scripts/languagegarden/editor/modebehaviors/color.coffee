    'use strict'

    {BaseModeBehavior} = require('./base')
    {ColorBehavior} = require('./../letterbehaviors/color')
    {EditorMode} = require('./../constants')


    class ColorModeBehavior extends BaseModeBehavior

        boundLettersClasses: [
            ColorBehavior
        ]
        middleLettersClasses: [
            ColorBehavior
        ]


    module.exports =
        ColorBehavior: ColorModeBehavior
