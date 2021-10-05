    'use strict'

    {ModeBehavior}                  = require('./base')
    LetterRotateBehavior            = require('./../../behaviors/letter/rotate').RotateBehavior
    {ModeSwitchAndSelectBehavior}   = require('./../../behaviors/letter/select')
    {EditBehavior}                  = require('./../../behaviors/letter/edit')
    {SelectBehavior}                = require('./../../behaviors/media/select')


    class RotateBehavior extends ModeBehavior
        mediaClasses: [
            SelectBehavior,
        ]
        selectedBoundLettersClasses: [
            LetterRotateBehavior,
        ]
        selectedMiddleLettersClasses: [
            LetterRotateBehavior,
        ]
        boundLettersClasses: [
            ModeSwitchAndSelectBehavior,
            EditBehavior,
        ]
        middleLettersClasses: [
            ModeSwitchAndSelectBehavior,
            EditBehavior,
        ]


    module.exports =
        RotateBehavior: RotateBehavior
