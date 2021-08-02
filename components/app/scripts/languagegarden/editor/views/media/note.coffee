    'use strict'

    _ = require('underscore')
    $ = require('jquery')
    {disableSelection} = require('./../../../common/domutils')
    {Point} = require('./../../../math/points')
    {NoteView} = require('./../../../common/views/media/note')
    {
        SelectablePrototype
        EventDispatchingPrototype
        EventBindingPrototype
    } = require('./base')
    {EditorMode} = require('./../../constants')


    ExtendedNoteView = NoteView
        .extend(SelectablePrototype)
        .extend(EventDispatchingPrototype)
        .extend(EventBindingPrototype)

    ###Note providing:
    * disabling editable when any dragging is in progress (fixes unwanted
    selection)
    * deselecting other views when this note is focused (fixes case when
    user presses tab to focus this note)
    * configures hammer events so they won't disable the editable
    ###
    class EditorNoteBase extends ExtendedNoteView
        editable: true
        # PROTOTYPES
        # EventBindingPrototype
        hammerEventOptions:
            # TODO: check if this is neccessary
            stop_browser_behavior: false
            prevent_default: false

        events:
            'focus': 'onContentFocused'
            'blur': 'onBlur'

        initialize: (options) =>
            super
            @bindEditorEvents()

        remove: ->
            @unbindEditorEvents()
            super

        onParentViewBind: ->
            @listenTo(@parentView, 'change:dragging', @editorDraggedChange)
            @listenTo(@parentView, 'change:bgDragging', @editorDraggedChange)
            @listenTo(@parentView, 'change:mode', @editorModeChange)

        # INTERFACE
        # provide means for further classes to easily add/remove events
        bindEditorEvents: ->

        unbindEditorEvents: ->

        onBlur: (event) -> @setModelContent()

        onContentFocused: ->
            # content can gain focus because of page navigation (tab)
            # making sure everything gets deselected in such case
            @parentView.deselectAll()

        ###Sets editable state to false for the duration of drag to avoid
        selection issues.

        ###
        editorDraggedChange: (editor, value, oldValue) ->
            @setEditable(not value and @parentView.mode != EditorMode.COLOR)

        editorModeChange: (editor, value, oldValue) ->
            @setEditable(value != EditorMode.COLOR)

        # SelectablePrototype/EventDispatchingPrototype
        getClickableNode: -> @getElementNode()


    ####This type of note adds a ###
    class EditorNoteWithMargin extends EditorNoteBase
        marginWidth: 30
        # overriding the events because of the text wrapper
        events:
            'focus .note-medium-content': 'onContentFocused'
            'blur .note-medium-content': 'onBlur'

        initialize: (options) =>
            @setOptions(options, ['marginWidth'])
            @createTextElWrapper()
            @createHandleDiv()
            super

        createHandleDiv: ->
            if @$handleDiv?
                return

            @$handleDiv = $("<div>")
                .addClass('note-medium-margin')
                .css('position', 'absolute')
                .css('top', 0)
                .width(@marginWidth)
                .height('100%')

            @bindClickableElementEvents()

        createTextElWrapper: =>
            @$textEl = $('<div>').addClass('note-medium-content')

        getTextElement: -> @$textEl

        render: ->
            @$el.append(@$textEl)
            @$el.append(@$handleDiv)
            super
            this


        # PLUGGING IN
        remove: ->
            @$handleDiv.remove()
            @$handleDiv = null
            @$textEl.remove()
            @$textEl = null
            super

        # SelectablePrototype
        getClickableNode: -> @$handleDiv.get(0)

        applySelectionStyles: (elemNode, selected, options) ->
            super(@$handleDiv, selected)
            super


    class EditorNoteView extends EditorNoteWithMargin


    module.exports =
        EditorNoteView: EditorNoteView
