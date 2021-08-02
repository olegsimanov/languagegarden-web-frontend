    'use strict'

    {BBox} = require('./../../../math/bboxes')
    {HtmlMediumView} = require('./base')
    {TextSize} = require('./../../constants')
    {HTMLStylablePrototype} = require('./base')


    ###Basic interface for any text medium.###
    class TextMediumBase extends HtmlMediumView

        textAreaClass: 'text-box'

        className: "#{HtmlMediumView::className} text-medium"

        minHeight: null
        maxHeight: null

        width: null
        height: null

        emptyValue: '<p></p>'
        placeholder: '<p></p>'
        modelAttribute: 'text'


        initialize: (options) ->
            super
            @minHeight = options.minHeight if options.minHeight?
            @maxHeight = options.maxHeight if options.maxHeight?

            @minWidth = options.minWidth if options.minWidth?
            @maxWidth = options.maxWidth if options.maxWidth?

            @height = options.height if options.height?
            @width = options.width if options.width?

            @modelAttribute = options.modelAttribute if options.modelAttribute?
            @textAreaClass = options.textAreaClass or @textAreaClass

        setMinMaxHeight: (minHeight=@minHeight, maxHeight=@maxHeight) ->
            if not (minHeight? or maxHeight?)
                return

            opts = {}
            opts['min-height'] = minHeight if minHeight?
            opts['max-height'] = maxHeight if maxHeight?

            @getEditorSizingNode()
                .css(opts)

        setMinMaxWidth: (minWidth=@minWidth, maxWidth=@maxWidth) ->
            if not (minWidth? or maxWidth?)
                return

            opts = {}
            opts['min-width'] = minWidth if minWidth?
            opts['max-width'] = maxWidth if maxWidth?

            @getEditorSizingNode()
                .css(opts)

        getTextContent: => @model.get(@modelAttribute) or @placeholder or ''

        ###Defines the node that will have min and max width/height applied.###
        getEditorSizingNode: => console.log('getEditorSizingNode missing')
        getElementNode: -> @$el.get(0)

        getTextSizeClass: => "text-size-#{@model.get('textSize')}"


    TextMediumBase = TextMediumBase
        .extend(HTMLStylablePrototype)


    module.exports =
        TextMediumBase: TextMediumBase
