    'use strict'

    {ModeBehavior} = require('./base')
    LetterBendBehavior= require('./../letterbehaviors/bend').BendBehavior
    LetterStretchBehavior = require('./../letterbehaviors/stretch').StretchBehavior
    LetterModeSwitchAndSelectBehavior = require('./../letterbehaviors/select').ModeSwitchAndSelectBehavior
    LetterEditBehavior = require('./../letterbehaviors/edit').EditBehavior
    {SelectBehavior} = require('./../mediabehaviors/select')


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
