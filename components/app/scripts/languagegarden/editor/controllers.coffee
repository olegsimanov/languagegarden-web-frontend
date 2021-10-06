    'use strict'

    _ = require('underscore')
    $ = require('jquery')

    require('../../polyfills/request-animation-frame')

    require('../../../styles/layout.less')
    require('../../../font/languagegarden-regular-webfont.css')
    require('../../../font/eskorte-arabic-regular-webfont.css')
    require('../../../styles/iefix.less')

    require('../../iefix')

    {LetterMetrics}         = require('./views/svg/svgmetrics')
    editorColors            = require('./colors')
    settings                = require('./../settings')
    {EventsAwareClass}      = require('./../editor/events')

    {EditorPalette}         = require('./models/palette')
    {Settings}              = require('./models/settings')
    {UnitState, LessonData} = require('./models/plants')

    {EditorPageView}        = require('./views/page')
    {EditorCanvasView}      = require('./views/canvas')
    {EditorTextBoxView}     = require('./views/textbox')
    {BuilderToolbar}        = require('./views/toolbars/builder')

    class PlantEditorController extends EventsAwareClass

        constructor: (containerElement) ->

            @draggingInfo       = {}

            @dataModel          = new LessonData()
            @model              = new UnitState()
            @letterMetrics      = new LetterMetrics()

            @canvasView         = new EditorCanvasView
                                        controller:     @
                                        model:          @model
                                        dataModel:      @dataModel
                                        settings:       Settings.getSettings('plant-view')
                                        colorPalette:   new EditorPalette
                                            toolInfos: editorColors.initialTools
                                            newWordColor: editorColors.newWordColor
                                        letterMetrics: @letterMetrics

            @textBoxView        = new EditorTextBoxView
                                        controller:     @
                                        model:          @model
                                        dataModel:      @dataModel
                                        settings:       Settings.getSettings('plant-view')
                                        letterMetrics:  @letterMetrics

            @toolbarView        = new BuilderToolbar
                                        controller: @

            @pageView           = new EditorPageView
                                        controller: this
                                        canvasView: @canvasView
                                        subviews:
                                            '.canvas-container':        [@canvasView]
                                            '.text-to-plant-container': @textBoxView
                                            '.toolbar-container':       @toolbarView
                                        containerEl: containerElement

            @canvasView.setParentView(@pageView)
            @textBoxView.setParentView(@pageView)

            @listenTo(@canvasView, 'change:dragging',   @onCanvasDraggingChange)
            @listenTo(@canvasView, 'change:bgDragging', @onCanvasBgDraggingChange)

        remove: ->

            @letterMetrics.remove()

            @model          = null
            @dataModel      = null
            @canvasView     = null
            @pageView       = null
            @letterMetrics  = null

            @off()

            super

        renderViews: -> @pageView.render()

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
