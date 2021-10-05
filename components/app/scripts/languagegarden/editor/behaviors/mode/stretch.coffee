    'use strict'

    {ModeBehavior}                      = require('./base')
    LetterBendBehavior                  = require('./../../behaviors/letter/bend').BendBehavior
    LetterStretchBehavior               = require('./../../behaviors/letter/stretch').StretchBehavior
    LetterModeSwitchAndSelectBehavior   = require('./../../behaviors/letter/select').ModeSwitchAndSelectBehavior
    LetterEditBehavior                  = require('./../../behaviors/letter/edit').EditBehavior
    {SelectBehavior}                    = require('./../../behaviors/media/select')


    class StretchBehavior extends ModeBehavior
        mediaClasses: [
            SelectBehavior,
        ]
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
