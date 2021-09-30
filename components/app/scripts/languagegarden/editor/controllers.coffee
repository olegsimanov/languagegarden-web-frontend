    'use strict'

    _ = require('underscore')
    buttons = require('./views/buttons')
    deleteActions = require('./actions/delete')
    {UnitState, LessonData} = require('./models/plants')
    editorColors = require('./colors')
    settings = require('./../settings')
    {EditorPalette} = require('./models/palette')
    {EditorCanvasView} = require('./views/canvas')
    {EditorTextBoxView} = require('./views/textboxes')
    {BaseController} = require('./../common/controllers')
    {EditorPageView} = require('./views/page/base')
    {BuilderToolbar} = require('./views/toolbars/builder')
    {Settings} = require('./models/settings')
    {LetterMetrics} = require('./../common/svgmetrics')
    {ToolbarEnum} = require('./../common/views/toolbars/constants')


    class BaseEditorController extends BaseController
        modelClass: UnitState
        dataModelClass: LessonData
        ToolbarEnum: ToolbarEnum
        buttonClasses: []
        canvasViewClass: EditorCanvasView
        textBoxViewClass: EditorTextBoxView

        shortcutsAndActionsClasses: [
            ['Delete', deleteActions.DeleteAction],
        ]

        toolbarViewClass: null
        getToolbarViewClass: -> @toolbarViewClass

        initialize: (options={}) ->
            super
            @draggingInfo = {}

            #languagegarden.settings.debug.enabled
            debugEnabled = options.debugEnabled
            debugEnabled ?= false
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
                debug: debugEnabled
                settings: settingsModel
                colorPalette: editorPalette
                letterMetrics: @letterMetrics

            @listenTo(@canvasView, 'change:dragging', @onCanvasDraggingChange)
            @listenTo(@canvasView, 'change:bgDragging', @onCanvasBgDraggingChange)

            @textBoxView = new @textBoxViewClass
                controller: this
                model: @model
                dataModel: @dataModel
                debug: debugEnabled
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

        getPageViewSubviews: ->
            '.toolbar-container': @toolbarView
            '.canvas-container': [@canvasView]
            '.text-to-plant-container': @textBoxView

        ###
        This method is used for 'carving out' model data from controller,
        which allows reusing model & history objects in the editor when
        we return from the test player.
        ###
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
