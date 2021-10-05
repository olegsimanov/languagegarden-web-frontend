    'use strict'

    {ModeBehavior}                      = require('./base')
    LetterBendBehavior                  = require('./../../behaviors/letter/bend').BendBehavior
    LetterStretchBehavior               = require('./../../behaviors/letter/stretch').StretchBehavior
    LetterModeSwitchAndSelectBehavior   = require('./../../behaviors/letter/select').ModeSwitchAndSelectBehavior
    LetterEditBehavior                  = require('./../../behaviors/letter/edit').EditBehavior


    class StretchBehavior extends ModeBehavior

        selectedBoundLettersClasses: [
            LetterStretchBehavior,
        ]
        selectedMiddleLettersClasses: [
            LetterBendBehavior,
        ]
        boundLettersClasses: [
            LetterModeSwitchAndSelectBehavior,
            LetterEditBehavior,
        ]
        middleLettersClasses: [
            LetterModeSwitchAndSelectBehavior,
            LetterEditBehavior,
        ]


    module.exports =
        StretchBehavior: StretchBehavior
