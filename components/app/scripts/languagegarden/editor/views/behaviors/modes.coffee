    'use strict'

    _                                   = require('underscore')

    {ColorBehavior}                     = require('./color')
    LetterEditBehavior                  = require('./edit').EditBehavior
    LetterScaleBehavior                 = require('./scale').ScaleBehavior
    LetterModeSwitchAndSelectBehavior   = require('./select').ModeSwitchAndSelectBehavior
    LetterMoveBehavior                  = require('./move').MoveBehavior
    LetterRotateBehavior                = require('./rotate').RotateBehavior
    LetterBendBehavior                  = require('./bend').BendBehavior
    LetterStretchBehavior               = require('./stretch').StretchBehavior

    {MediumType}                        = require('./../../constants')
    {Point}                             = require('./../../math/points')
    {BBox}                              = require('./../../math/bboxes')


    class BaseModeBehavior

        boundLettersClasses:            []
        middleLettersClasses:           []
        selectedBoundLettersClasses:    []
        selectedMiddleLettersClasses:   []

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

    class ColorModeBehavior extends BaseModeBehavior

        boundLettersClasses: [
            ColorBehavior
        ]
        middleLettersClasses: [
            ColorBehavior
        ]

    class EditBehavior extends ModeBehavior
        middleLettersClasses: [
            LetterEditBehavior,
        ]
        boundLettersClasses: [
            LetterEditBehavior,
        ]

        onModeEnter: (oldMode) =>
            super
            @model.stopTrackingChanges()
            @parentView.deselectAll()

        onModeLeave: (newMode) =>
            insertView = @getInsertView()
            if not insertView?
                super
                return
            addOptions = {}
            if @parentView.editElementModelPosition?
                addOptions.at = @parentView.editElementModelPosition

            @parentView.wordSplitContext = @getWordSplitContext()
            insertModel = insertView.model

            insertView?.remove()
            @parentView.insertView = null

            insertModel.reduceTransform()
            text = insertModel.get('text')
            if text.length > 0
                oldMode = @parentView.mode
                @parentView.mode = newMode
                # adding the word in the edit mode would not update the
                # letter areas, therefore we add it in the 'future' mode
                @model.addElement(insertModel, addOptions)
                @parentView.mode = oldMode
            @model.startTrackingChanges()
            super

        getWordSplitContext: ->
            insertView = @getInsertView()

            position: insertView.lastCaretPos
            model: insertView.model

        getInsertView: -> @parentView.insertView


    class GroupScaleBehavior extends ModeBehavior

        selectedBoundLettersClasses: [
            LetterScaleBehavior,
        ]
        selectedMiddleLettersClasses: [
            LetterScaleBehavior,
        ]
        boundLettersClasses: [
            LetterModeSwitchAndSelectBehavior,
            LetterEditBehavior,
        ]

    class MoveBehavior extends ModeBehavior
        boundLettersClasses: [
            LetterMoveBehavior,
            LetterModeSwitchAndSelectBehavior,
            LetterEditBehavior,
        ]
        middleLettersClasses: [
            LetterMoveBehavior,
            LetterModeSwitchAndSelectBehavior,
            LetterEditBehavior,
        ]

    class RotateBehavior extends ModeBehavior

        selectedBoundLettersClasses: [
            LetterRotateBehavior,
        ]
        selectedMiddleLettersClasses: [
            LetterRotateBehavior,
        ]
        boundLettersClasses: [
            LetterModeSwitchAndSelectBehavior,
            LetterEditBehavior,
        ]
        middleLettersClasses: [
            LetterModeSwitchAndSelectBehavior,
            LetterEditBehavior,
        ]

    class ScaleBehavior extends ModeBehavior

        selectedBoundLettersClasses: [
            LetterScaleBehavior,
        ]
        selectedMiddleLettersClasses: [
            LetterBendBehavior,
        ]
        boundLettersClasses: [
            LetterModeSwitchAndSelectBehavior,
            LetterEditBehavior,
        ]
        middleLettersClasses: [
            LetterModeSwitchAndSelectBehavior,
            LetterEditBehavior,
        ]

    class StretchBehavior extends ModeBehavior

        selectedBoundLettersClasses: [
            LetterStretchBehavior,
        ]
        selectedMiddleLettersClasses: [
            LetterBendBehavior,
        ]
        boundLettersClasses: [
            LetterModeSwitchAndSelectBehavior,
            LetterEditBehavior,
        ]
        middleLettersClasses: [
            LetterModeSwitchAndSelectBehavior,
            LetterEditBehavior,
        ]


    class TextEditBehavior extends ModeBehavior

        boundLettersClasses: [
            LetterModeSwitchAndSelectBehavior,
            LetterEditBehavior,
        ]
        middleLettersClasses: [
            LetterModeSwitchAndSelectBehavior,
            LetterEditBehavior,
        ]

        getTextMediaViews: (onlySelected=false) =>
            views = []
            for view in @parentView.getMediaViews(MediumType.TEXT)
                if onlySelected and not view.isSelected()
                    continue
                views.push(view)
            views

        onModeEnter: (oldMode) =>
            super
            for view in @getTextMediaViews()
                view.startEdit() if view.shouldEnterEditMode

        onModeLeave: (newMode) =>
            for view in @getTextMediaViews()
                view.shouldEnterEditMode = false
                view.finishEdit()
            super

    module.exports =
        ColorBehavior:      ColorModeBehavior
        EditBehavior:       EditBehavior
        GroupScaleBehavior: GroupScaleBehavior
        MoveBehavior:       MoveBehavior
        RotateBehavior:     RotateBehavior
        ScaleBehavior:      ScaleBehavior
        StretchBehavior:    StretchBehavior
        TextEditBehavior:   TextEditBehavior
