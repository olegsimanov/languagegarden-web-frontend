    'use strict'

    Hammer = require('hammerjs')
    _ = require('underscore')
    {
        DummyMediumView
        HTMLStylablePrototype
        VisibilityPrototype
    } = require('./../../../common/views/media/base')


    ###Adds view selectability.

    Provides: select/isSelected methods

    Requires implementations of styling methods:
    * addElementCSS,
    * removeElementCSS.

    See languagegarden.common.views.media.base for interfaces implementing them.

    ###
    SelectablePrototype =

        __required_interface_methods__: [
            'getElementNode',
            'addElementCSS',
            'removeElementCSS',
        ]

        getClickableNode: -> @getElementNode()

        applySelectionStyles: (elemNode, selected, options) ->
            if selected
                @addElementCSS(elemNode, 'selected')
            else
                @removeElementCSS(elemNode, 'selected')

        select: (selected=true, options) ->
            elemNode = @getElementNode()
            oldSelected = @isSelected()
            if oldSelected == selected
                return
            @selected = selected
            if elemNode?
                @applySelectionStyles(elemNode, selected, options)
            if options?.silent
                return
            @trigger('selectchange', this)

        isSelected: -> @selected or false


    ###Medium editor events compatibility (see ModeBehavior).###
    EventDispatchingPrototype =

        __required_interface_methods__: [
            'isSelected',
        ]

        getMediumEventDispatcher: (eventName) ->
            fullEventName = "medium#{eventName}"
            (args...) =>
                selPrefix = if @isSelected() then 'selected' else ''
                handler = @parentView.getModeBehaviorHandler("#{selPrefix}#{fullEventName}")
                if handler?
                    handler(this, args...)
                    true
                else
                    false


    ###Adds method allowing view to plug into editor events.###
    EventBindingPrototype =

        __required_interface_methods__: [
            'getMediumEventDispatcher',
            'getClickableNode',
        ]

        hammerEventOptions: {}

        bindClickableElementEvents: ->
            clickDispatcher = @getMediumEventDispatcher('click')
            dblClickDispatcher = @getMediumEventDispatcher('dblclick')
            dragDispatcher = @getMediumEventDispatcher('drag')
            dragStartDispatcher = @getMediumEventDispatcher('dragstart')
            dragEndDispatcher = @getMediumEventDispatcher('dragend')

            hammerDrag = (e) =>
                x = e.center.x
                y = e.center.y
                dx = e.deltaX
                dy = e.deltaY
                [x, y] = @parentView.transformToCanvasCoords(x, y)
                [dx, dy] = @parentView.transformToCanvasCoordOffsets(dx, dy)
                dragDispatcher(e, x, y, dx, dy)
            hammerDragstart = (e) =>
                x = e.center.x
                y = e.center.y
                [x, y] = @parentView.transformToCanvasCoords(x, y)
                dragStartDispatcher(e, x, y)

            Hammer(@getClickableNode(), @hammerEventOptions)
                .on('tap', clickDispatcher)
                .on('doubletap', dblClickDispatcher)
                .on('pan', hammerDrag)
                .on('panstart', hammerDragstart)
                .on('panend', dragEndDispatcher)


    BaseEditorDummyMediumView = DummyMediumView
    .extend(HTMLStylablePrototype)
    .extend(VisibilityPrototype)


    EditorDummyMediumView = class extends BaseEditorDummyMediumView

        select: (selected=true, options) ->

        isSelected: -> false

        getBBox: => BBox.newEmpty()

        intersects: (bbox) => false


    module.exports =
        SelectablePrototype: SelectablePrototype
        EventDispatchingPrototype: EventDispatchingPrototype
        EventBindingPrototype: EventBindingPrototype
        EditorDummyMediumView: EditorDummyMediumView
