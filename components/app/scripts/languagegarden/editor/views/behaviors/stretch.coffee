    'use strict'

    _                       = require('underscore')

    {TransformBehavior}     = require('./transform')

    {Point}                 = require('./../../math/points')


    class StretchBehavior extends TransformBehavior

        id: 'stretch'

        onDragMove: (view, event, x, y, dx, dy, {letter}) =>
            super
            di = view._drag
            [x, y] = view.screenToPathCoordinates(x, y)
            x += di.dragPointOffset.x
            y += di.dragPointOffset.y
            dragPoint = new Point(x, y)
            view.model.stretch(dragPoint, di.startPointLetterDragged,
                               limit: true)
            di.movingPt.set(dragPoint)
            if di.firstMove
                view.toFront()
                di.firstMove = false
            view.updateTextPath()


    module.exports =
        StretchBehavior: StretchBehavior
