    'use strict'

    _                   = require('underscore')

    {TransformBehavior} = require('./transform')

    {Point}             = require('./../math/points')


    class ScaleBehavior extends TransformBehavior

        id: 'scale'

        getBestFittingTransformation: (selectedElements, dragPoint, oldDragPoint,
                                       originPoint, options) ->
            inputVector = oldDragPoint.sub(originPoint)
            outputVector = dragPoint.sub(originPoint)

            transformations = []

            for elemModel in selectedElements
                t = elemModel.calculateScalingRotation(
                    originPoint, inputVector, outputVector, options
                )
                transformations.push(t)

            bestT = transformations[0]
            bestScore = Math.abs(1 - bestT.getDeterminant())

            for t in transformations[1...]
                score = Math.abs(1 - t.getDeterminant())
                if score < bestScore
                    bestT = t
                    bestScore = score

            return bestT

        onDragMove: (view, event, x, y, dx, dy, {letter}) =>
            super
            di = view._drag
            [x, y] = view.screenToPathCoordinates(x, y)
            x += di.dragPointOffset.x
            y += di.dragPointOffset.y
            if di.selectedElements.length > 1
                originPoint = di.centerPt
            else
                originPoint = di.originPt
            oldDragPoint = di.startDragPt
            dragPoint = new Point(x, y)

            scaleOptions =
                limit: true
            if di.isSingleWordOneLetter
                scaleOptions.disableRotation = true

            t = @getBestFittingTransformation(
                di.selectedInitialElements, dragPoint, oldDragPoint, originPoint,
                scaleOptions
            )

            for selectedView in di.selectedElementViews
                elemModel = selectedView.model
                elemInitialModel = selectedView._drag.initialCopy
                elemModel.transform(t, elemInitialModel)

            di.movingPt.set(dragPoint)
            if di.firstMove
                view.toFront()
                di.firstMove = false

            for selectedView in di.selectedElementViews
                selectedView.updateTextPath()


    module.exports =
        ScaleBehavior: ScaleBehavior
