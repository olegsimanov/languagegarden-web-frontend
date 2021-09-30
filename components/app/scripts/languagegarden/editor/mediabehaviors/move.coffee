    'use strict'

    {MoveBehaviorBase} = require('./../plantchildbehaviors/move')
    {
        MediaBehaviorPrototype
        MediaDragBehaviorPrototype
    } = require('./base')


    class MoveBehavior extends MoveBehaviorBase.extend(MediaBehaviorPrototype).extend(MediaDragBehaviorPrototype)

        id: 'move-media'
        plantChildType: 'medium'


    module.exports =
        MoveBehavior: MoveBehavior
