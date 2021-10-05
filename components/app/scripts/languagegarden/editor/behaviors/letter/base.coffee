    'use strict'

    _ = require('underscore')
    {Point} = require('./../../../math/points')
    {BBox} = require('./../../../math/bboxes')
    {
        DragBehaviorBase
        ClickBehaviorBase
        DblClickBehaviorBase
    } = require('./../../behaviors/plantchild/base')



    LetterBehaviorPrototype =

        id: 'missing-letter-hehavior-id'
        getMetricName: -> "lbehavior.#{@id}"


    LetterDragBehaviorPrototype =

        getDragInfo: (view, {letterIndex}) -> view._dragInfo?[letterIndex]

        onDragStartViewUpdate: (view, event, x, y, {letterIndex}) ->
            view._dragInfo ?= {}
            view._dragInfo[letterIndex] =
                model: view.model
                letterIndex: letterIndex
                initialAttributes: _.clone(view.model.attributes)
                initialDragPoint: new Point(x, y)
                initialDragPathPoint: new Point(
                    view.screenToPathCoordinates(x, y)...)
                dragged: false

        onDragEndViewUpdate: (view, event, options) ->
            dragInfo = @getDragInfo(view, options)
            if dragInfo.dragged
                @parentView.updateDirtyLetterAreas()
                @parentView.selectionBBoxChange()
            view._dragInfo = null


    class DragBehavior      extends DragBehaviorBase.extend(LetterBehaviorPrototype).extend(LetterDragBehaviorPrototype)
    class ClickBehavior     extends ClickBehaviorBase.extend(LetterBehaviorPrototype)
    class DblClickBehavior  extends DblClickBehaviorBase.extend(LetterBehaviorPrototype)


    module.exports =
        DragBehavior:                   DragBehavior
        ClickBehavior:                  ClickBehavior
        DblClickBehavior:               DblClickBehavior
        LetterBehaviorPrototype:        LetterBehaviorPrototype
        LetterDragBehaviorPrototype:    LetterDragBehaviorPrototype
