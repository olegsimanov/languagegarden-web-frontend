    'use strict'

    {ModeBehavior} = require('./base')
    LetterScaleBehavior = require('./../letterbehaviors/scale').ScaleBehavior
    LetterModeSwitchAndSelectBehavior = require('./../letterbehaviors/select').ModeSwitchAndSelectBehavior
    LetterEditBehavior = require('./../letterbehaviors/edit').EditBehavior
    {SelectBehavior} = require('./../mediabehaviors/select')


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
