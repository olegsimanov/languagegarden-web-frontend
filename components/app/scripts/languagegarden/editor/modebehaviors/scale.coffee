    'use strict'

    {ModeBehavior} = require('./base')
    LetterBendBehavior = require('./../letterbehaviors/bend').BendBehavior
    LetterScaleBehavior = require('./../letterbehaviors/scale').ScaleBehavior
    LetterModeSwitchAndSelectBehavior = require('./../letterbehaviors/select').ModeSwitchAndSelectBehavior
    LetterEditBehavior = require('./../letterbehaviors/edit').EditBehavior
    {SelectBehavior} = require('./../mediabehaviors/select')


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
