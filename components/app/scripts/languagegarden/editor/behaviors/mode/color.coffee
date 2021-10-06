    'use strict'

    {BaseModeBehavior} = require('./base')
    {ColorBehavior} = require('./../../behaviors/letter/color')


    class ColorModeBehavior extends BaseModeBehavior

        boundLettersClasses: [
            ColorBehavior
        ]
        middleLettersClasses: [
            ColorBehavior
        ]


    module.exports =
        ColorBehavior: ColorModeBehavior
