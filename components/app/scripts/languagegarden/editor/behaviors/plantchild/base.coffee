    'use strict'

    _                   = require('underscore')

    {Point}             = require('./../../../math/points')
    {
        extend,
        extendAll
    }                   = require('./../../extend')


    class PlantChildBehavior

        @extend:        extend
        @extendAll:     extendAll

        id: 'missing-object-hehavior-id'

        constructor: (options) ->
            @parentView = options.parentView
            @controller = options.controller
            @model = @parentView.model
            @parentBehavior = options.parentBehavior
            @initialize(options)

        initialize: =>
            @handlers ?= {}
            @initializeHandlers() if @initializeHandlers?

    class MouseBehaviorBase extends PlantChildBehavior

        mouseHandlerBase: (view, event) ->
            event.preventDefault()
            event.srcEvent.stopPropagation()


    class DragBehaviorBase extends MouseBehaviorBase

        getDragInfo: -> console.log('getDragInfo method missing')

        initializeHandlers: ->
            @handlers = _.extend(
                @handlers,
                dragstart: @onDragStart
                drag: @onDragMove
                dragend: @onDragEnd
            )

        onDragStart: (view, event, x, y, options) =>
            @mouseHandlerBase(view, event)
            @model.stopTrackingChanges()
            if @shouldCheckOutOfBounds
                @containerBBox = @parentView.getCanvasBBox(true)
            @onDragStartViewUpdate(view, event, x, y, options)

        onDragMove: (view, event, x, y, dx, dy, options) =>
            @mouseHandlerBase(view, event)

            if not @draggingSet
                @draggingSet = true
                @parentView.setDragging(true)
                dragInfo = @getDragInfo(view, options)
                dragInfo.dragged = true

            @updateOutOfBounds() if @shouldCheckOutOfBounds

        onDragEnd: (view, event, options)  =>
            @mouseHandlerBase(view, event)

            if @draggingSet
                @draggingSet = false
                @parentView.setDragging(false)

            @onDragEndViewUpdate(view, event, options)
            delete @containerBBox
            @model.startTrackingChanges()

        processCoordinates: (x, y, dx, dy, di) ->
            # hammerjs drag is reported only when the cursor moves at least some
            # distance (10px by default), but the dx/dy still reflect the
            # original click point, so we need to compensate:
            di._startdx ?= dx
            di._startdy ?= dy
            dx -= di._startdx
            dy -= di._startdy
            [x, y, dx, dy]

        shouldCheckOutOfBounds: false

        updateOutOfBounds: =>
            views = @parentView.getSelectedViews()
            flag = _.any(views, @isViewOutOfBounds)
            _.each(views, (v) => @updateViewOutOfBounds(v, flag))

        updateViewOutOfBounds: (view, flag) => view.setIsOutOfBounds?(flag)
        isViewOutOfBounds: (view)           => not view.isInsideBBox?(@containerBBox, true)


    class ClickBehaviorBase extends MouseBehaviorBase

        onClick: (view, event)      => @mouseHandlerBase(view, event)
        initializeHandlers:         -> @handlers.click = @onClick


    class DblClickBehaviorBase extends MouseBehaviorBase

        onDblClick: (view, event)   => @mouseHandlerBase(view, event)
        initializeHandlers:         -> @handlers.dblclick = @onDblClick


    module.exports =
        DragBehaviorBase:       DragBehaviorBase
        ClickBehaviorBase:      ClickBehaviorBase
        DblClickBehaviorBase:   DblClickBehaviorBase
