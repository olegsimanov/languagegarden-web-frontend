    'use strict'

    {ModeBehavior} = require('./base')
    LetterMoveBehavior = require('./../letterbehaviors/move').MoveBehavior
    LetterModeSwitchAndSelectBehavior = require('./../letterbehaviors/select').ModeSwitchAndSelectBehavior
    LetterEditBehavior = require('./../letterbehaviors/edit').EditBehavior
    MediumSelectBehavior = require('./../mediabehaviors/select').SelectBehavior
    MediumMoveBehavior = require('./../mediabehaviors/move').MoveBehavior
    MediumEditBehavior = require('./../mediabehaviors/edit').EditBehavior


    class MoveBehavior extends ModeBehavior
        mediaClasses: [
            MediumSelectBehavior,
            MediumMoveBehavior,
            MediumEditBehavior,
        ]
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

    class MediaMoveBehavior extends ModeBehavior
        mediaClasses: [
            MediumSelectBehavior,
            MediumMoveBehavior,
            MediumEditBehavior,
        ]
        boundLettersClasses: []
        middleLettersClasses: []


        onBgClick: (event, x, y) =>

        onBgDblClick: (event, x, y) =>

        onBgDragStart: (event, x, y) =>

        onBgDragMove: (event, x, y, dx, dy) =>

        onBgDragEnd: (event) =>


    module.exports =
        MoveBehavior: MoveBehavior
        MediaMoveBehavior: MediaMoveBehavior
