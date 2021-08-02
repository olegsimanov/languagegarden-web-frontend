    'use strict'

    {MoveBehaviorBase} = require('./../plantchildbehaviors/move')
    {
        LetterBehaviorPrototype
        LetterDragBehaviorPrototype
    } = require('./../../common/letterbehaviors/base')


    class MoveBehavior extends MoveBehaviorBase
            .extend(LetterBehaviorPrototype)
            .extend(LetterDragBehaviorPrototype)

        id: 'move-letter'
        plantChildType: 'element'


    module.exports =
        MoveBehavior: MoveBehavior
