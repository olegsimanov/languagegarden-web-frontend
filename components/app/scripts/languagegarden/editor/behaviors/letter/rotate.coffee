    'use strict'

    _                       = require('underscore')
    {TransformBehavior}     = require('./transform')
    {Point}                 = require('./../../../math/points')


    class SingleLetterRotateBehavior extends TransformBehavior

        id: 'rotate'

        applyChangeToView: (view, x, y, angle) =>
            view.rotate(x, y, angle)
            view.toFront()
            view.updateTextPath()

        onDragMove: (view, event, x, y, dx, dy, options) =>
            if view._drag.isSingleWordOneLetter
                @singleLetterOnDragMove(view, event, x, y, dx, dy, options)

        singleLetterOnDragMove: (view, event, x, y, dx, dy, options) =>
            SingleLetterRotateBehavior.__super__.onDragMove.apply(@, arguments)
            di = @getDragInfo(view, options)
            if not di? then return
            [x, y] = view.screenToPathCoordinates(x, y)
            @applyChangeToView(view, x, y)

    class MultiWordRotateBehavior extends SingleLetterRotateBehavior

        isMultiWordRotate: (view) =>
            ln = view._drag?.selectedElementViews?.length
            ln ?= @parentView.getSelectedElements().length
            ln > 1

        onDragMove: (clickedView, event, x, y, dx, dy, options) =>
            if @isMultiWordRotate(clickedView)
                @multiWordOnDragMove(clickedView, event, x, y, dx, dy, options)
            else
                super

        onDragStart: (clickedView, event, x, y, options) =>
            if @isMultiWordRotate(clickedView)
                @multiWordOnDragStart(clickedView, event, x, y, options)
            else
                super

        onDragEnd: (clickedView, event, x, y, options) =>
            if @isMultiWordRotate(clickedView)
                @multiWordOnDragEnd(clickedView, event, x, y, options)
            super

        multiWordOnDragMove: (clickedView, event, x, y, dx, dy, options) =>
            @singleLetterOnDragMove(clickedView, event, x, y, dx, dy, options)

            angle = clickedView.getRotationAngle(x, y)
            for view in clickedView._drag.selectedElementViewsWithoutClicked
                @applyChangeToView(view, null, null, angle)

        getSecondaryViewDragInfo: (view, x, y, clickedViewDi) =>
            _.extend super, originPt: clickedViewDi._drag.originPt.copy()

        getTransformOriginPt: => @parentView.getSelectionBBox().getCenterPoint()

        multiWordOnDragStart: (clickedView, event, x, y, options={}) =>
            originPt = @getTransformOriginPt()

            options.originPt = originPt
            MultiWordRotateBehavior.__super__.onDragStart.call(
                @, clickedView, event, x, y, options)

            clickedViewDi = @getDragInfo(clickedView, options)
            els = _.without(clickedView._drag.selectedElementViews, clickedView)
            clickedView._drag.selectedElementViewsWithoutClicked = els
            for view in els
                view._dragInfo ?= {}
                di = view._dragInfo[null] = {_drag: {}}
                view._drag = di._drag = @getSecondaryViewDragInfo(
                    view, x, y, clickedViewDi
                )

        multiWordOnDragEnd: (clickedView, event, options) =>
            for view in clickedView._drag.selectedElementViewsWithoutClicked
                @onDragEndApplyTransform(view, clickedView._drag)

    module.exports =
        RotateBehavior: MultiWordRotateBehavior
