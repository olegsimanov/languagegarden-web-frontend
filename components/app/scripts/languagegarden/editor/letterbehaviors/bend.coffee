    'use strict'

    _ = require('underscore')
    bezier = require('./../../math/bezier')
    {Line} = require('./../../math/lines')
    {Point} = require('./../../math/points')
    {DragBehavior} = require('./base')


    class BendBehavior extends DragBehavior

        id: 'bend'
        shouldCheckOutOfBounds: true

        onDragStart: (view, event, x, y, options) =>
            super
            di = @getDragInfo(view, options)
            start = view.getStartPoint()
            end = view.getEndPoint()
            di.initialPoints = _.map(view.getPoints(), (a) => a.toArray())
            line0 = Line.fromTwoPoints(end, start)
            ortho0 = line0.getOrthogonal()
            line1 = Line.ortogonalPassingFirst(start, end)
            line2 = Line.ortogonalPassingFirst(end, start)
            line3 = line0.copy().translate(ortho0)
            line4 = line0.copy().negateSelf().translate(ortho0.neg())

            pos = view.getLetterStartPathPosition(options.letterIndex)
            path = view.getPath()
            pointOnPath = path.getPointAtLength(pos)
            dragStartPoint = new Point(x, y)
            origDragPointOffset = pointOnPath.sub(dragStartPoint)
            startEndNormal = Point.getOrthogonal(start, end).normalize()
            projectLen = Point.dot(origDragPointOffset, startEndNormal)
            dragPointOffset = startEndNormal.mul(projectLen)

            di.boundLines = [line1, line2, line3, line4]
            di.firstMove = true
            di.dragPointOffset = dragPointOffset

        onDragMove: (view, event, x, y, dx, dy, options) =>
            super
            di = @getDragInfo(view, options)
            if not di? then return
            point = new Point(x, y).addToSelf(di.dragPointOffset)
            start = view.getStartPoint()
            end = view.getEndPoint()
            oldCtrlPoint = view.getControlPoints()[0]
            ctrlPoint = bezier.calculateQuadraticCtrlPoint(start, end, point)

            for l in di.boundLines
                if l.getSide(ctrlPoint) > 0
                    l.project(ctrlPoint)

            ctrlPoint = Point.weightedAvg(oldCtrlPoint, ctrlPoint, 0.15)

            ctrlPoint.x = Math.floor(ctrlPoint.x)
            ctrlPoint.y = Math.floor(ctrlPoint.y)
            view.model.set('controlPoints', [ctrlPoint])
            if di.firstMove
                view.toFront()
                di.firstMove = false
            view.updateTextPath()

        onDragEnd: (view, event, options) =>
            if view.isOutOfBounds
                di = @getDragInfo(view, options)
                @restoreViewInitialState(view, di)
            super

        restoreViewInitialState: (view, di) =>
            [startPoint, controlPoints..., endPoint] = _.map(di.initialPoints, (cs) -> new Point(cs...))
            view.model.set(
                controlPoints: controlPoints
                startPoint: startPoint
                endPoint: endPoint
            )
            view.setIsOutOfBounds(false)
            view.updateTextPath()


    module.exports =
        BendBehavior: BendBehavior
