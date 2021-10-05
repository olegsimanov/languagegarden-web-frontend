    'use strict'

    {ModeBehavior}                  = require('./base')
    LetterRotateBehavior            = require('./../../behaviors/letter/rotate').RotateBehavior
    {ModeSwitchAndSelectBehavior}   = require('./../../behaviors/letter/select')
    {EditBehavior}                  = require('./../../behaviors/letter/edit')


    class RotateBehavior extends ModeBehavior

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
