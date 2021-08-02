    'use strict'

    $ = require('jquery')
    {TextMediumBase} = require('./text')
    {MediumType} = require('./../../constants')
    {HTMLStylablePrototype, VisibilityPrototype} = require('./base')


    ###Simple uninteractive note view.###
    class BaseNoteView extends TextMediumBase
            .extend(HTMLStylablePrototype)
            .extend(VisibilityPrototype)

        className: "#{TextMediumBase::className} note-medium"
        editable: false

        onModelBind: ->
            @listenTo(@model, 'change:text', @updateContentFromModel)
            @listenTo(@model, 'change:noteTextContent', @invalidate)
            @listenTo(@model, 'change:visibilityType', @updateVisibility)

        setModelContent: (options) ->
            silent = options?.silent
            $textEl = $(@getTextElement())
            @model.set('text', $textEl.html(), silent: silent)

        updateContentFromModel: ->
            $textEl = $(@getTextElement())
            $textEl.html(@getTextContent())

        setEditable: (editable) ->
            if editable != @editable
                @editable = editable
                @applyEditableStyles()

        getTextContent: ->
            @model.getTextContent?() or super

        # VISUALS
        render: ->
            super
            @setPosition()
            @updateContentFromModel()
            @applyEditableStyles()
            @addElementCSS(@getTextElement(), @getElementStyles().join(' '))
            @updateVisibility()
            @

        getNoteTypeClass: => @model.get('type')

        getElementStyles: ->
            [
                @getTextSizeClass()
                @getNoteTypeClass()
                'note-medium-content'
            ]

        applyEditableStyles: (editable=@editable) ->
            @getTextElement()
                .attr('contenteditable', editable)
                .attr('unselectable', if editable then 'off' else 'on')


        # decoupling self and
        getTextElement: -> @getElement()

        # PROTOTYPES
        getElement: -> @$el

        getElementNode: -> @getElement().get(0)

        setCoreOpacity: (opacity) -> @$el?.css('opacity', opacity)


    class NoteView extends BaseNoteView

        render: ->
            @$el.css('position', 'absolute')
            super

        updateVisibility: ->
            @setCoreOpacity(@getOpacity())


    module.exports =
        BaseNoteView: BaseNoteView
        NoteView: NoteView
