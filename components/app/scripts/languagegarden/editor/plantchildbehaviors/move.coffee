    'use strict'

    _ = require('underscore')
    {DragBehaviorBase} = require('./base')
    {Point} = require('./../../math/points')
    {BBox} = require('./../../math/bboxes')

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
            @initDragInfo(dragInfo, @parentView, view, @plantChildType)

            # calculate cursor bbox
            dragInfo.cursorBox = @getMoveCursorBBox(dragInfo, x, y)
            dragInfo

        onDragMove: (view, event, x, y, dx, dy, options) =>
            super
            di = @getDragInfo(view, options)
            if not di? then return

            [x, y, dx, dy] = @processCoordinates(x, y, dx, dy, di)

            selected = @parentView.getSelectedViews()
            if selected.length > 0 and view not in selected then return

            [x, y, dx, dy] = @applyCursorLimit(di.cursorBox, x, y, dx, dy)

            @moveUsingDragInfo(di, @parentView, dx, dy)

        getMoveCursorBBox: (dragInfo, x, y) ->
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

            BBox.fromCoordinates(
                x - contentBBox.leftTop.x,
                y - contentBBox.leftTop.y,
                @containerBBox.rightBottom.x - contentBBox.rightBottom.x + x,
                @containerBBox.rightBottom.y - contentBBox.rightBottom.y + y,
            )

        initDragInfo: (dragInfo, editor, view, type) ->
            dragInfo.movingElements = []
            dragInfo.movingMedia = []

            addView = (view, movingInfos) ->
                model = view.model
                movingInfos.push
                    view: view
                    model: model
                    initialAttributes: _.clone(model.attributes)

            addElementView = (view) -> addView(view, dragInfo.movingElements)
            addMediumView = (view) -> addView(view, dragInfo.movingMedia)

            for view in editor.getSelectedElementViews()
                addElementView(view)

            for view in editor.getSelectedMediaViews()
                addMediumView(view)

            if _.size(dragInfo.movingElements) == 0 and _.size(dragInfo.movingMedia) == 0
                switch type
                    when 'element'
                        addElementView(view)
                    when 'medium'
                        addMediumView(view)

        moveUsingDragInfo: (dragInfo, editor, dx, dy) ->
            moveVector = new Point(dx, dy)
            lastView = null
            movedCount = 0
            for elInfo in dragInfo.movingElements
                element = elInfo.model
                view = elInfo.view
                startPoint = elInfo.initialAttributes.startPoint
                ctrlPoints = elInfo.initialAttributes.controlPoints
                endPoint = elInfo.initialAttributes.endPoint
                element.set
                    startPoint: startPoint.add(moveVector)
                    controlPoints: (p.add(moveVector) for p in ctrlPoints)
                    endPoint: endPoint.add(moveVector)
                view.updateTextPath()
                movedCount += 1
                lastView = view

            for elInfo in dragInfo.movingMedia
                medium = elInfo.model
                view = elInfo.view
                centerPoint = elInfo.initialAttributes.centerPoint
                medium.set
                    centerPoint: centerPoint.add(moveVector)
                movedCount += 1
                lastView = view

            if movedCount == 1
                lastView.toFront()


    module.exports =
        MoveBehaviorBase: MoveBehaviorBase
