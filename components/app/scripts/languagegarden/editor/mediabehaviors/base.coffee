    'use strict'

    _ = require('underscore')
    {Point} = require('./../../math/points')
    {
        PlantChildBehavior
        DragBehaviorBase
        ClickBehaviorBase
        DblClickBehaviorBase
    } = require('./../plantchildbehaviors/base')



    MediaBehaviorPrototype =

        id: 'missing-media-hehavior-id'

        getMetricName: -> "mbehavior.#{@id}"


    MediaDragBehaviorPrototype =

        getDragInfo: (view) -> view._dragInfo

        onDragStartViewUpdate: (view, event, x, y) ->
            view._dragInfo =
                model: view.model
                initialAttributes: _.clone(view.model.attributes)
                initialDragPoint: new Point(x, y)
                dragged: false

        onDragEndViewUpdate: (view, event) ->
            dragInfo = @getDragInfo(view)
            if dragInfo.dragged
                @parentView.updateDirtyLetterAreas()
                @parentView.selectionBBoxChange()
            view._dragInfo = null


    class DragBehavior extends DragBehaviorBase.extend(MediaBehaviorPrototype).extend(MediaDragBehaviorPrototype)
    class ClickBehavior extends ClickBehaviorBase.extend(MediaBehaviorPrototype)
    class DblClickBehavior extends DblClickBehaviorBase.extend(MediaBehaviorPrototype)


    module.exports =
        DragBehavior: DragBehavior
        ClickBehavior: ClickBehavior
        DblClickBehavior: DblClickBehavior
        MediaBehaviorPrototype: MediaBehaviorPrototype
        MediaDragBehaviorPrototype: MediaDragBehaviorPrototype
