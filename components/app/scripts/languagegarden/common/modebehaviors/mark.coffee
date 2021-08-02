    'use strict'

    {BaseModeBehavior} = require('./../../common/modebehaviors/base')
    LetterMarkBehavior = require('./../letterbehaviors/mark').MarkBehavior


    class MarkBehavior extends BaseModeBehavior
        boundLettersClasses: [
            LetterMarkBehavior
        ]
        middleLettersClasses: [
            LetterMarkBehavior
        ]


    module.exports =
        MarkBehavior: MarkBehavior
