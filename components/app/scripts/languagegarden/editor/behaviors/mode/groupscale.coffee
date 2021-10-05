    'use strict'

    {ModeBehavior}                      = require('./base')
    LetterScaleBehavior                 = require('./../../behaviors/letter/scale').ScaleBehavior
    LetterModeSwitchAndSelectBehavior   = require('./../../behaviors/letter/select').ModeSwitchAndSelectBehavior
    LetterEditBehavior                  = require('./../../behaviors/letter/edit').EditBehavior
    {SelectBehavior}                    = require('./../../behaviors/media/select')


    class GroupScaleBehavior extends ModeBehavior
        mediaClasses: [
            SelectBehavior,
        ]
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
