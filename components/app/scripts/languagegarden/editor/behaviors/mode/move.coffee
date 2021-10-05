    'use strict'

    {ModeBehavior}                      = require('./base')
    LetterMoveBehavior                  = require('./../../behaviors/letter/move').MoveBehavior
    LetterModeSwitchAndSelectBehavior   = require('./../../behaviors/letter/select').ModeSwitchAndSelectBehavior
    LetterEditBehavior                  = require('./../../behaviors/letter/edit').EditBehavior

    class MoveBehavior extends ModeBehavior
        boundLettersClasses: [
            LetterMoveBehavior,
            LetterModeSwitchAndSelectBehavior,
            LetterEditBehavior,
        ]
        middleLettersClasses: [
            LetterMoveBehavior,
            LetterModeSwitchAndSelectBehavior,
            LetterEditBehavior,
        ]

    module.exports =
        MoveBehavior:       MoveBehavior
