    'use strict'

    require('raphael')
    _ = require('underscore')
    $ = require('jquery')
    {BBox} = require('./../../../math/bboxes')
    {OperationType} = require('./../../diffs/operations')
    {PlantChildView} = require('./../base')
    {VisibilityType, PlacementType} = require('./../../constants')
    {addSVGElementClass, removeSVGElementClass} = require('./../../domutils')


    ###Base class for any plant medium view.

    Adds custom getAnimations logic required for certain media types.

    ###
    class MediumViewBase extends PlantChildView

        getPlacementType: -> PlacementType.CANVAS

        toFront: =>

        ###Groups operations in batches for further processing.
        Operations are checked for their type, each TEXT_REPLACE operation will
        have own group created, others if can, will be grouped.

        Done to preserve the animation order.
        ###
        @groupOperations: (diff) ->
            opGroups = []
            lastGroup = []
            for op in diff
                if op.type == OperationType.TEXT_REPLACE
                    if lastGroup.length > 0
                        opGroups.push(lastGroup)
                        lastGroup = []
                    opGroups.push([op])
                else
                    lastGroup.push(op)

            opGroups.push(lastGroup) if lastGroup.length > 0
            opGroups

    class DummyMediumView extends MediumViewBase


    ###Base class for an html-based medium view.

    1) Uses this.$el as content and
    2) once rendered should be automatically appended to this.container (in
    render method).

    ###
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


    ###Base class for a medium view rendered in svg using Raphael.

    View's this.$el is omitted entirely in favour of custom rendering using
    this.paper.

    ###
    class SvgMediumView extends MediumViewBase

        initialize: (options) =>
            super(options)
            @paper = options.paper

        remove: =>
            delete @paper
            super

    ###Interface allowing the view to reflect model's visibilityType.

    Requires implementation of two methods:
    * addElementCSS
    * removeElementCSS

    ###
    VisibilityPrototype =

        __required_interface_methods__: [
            'getElementNode',
            'addElementCSS',
            'removeElementCSS',
        ]

        ###
        Override which does not use setCoreOpacity, instead uses css classes
        (we assume that we do not use setAnimOpacity in editor).
        ###
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


    ###Implements SVG-specific methods for applying css classes.

    Adds:
    * addElementCSS
    * removeElementCSS

    ###
    SVGStylablePrototype =
        # we use customized functions because jquery addClass() & removeClass()
        # do not work as expected

        addElementCSS: (node, cssCls) ->
            addSVGElementClass(node, cssCls)

        removeElementCSS: (node, cssCls) ->
            removeSVGElementClass(node, cssCls)


    ###Implements HTML-specific methods for applying css classes.

    Adds:
    * addElementCSS
    * removeElementCSS

    ###
    HTMLStylablePrototype =

        addElementCSS: (node, cssCls) -> $(node).addClass(cssCls)

        removeElementCSS: (node, cssCls) -> $(node).removeClass(cssCls)


    module.exports =
        MediumViewBase: MediumViewBase
        HtmlMediumView: HtmlMediumView
        SvgMediumView: SvgMediumView
        VisibilityPrototype: VisibilityPrototype
        SVGStylablePrototype: SVGStylablePrototype
        HTMLStylablePrototype: HTMLStylablePrototype
        DummyMediumView: DummyMediumView
