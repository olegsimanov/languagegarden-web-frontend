    'use strict'

    _ = require('underscore')
    {Point} = require('./../../math/points')


    initDragInfo = (dragInfo, editor, view, type) ->
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

    moveUsingDragInfo = (dragInfo, editor, dx, dy) ->
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
            # TODO: use events for autoupdate
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
        initDragInfo: initDragInfo
        moveUsingDragInfo: moveUsingDragInfo
