    'use strict'

    _ = require('underscore')
    $ = require('jquery')

    require('../../polyfills/request-animation-frame')

    require('../../../styles/layout.less')
    require('../../../font/languagegarden-regular-webfont.css')
    require('../../../font/eskorte-arabic-regular-webfont.css')
    require('../../../styles/iefix.less')

    require('../../iefix')

    {LetterMetrics}         = require('./svgmetrics')
    editorColors            = require('./colors')
    settings                = require('./../settings')
    {EventObject}           = require('./../editor/events')

    {EditorPalette}         = require('./models/palette')
    {Settings}              = require('./models/settings')
    {UnitState, LessonData} = require('./models/plants')

    buttons                 = require('./views/buttons')
    {EditorCanvasView}      = require('./views/canvas')
    {EditorTextBoxView}     = require('./views/textboxes')
    {EditorPageView}        = require('./views/page')
    {BuilderToolbar}        = require('./views/toolbars/builder')
    {ToolbarEnum}           = require('./views/toolbars/constants')

    class PlantEditorController extends EventObject
        modelClass:         UnitState
        dataModelClass:     LessonData
        ToolbarEnum:        ToolbarEnum
        buttonClasses:      []
        canvasViewClass:    EditorCanvasView
        textBoxViewClass:   EditorTextBoxView
        toolbarViewClass:   BuilderToolbar

        constructor: (options = {}) ->

            @draggingInfo       = {}

            @dataModel          = options.dataModel
            @dataModel          ?= new @dataModelClass()
            @model              = new @modelClass()

            @letterMetrics = new LetterMetrics()

            @canvasView = new @canvasViewClass
                controller: this
                model: @model
                dataModel: @dataModel
                settings: Settings.getSettings('plant-view')
                colorPalette: new EditorPalette
                    toolInfos: editorColors.initialTools
                    newWordColor: editorColors.newWordColor
                letterMetrics: @letterMetrics

            @textBoxView = new @textBoxViewClass
                controller: this
                model: @model
                dataModel: @dataModel
                settings: Settings.getSettings('plant-view')
                letterMetrics: @letterMetrics

            @toolbarView = new BuilderToolbar
                controller: @

            @view = new EditorPageView
                controller: this
                canvasView: @canvasView
                subviews:
                    '.toolbar-container':       @toolbarView
                    '.canvas-container':        [@canvasView]
                    '.text-to-plant-container': @textBoxView
                containerEl: options.containerElement or document.body

            @canvasView.setParentView(@view)
            @textBoxView.setParentView(@view)

            @listenTo(@canvasView, 'change:dragging',   @onCanvasDraggingChange)
            @listenTo(@canvasView, 'change:bgDragging', @onCanvasBgDraggingChange)

        remove: ->

            @letterMetrics.remove()

            @model          = null
            @dataModel      = null
            @canvasView     = null
            @view           = null
            @letterMetrics  = null

            @off()

            super

        renderViews: -> @view.render()

        start: () ->
            @trigger('start:success', this)
            @renderViews()

        isDragging: -> (@draggingInfo.canvasElements or @draggingInfo.canvasBackground or false)

        setToolbarState: (state) ->
            if not state?
                state = @toolbarView.defaultState
            @toolbarView.setState(state)

        onCanvasDraggingChange: (source, value) ->
            oldDragging = @isDragging()
            @draggingInfo.canvasElements = value
            dragging = @isDragging()
            if oldDragging != dragging
                @trigger('change:dragging', this, dragging, oldDragging)

        onCanvasBgDraggingChange: (source, value) ->
            oldDragging = @isDragging()
            @draggingInfo.canvasBackground = value
            dragging = @isDragging()
            if oldDragging != dragging
                @trigger('change:dragging', this, dragging, oldDragging)

    module.exports =
        PlantEditorController:          PlantEditorController
