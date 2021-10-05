    'use strict'

    {
        MediaBehaviorPrototype
        MediaDragBehaviorPrototype
    }                   = require('./base')
    {MoveBehaviorBase}  = require('./../../behaviors/plantchild/move')


    class MoveBehavior extends MoveBehaviorBase.extend(MediaBehaviorPrototype).extend(MediaDragBehaviorPrototype)

        id:                 'move-media'
        plantChildType:     'medium'


    module.exports =
        MoveBehavior: MoveBehavior
