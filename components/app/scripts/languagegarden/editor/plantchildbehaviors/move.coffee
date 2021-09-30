    'use strict'

    _ = require('underscore')
    {DragBehaviorBase} = require('./base')
    {Point} = require('./../../math/points')
    {BBox} = require('./../../math/bboxes')
    moveHelpers = require('./../behaviorhelpers/move')



    class MoveBehaviorBase extends DragBehaviorBase

        id: 'move'

        shouldCheckOutOfBounds: true
        plantChildType: 'plantChildType missing'

        applyCursorLimit: (cursorBox, x, y, dx, dy) ->
            if not cursorBox.containsCoordinates(x, y)
                [nx, ny] = cursorBox.nearestCoordinatesInside(x, y)
                dx += nx - x
                dy += ny - y
                x = nx
                y = ny
            [x, y, dx, dy]

        onDragStart: (view, event, x, y, options) =>
            super

            dragInfo = @getDragInfo(view, options)
            moveHelpers.initDragInfo(dragInfo, @parentView, view, @plantChildType)

            # calculate cursor bbox
            dragInfo.cursorBox = @getMoveCursorBBox(dragInfo, x, y)
            dragInfo

        onDragMove: (view, event, x, y, dx, dy, options) =>
            super
            di = @getDragInfo(view, options)
            if not di? then return

            [x, y, dx, dy] = @processCoordinates(x, y, dx, dy, di)

            # if selection is active, prevent unselected views from issuing move
            selected = @parentView.getSelectedViews()
            if selected.length > 0 and view not in selected then return

            [x, y, dx, dy] = @applyCursorLimit(di.cursorBox, x, y, dx, dy)

            moveHelpers.moveUsingDragInfo(di, @parentView, dx, dy)

        ###Calculate positions the cursor can move.###
        getMoveCursorBBox: (dragInfo, x, y) ->
            # find min/max of all letter area points
            contentBBox = BBox.fromPointList(
                _.flatten(_.map(
                    dragInfo.movingElements,
                    (i) -> i.view.getLetterAreaPoints()
                ))
            )

            contentBBox = BBox.fromBBoxList(
                _.chain(
                    _.map(dragInfo.movingMedia, (m) -> m.view.getBBox())
                ).push(contentBBox).value()
            )

            # offset based on cursor position
            # assuming the cursor must already be inside the bounding box
            BBox.fromCoordinates(
                x - contentBBox.leftTop.x,
                y - contentBBox.leftTop.y,
                @containerBBox.rightBottom.x - contentBBox.rightBottom.x + x,
                @containerBBox.rightBottom.y - contentBBox.rightBottom.y + y,
            )

        updateViewOutOfBounds: =>
            # disable updating the view so no coloring happens

    module.exports =
        MoveBehaviorBase: MoveBehaviorBase
