    'use strict'

    _ = require('underscore')

    require('../../polyfills/request-animation-frame')

    $ = require('jquery')
    require('../../../styles/layout.less')
    require('../../../font/languagegarden-regular-webfont.css')
    require('../../../font/eskorte-arabic-regular-webfont.css')
    require('../../../styles/iefix.less')

    require('../../iefix')

    {LetterMetrics}         = require('./svgmetrics')
    deleteActions           = require('./actions/delete')
    editorColors            = require('./colors')
    settings                = require('./../settings')
    {EventObject} =          require('./../editor/events')

    {EditorPalette}         = require('./models/palette')
    {Settings}              = require('./models/settings')
    {UnitState, LessonData} = require('./models/plants')

    buttons                 = require('./views/buttons')
    {EditorCanvasView}      = require('./views/canvas')
    {EditorTextBoxView}     = require('./views/textboxes')
    {EditorPageView}        = require('./views/page/base')
    {BuilderToolbar}        = require('./views/toolbars/builder')
    {ToolbarEnum}           = require('./views/toolbars/constants')

    class BaseEditorController extends EventObject
        modelClass:         UnitState
        dataModelClass:     LessonData
        ToolbarEnum:        ToolbarEnum
        buttonClasses:      []
        canvasViewClass:    EditorCanvasView
        textBoxViewClass:   EditorTextBoxView

        shortcutsAndActionsClasses: [
            ['Delete', deleteActions.DeleteAction],
        ]

        toolbarViewClass: null
        getToolbarViewClass: -> @toolbarViewClass

        constructor: (options) ->
            @cid = _.uniqueId('controller')
            @bus = new EventObject()
            super

        initialize: (options={}) ->
            super

            @containerElement = options.containerElement or document.body
            @backURL = options.backURL or '/'

            @draggingInfo = {}

            @dataModel = options.dataModel
            @dataModel ?= new @dataModelClass()
            @model = new @modelClass()

            editorPalette = new EditorPalette
                toolInfos: editorColors.initialTools
                newWordColor: editorColors.newWordColor

            settingsModel = Settings.getSettings('plant-view')

            @letterMetrics = new LetterMetrics()

            @canvasView = new @canvasViewClass
                controller: this
                model: @model
                dataModel: @dataModel
                settings: settingsModel
                colorPalette: editorPalette
                letterMetrics: @letterMetrics

            @listenTo(@canvasView, 'change:dragging', @onCanvasDraggingChange)
            @listenTo(@canvasView, 'change:bgDragging', @onCanvasBgDraggingChange)

            @textBoxView = new @textBoxViewClass
                controller: this
                model: @model
                dataModel: @dataModel
                settings: settingsModel
                letterMetrics: @letterMetrics

            if not settings.isMobile
                #TODO: handle optional dependencies
                editorKeyboard = require('./keyboard')

                @shortcutListener = new editorKeyboard.ShortcutListener
                    el: document.body

                for [shortcut, actionCls] in _.result(this,
                                                'shortcutsAndActionsClasses')
                    @shortcutListener.on(shortcut, new actionCls(
                        controller: this))

            toolbarViewClass = @getToolbarViewClass()
            @toolbarView = new toolbarViewClass
                controller: @

            @view = new EditorPageView
                controller: this
                canvasView: @canvasView
                subviews: @getPageViewSubviews()
                containerEl: @containerElement

            @canvasView.setParentView(@view)
            @textBoxView.setParentView(@view)

            @modelId = options.modelId
            @listenTo(@dataModel, 'sync', @onModelSync)
            for evObj in @getEventObjects()
                @listenTo(evObj, 'navigate', @onObjectNavigate)

        getTriggeringCallbacks: (options) ->
            successCallback = options?.success or ->
            errorCallback = options?.error or ->

            triggerSuccess = =>
                successCallback()
                @trigger('start:success', this)

            triggerError = =>
                errorCallback()
                @trigger('start:error', this)

            [triggerSuccess, triggerError]

        onObjectNavigate: (source, navigationInfo) ->
            @trigger('navigate', source, navigationInfo)

        getPageViewSubviews: ->
            '.toolbar-container': @toolbarView
            '.canvas-container': [@canvasView]
            '.text-to-plant-container': @textBoxView

        carveOutModelObjects: ->
            dataModel: @dataModel.deepClone()

        getEventObjects: ->
            views = [@view]
            models = []
            models.push(@dataModel) if @dataModel?
            views.concat(models)

        remove: ->
            for obj in @getEventObjects()
                @stopListening(obj)
                obj.remove()
            @shortcutListener?.remove()
            @model = null
            @dataModel = null
            @canvasView = null
            @view = null
            @letterMetrics.remove()
            @letterMetrics = null

            @bus.stopListening()
            @bus.off()
            @off()

            super

        renderViews: ->
            @view.render()
            # reinitialize scroll after the sidebar view (the subview of
            # this.view) is added to document body

        onModelSync: ->
            @renderViews()

        setModelId: (modelId, options) ->
            [triggerSuccess, triggerError] = @getTriggeringCallbacks(options)

            if modelId in ['unsaved', 'new']
                modelId = null
            else if _.isString(modelId)
                modelId = parseInt(modelId, 10)

            oldModelId = @dataModel.id

            if ((not modelId? and oldModelId?) or
                    (modelId? and not oldModelId?) or
                    (modelId? and oldModelId? and oldModelId != modelId))
                triggerSuccess()
                @renderViews()
            else
                triggerSuccess()
                @renderViews()

        start: (options) ->
            modelId = options?.modelId or @modelId
            @setModelId(modelId, options)

        isDragging: ->
            (@draggingInfo.canvasElements or
                @draggingInfo.canvasBackground or false)

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


    class PlantEditorController extends BaseEditorController
        toolbarViewClass: BuilderToolbar

    module.exports =
        PlantEditorController:          PlantEditorController
