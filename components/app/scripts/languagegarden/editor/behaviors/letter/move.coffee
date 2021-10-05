    'use strict'

    {
        LetterBehaviorPrototype
        LetterDragBehaviorPrototype
    }                   = require('./base')
    {MoveBehaviorBase}  = require('./../../behaviors/plantchild/move')


    class MoveBehavior extends MoveBehaviorBase.extend(LetterBehaviorPrototype).extend(LetterDragBehaviorPrototype)

        id:                 'move-letter'
        plantChildType:     'element'


    module.exports =
        MoveBehavior: MoveBehavior
