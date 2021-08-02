    'use strict'

    _ = require('underscore')
    $ = require('jquery')
    {disableSelection} = require('./domutils')


    class SVGWrappedElement
        xlinkNS: "http://www.w3.org/1999/xlink"

        constructor: (options) ->
            @paper = options.paper
            @unselectable = options.unselectable
            @initialize(options)
            @updateProperties(options)
            @create()

        # implement in subclass
        initialize: (options) ->

        # implement in subclass
        updateProperties: (options) ->

        generateId: -> _.uniqueId('lg-svg-elem-uniq')

        getId: ->
            if not @id? then @id = @generateId()
            @id

        getAttrRef: -> "url(##{@getId()})"

        getSVGRootNode: -> @paper.canvas

        getSVGDefsNode: -> @getSVGRootNode().querySelector('defs')

        getSVGNamespaceURI: -> @getSVGRootNode().namespaceURI

        # implement in subclass
        getParentNode: ->

        isCreated: -> @node?

        create: ->
            node = @createSVGNode(@getSVGNamespaceURI())
            node.setAttribute('id', @getId())
            disableSelection(node) if @unselectable
            @insertSVGNode(node)
            @updateSVGNode(node)
            @node = node

        update: (options) ->
            @updateProperties(options)
            @updateSVGNode(@node) if @isCreated()

        remove: ->
            $(@node).remove()
            @node = undefined

        insertSVGNode: (node) -> @getParentNode().appendChild(node)

        # implement in subclass. should return the node
        createSVGNode: (svgNS) ->

        # implement in subclass
        updateSVGNode: (node) ->


    module.exports =
        SVGWrappedElement: SVGWrappedElement
