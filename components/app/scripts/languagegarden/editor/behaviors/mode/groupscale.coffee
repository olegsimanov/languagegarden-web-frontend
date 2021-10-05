    'use strict'

    {ModeBehavior}                      = require('./base')
    LetterScaleBehavior                 = require('./../../behaviors/letter/scale').ScaleBehavior
    LetterModeSwitchAndSelectBehavior   = require('./../../behaviors/letter/select').ModeSwitchAndSelectBehavior
    LetterEditBehavior                  = require('./../../behaviors/letter/edit').EditBehavior


    class GroupScaleBehavior extends ModeBehavior

        selectedBoundLettersClasses: [
            LetterScaleBehavior,
        ]
        selectedMiddleLettersClasses: [
            LetterScaleBehavior,
        ]
        boundLettersClasses: [
            LetterModeSwitchAndSelectBehavior,
            LetterEditBehavior,
        ]


    module.exports =
        GroupScaleBehavior: GroupScaleBehavior
