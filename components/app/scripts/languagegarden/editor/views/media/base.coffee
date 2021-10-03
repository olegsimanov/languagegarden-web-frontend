    'use strict'

    require('raphael')
    _ = require('underscore')
    $ = require('jquery')
    {BBox} = require('./../../../math/bboxes')
    {PlantChildView} = require('../../../common/views/base')
    {VisibilityType, PlacementType} = require('./../../../editor/constants')
    {addSVGElementClass, removeSVGElementClass} = require('./../../../common/domutils')


    class MediumViewBase extends PlantChildView

        getPlacementType: -> PlacementType.CANVAS

        toFront: =>

    class DummyMediumView extends MediumViewBase


    class HtmlMediumView extends MediumViewBase
        width: 200
        height: 100
        className: 'html-media-float'
        shouldAppendToContainer: true

        initialize: (options) =>
            super
            @containerEl = options.containerEl
            @width ?= options.width if options.width
            @height ?= options.height if options.height
            @listenTo(@model, 'change:centerPoint', @onPositionChange)

        remove: =>
            delete @containerEl
            super

        onPositionChange: -> @setPosition()

        setPosition: (x, y) =>
            [x, y] = @model.get('centerPoint').toArray() if not (x? and y?)
            @$el.css
                left: x
                top: y
            [x, y]

        getBBox: =>
            clientBBox = BBox.fromClientRect(@el.getBoundingClientRect())
            @parentView.transformToCanvasBBox(clientBBox)

        intersects: (bbox) => @getBBox().intersects(bbox)


    class SvgMediumView extends MediumViewBase

        initialize: (options) =>
            super(options)
            @paper = options.paper

        remove: =>
            delete @paper
            super


    VisibilityPrototype =

        __required_interface_methods__: [
            'getElementNode',
            'addElementCSS',
            'removeElementCSS',
        ]

        updateVisibility: ->

            marked = @model.get('marked')
            if marked in [false, true]
                className = if marked then 'marked' else VisibilityType.FADED
            else
                className = @model.get('visibilityType') or VisibilityType.DEFAULT

            elemNode = @getElementNode()
            for own key, value of VisibilityType
                @removeElementCSS(elemNode, value)
            @addElementCSS(elemNode, className)

        setVisibilityType: (value=VisibilityType.VISIBLE, options) ->
            @model.set('visibilityType', value, options)


    SVGStylablePrototype =

        addElementCSS: (node, cssCls) ->
            addSVGElementClass(node, cssCls)

        removeElementCSS: (node, cssCls) ->
            removeSVGElementClass(node, cssCls)


    HTMLStylablePrototype =

        addElementCSS: (node, cssCls) -> $(node).addClass(cssCls)

        removeElementCSS: (node, cssCls) -> $(node).removeClass(cssCls)


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


    EventBindingPrototype =

        __required_interface_methods__: [
            'getMediumEventDispatcher',
            'getClickableNode',
        ]

        hammerEventOptions: {}

    BaseEditorDummyMediumView = DummyMediumView.extend(HTMLStylablePrototype).extend(VisibilityPrototype)


    EditorDummyMediumView = class extends BaseEditorDummyMediumView

        select: (selected=true, options) ->

        isSelected: -> false

        getBBox: => BBox.newEmpty()

        intersects: (bbox) => false


    module.exports =
        HtmlMediumView: HtmlMediumView
        SelectablePrototype: SelectablePrototype
        EventDispatchingPrototype: EventDispatchingPrototype
        EventBindingPrototype: EventBindingPrototype
        EditorDummyMediumView: EditorDummyMediumView
