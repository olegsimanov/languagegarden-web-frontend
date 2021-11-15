    'use strict'

    _                       = require('underscore')
    $                       = require('jquery')
    {disableSelection}      = require('./../utils/dom')


    class SVGWrappedElement

        xlinkNS: "http://www.w3.org/1999/xlink"

        constructor: (options)      ->
                                        @paper          = options.paper
                                        @unselectable   = options.unselectable
                                        @initialize(options)
                                        @updateProperties(options)
                                        @create()

        initialize: (options)       ->
        updateProperties: (options) ->
        generateId:                 -> _.uniqueId('lg-svg-elem-uniq')

        getId:                      ->
                                        if not @id? then @id = @generateId()
                                        @id

        getAttrRef:                 -> "url(##{@getId()})"
        getSVGRootNode:             -> @paper.canvas
        getSVGDefsNode:             -> @getSVGRootNode().querySelector('defs')
        getSVGNamespaceURI:         -> @getSVGRootNode().namespaceURI
        getParentNode:              ->
        isCreated:                  -> @node?

        create:                     ->
                                        node = @createSVGNode(@getSVGNamespaceURI())
                                        node.setAttribute('id', @getId())
                                        disableSelection(node) if @unselectable
                                        @insertSVGNode(node)
                                        @updateSVGNode(node)
                                        @node = node

        update: (options)           ->
                                        @updateProperties(options)
                                        @updateSVGNode(@node) if @isCreated()

        remove:                     ->
                                        $(@node).remove()
                                        @node = undefined

        insertSVGNode: (node)       -> @getParentNode().appendChild(node)
        createSVGNode: (svgNS)      ->
        updateSVGNode: (node)       ->


    module.exports =
        SVGWrappedElement: SVGWrappedElement
