    'use strict'

    {ModeBehavior}                      = require('./base')
    LetterMoveBehavior                  = require('./../../behaviors/letter/move').MoveBehavior
    LetterModeSwitchAndSelectBehavior   = require('./../../behaviors/letter/select').ModeSwitchAndSelectBehavior
    LetterEditBehavior                  = require('./../../behaviors/letter/edit').EditBehavior
    MediumSelectBehavior                = require('./../../behaviors/media/select').SelectBehavior
    MediumMoveBehavior                  = require('./../../behaviors/media/move').MoveBehavior
    MediumEditBehavior                  = require('./../../behaviors/media/edit').EditBehavior


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
