    'use strict'

    _                   = require('underscore')
    {DragBehavior}      = require('./base')
    settings            = require('./../../../settings')
    {Point}             = require('./../../../math/points')
    {Line}              = require('./../../../math/lines')



    class TransformBehavior extends DragBehavior

        shouldCheckOutOfBounds: true

        onDragStart: (view, event, x, y, options) =>
            super
            {originPt, letterIndex} = options

            di = @getDragInfo(view, options)
            startPt = new Point(x, y)
            start = view.getStartPoint().copy()
            end = view.getEndPoint().copy()

            firstLetterDragged = letterIndex == 0
            startPointLetterDragged = firstLetterDragged

            textRTL = view.isTextRTL()

            if textRTL
                startPointLetterDragged = not startPointLetterDragged

            moving = if startPointLetterDragged then start else end

            transformMatrix = view.model.get('transformMatrix')
            transformMatrixInv = transformMatrix.invert()
            textLength = view.model.get('text').length
            scale = transformMatrix.split().scalex
            path = view.model.getPath()

            minDistance = settings.minFontSize * textLength / scale

            [startPt.x, startPt.y] = view.screenToPathCoordinates(
                startPt.x, startPt.y)

            if textLength == 1
                pos = view.getLetterMiddlePathPosition(0)
                if not originPt?
                    originPt = path.getPointAtLength(pos)
                dragPointOffset = new Point(0, 0)
            else
                if not originPt?
                    if startPointLetterDragged
                        originPt = end
                    else
                        originPt = start

                if firstLetterDragged
                    if textRTL
                        pos = view.getLetterEndPathPosition(0)
                    else
                        pos = view.getLetterStartPathPosition(0)
                else
                    if textRTL
                        pos = view.getLetterStartPathPosition(textLength - 1)
                    else
                        pos = view.getLetterEndPathPosition(textLength - 1)

                pointOnPath = path.getPointAtLength(pos)
                dragPointOffset = pointOnPath.sub(startPt)

            selectedElementViews = @parentView.getSelectedElementViews()
            selectedMediaViews = @parentView.getSelectedMediaViews()
            selectedElements = (v.model for v in selectedElementViews)
            selectedMedia = (v.model for v in selectedMediaViews)
            selectedInitialElements = (v.model.deepClone() for v in selectedElementViews)
            isSingleLetter = textLength == 1
            isSingleWordOneLetter = selectedElementViews.length == 1 and isSingleLetter
            centerPt = @parentView.getSelectionBBox().getCenterPoint()

            di._drag =
                dragPointOffset: dragPointOffset
                initialPoints: _.map(view.getPoints(), (a) => a.toArray())
                initialMatrix: transformMatrix
                initialScale: scale
                currentMatrix: transformMatrix
                initialMatrixInv: transformMatrixInv
                startPt: startPt
                originPt: originPt
                centerPt: centerPt
                movingPt: moving
                startDragPt: new Point(x, y).addToSelf(dragPointOffset)
                initialLine: Line.fromTwoPoints(originPt, startPt)
                initialVec: originPt.sub(startPt)
                initialDist: Point.getDistance(startPt, originPt)
                minDistance: minDistance
                initialFontSize: view.model.get('fontSize')
                initialCopy: view.model.deepClone()

                selectedElementViews: selectedElementViews
                selectedMediaViews: selectedMediaViews
                selectedElements: selectedElements
                selectedMedia: selectedMedia
                selectedInitialElements: selectedInitialElements

                isSingleLetter: isSingleLetter
                isSingleWordOneLetter: isSingleWordOneLetter

                firstLetterDragged: firstLetterDragged
                startPointLetterDragged: startPointLetterDragged

            view._drag = di._drag

            for v in selectedElementViews
                v._drag = @getSecondaryViewDragInfo(v, x, y, di) if v != view

        getSecondaryViewDragInfo: (view, x, y, clickedViewDi) =>
            initialPoints: _.map(view.getPoints(), (a) => a.toArray())
            initialMatrix: view.model.get('transformMatrix')
            initialFontSize: view.model.get('fontSize')
            initialCopy: view.model.deepClone()

        restoreViewInitialState: (view) =>
            [
                startPoint, controlPoints..., endPoint
            ] = _.map(view._drag.initialPoints, (cs) -> new Point(cs...))
            view.model.set(
                transformMatrix: view._drag.initialMatrix
                controlPoints: controlPoints
                startPoint: startPoint
                endPoint: endPoint
                fontSize: view._drag.initialFontSize
            )
            view.setIsOutOfBounds(false)

        onDragEnd: (view, event, options) =>
            di = view._drag
            for selectedView in di.selectedElementViews
                @onDragEndApplyTransform(selectedView, di)
            super
            view._drag = undefined

        onDragEndApplyTransform: (view, drag) =>
            if view.isOutOfBounds
                @restoreViewInitialState(view)
            else
                view.model.set('transformMatrix', drag.currentMatrix)
                view.model.reduceTransform()

            view.updateTextPath()


    module.exports =
        TransformBehavior: TransformBehavior
