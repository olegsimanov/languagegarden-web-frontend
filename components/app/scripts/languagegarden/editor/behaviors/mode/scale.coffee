    'use strict'

    {ModeBehavior}                      = require('./base')
    LetterBendBehavior                  = require('./../../behaviors/letter/bend').BendBehavior
    LetterScaleBehavior                 = require('./../../behaviors/letter/scale').ScaleBehavior
    LetterModeSwitchAndSelectBehavior   = require('./../../behaviors/letter/select').ModeSwitchAndSelectBehavior
    LetterEditBehavior                  = require('./../../behaviors/letter/edit').EditBehavior
    {SelectBehavior}                    = require('./../../behaviors/media/select')


    class ScaleBehavior extends ModeBehavior
        mediaClasses: [
            SelectBehavior,
        ]
        selectedBoundLettersClasses: [
            LetterScaleBehavior,
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
        ScaleBehavior: ScaleBehavior
