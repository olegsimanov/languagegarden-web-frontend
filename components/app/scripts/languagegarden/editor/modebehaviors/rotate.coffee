    'use strict'

    {ModeBehavior} = require('./base')
    LetterRotateBehavior = require('./../letterbehaviors/rotate').RotateBehavior
    {ModeSwitchAndSelectBehavior} = require('./../letterbehaviors/select')
    {EditBehavior} = require('./../letterbehaviors/edit')
    {SelectBehavior} = require('./../mediabehaviors/select')


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
