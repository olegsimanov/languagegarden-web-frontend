    'use strict'

    _ = require('underscore')
    {Point} = require('./../../math/points')
    {TransformBehavior} = require('./transform')


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
            # fallback when view._drag is not ready
            ln ?= @parentView.getSelectedElements().length
            ln > 1

        ###Dispatch to the correct sub handler.###
        onDragMove: (clickedView, event, x, y, dx, dy, options) =>
            if @isMultiWordRotate(clickedView)
                @multiWordOnDragMove(clickedView, event, x, y, dx, dy, options)
            else
                super

        ###Add additional setup required only for multiple words.###
        onDragStart: (clickedView, event, x, y, options) =>
            if @isMultiWordRotate(clickedView)
                @multiWordOnDragStart(clickedView, event, x, y, options)
            else
                super

        ###Add additional teardown required only for multiple words.###
        onDragEnd: (clickedView, event, x, y, options) =>
            if @isMultiWordRotate(clickedView)
                @multiWordOnDragEnd(clickedView, event, x, y, options)
            super

        multiWordOnDragMove: (clickedView, event, x, y, dx, dy, options) =>
            # calculate transformation for the moving word
            @singleLetterOnDragMove(clickedView, event, x, y, dx, dy, options)

            # and apply it to all other views
            angle = clickedView.getRotationAngle(x, y)
            for view in clickedView._drag.selectedElementViewsWithoutClicked
                @applyChangeToView(view, null, null, angle)

        ###Simplified drag info for views other than the currently dragged
        (clicked) one.
        ###
        getSecondaryViewDragInfo: (view, x, y, clickedViewDi) =>
            _.extend super, originPt: clickedViewDi._drag.originPt.copy()

        ###Origin point of the whole group rotation.###
        getTransformOriginPt: => @parentView.getSelectionBBox().getCenterPoint()

        ###Sets up:
        * per-view drag data on secondary views and
        * the common rotation origin.

        ###
        multiWordOnDragStart: (clickedView, event, x, y, options={}) =>
            originPt = @getTransformOriginPt()

            options.originPt = originPt
            MultiWordRotateBehavior.__super__.onDragStart.call(
                @, clickedView, event, x, y, options)

            clickedViewDi = @getDragInfo(clickedView, options)
            # caching to simplify the loops and avoid comparison
            els = _.without(clickedView._drag.selectedElementViews, clickedView)
            clickedView._drag.selectedElementViewsWithoutClicked = els
            for view in els
                view._dragInfo ?= {}
                # secondary views don't require a specific letter, null is used
                # instead
                di = view._dragInfo[null] = {_drag: {}}
                view._drag = di._drag = @getSecondaryViewDragInfo(
                    view, x, y, clickedViewDi
                )

        ###Removes drag infos.###
        multiWordOnDragEnd: (clickedView, event, options) =>
            for view in clickedView._drag.selectedElementViewsWithoutClicked
                @onDragEndApplyTransform(view, clickedView._drag)

    module.exports =
        RotateBehavior: MultiWordRotateBehavior
