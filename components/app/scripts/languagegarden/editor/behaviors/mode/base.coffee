    'use strict'

    _           = require('underscore')

    {Point}     = require('./../../math/points')
    {BBox}      = require('./../../math/bboxes')


    class BaseModeBehavior

        boundLettersClasses: []
        middleLettersClasses: []
        selectedBoundLettersClasses: []
        selectedMiddleLettersClasses: []

        constructor: (options) ->
            @controller = options.controller
            @parentView = options.parentView
            @model = @parentView.model
            @initialize(options)

        initialize: (options) =>

            loadEventHandlers = (classes, prefix) =>
                for cls in classes
                    letterBehavior = new cls
                        parentView: @parentView
                        controller: @controller
                        parentBehavior: this
                    for eventName, handler of letterBehavior.handlers
                        @handlers["#{prefix}#{eventName}"] = handler

            @handlers ?= {}

            loadEventHandlers(@boundLettersClasses,         'boundletter')
            loadEventHandlers(@middleLettersClasses,        'middleletter')
            loadEventHandlers(@boundLettersClasses,         'selectedboundletter')
            loadEventHandlers(@middleLettersClasses,        'selectedmiddleletter')
            loadEventHandlers(@selectedBoundLettersClasses, 'selectedboundletter')
            loadEventHandlers(@selectedMiddleLettersClasses,'selectedmiddleletter')

            @handlers.bgclick       = @onBgClick
            @handlers.bgdblclick    = @onBgDblClick
            @handlers.bgdragstart   = @onBgDragStart
            @handlers.bgdrag        = @onBgDragMove
            @handlers.bgdragend     = @onBgDragEnd
            @handlers.modeenter     = @onModeEnter
            @handlers.modeleave     = @onModeLeave
            @handlers.modereset     = @onModeReset

        remove: ->

            @handlers   = null
            @model      = null
            @controller = null
            @parentView = null

        onModeEnter: (oldMode)              =>
        onModeReset:                        =>
        onModeLeave: (newMode)              =>

        onBgClick: (event, x, y)            =>
        onBgDblClick: (event, x, y)         =>
        onBgDragStart: (event, x, y)        =>
        onBgDragMove: (event, x, y, dx, dy) =>
        onBgDragEnd: (event)                =>


    class ModeBehavior extends BaseModeBehavior

        onBgClick: (event, x, y) =>
            @parentView.restoreDefaultMode()
            event.preventDefault()

        onBgDblClick: (event, x, y) =>
            @parentView.restoreDefaultMode()
            @parentView.startInserting(new Point(x, y))
            event.preventDefault()

        onBgDragStart: (event, x, y) =>
            @parentView.setBgDragging(true)
            @selectionBBox = BBox.newEmpty()

        onBgDragMove: (event, x, y, dx, dy) =>
            x1 = _.min([x - dx, x])
            y1 = _.min([y - dy, y])
            width = Math.abs(dx)
            height = Math.abs(dy)
            @selectionBBox = BBox.fromXYWH(x1, y1, width, height)
            @parentView.selectionRectObj.attr
                x: x1
                y: y1
                width: width
                height: height
            @parentView.selectionRectObj.show()

        onBgDragEnd: (event) =>
            @parentView.setBgDragging(false)
            @parentView.selectionRectObj.hide()
            @parentView.selectionRectObj.attr
                x: 0
                y: 0
                width: 1
                height: 1
            selectableViews = @parentView.getSelectableViews()
            selectedViews = (v for v in selectableViews when v.intersects(@selectionBBox))
            @parentView.reselect(selectedViews)


    module.exports =
        BaseModeBehavior:   BaseModeBehavior
        ModeBehavior:       ModeBehavior
