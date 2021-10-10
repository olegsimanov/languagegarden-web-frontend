    'use strict'

    _ = require('underscore')
    $ = require('jquery')

    require('../../polyfills/request-animation-frame')

    require('../../../styles/layout.less')
    require('../../../font/languagegarden-regular-webfont.css')
    require('../../../font/eskorte-arabic-regular-webfont.css')
    require('../../../styles/iefix.less')

    require('../../iefix')

    {EventsAwareClass}      = require('./events')
    editorColors            = require('./colors')

    {EditorPalette}         = require('./models/palette')
    {Settings}              = require('./models/settings')
    {UnitState, LessonData} = require('./models/plants')

    {EditorPageView}        = require('./views/page')
    {CanvasView}            = require('./views/canvas')
    {EditorTextBoxView}     = require('./views/textbox')
    {BuilderToolbarView}    = require('./views/toolbars/builder')
    {LetterMetrics}         = require('./views/svg/svgmetrics')

    settings                = require('./../settings')

    class PlantEditorController extends EventsAwareClass

        constructor: (containerElement) ->

            @dataModel          = new LessonData()
            @model              = new UnitState()
            @letterMetrics      = new LetterMetrics()

            @canvasView         = new CanvasView
                                        controller:     @
                                        model:          @model
                                        dataModel:      @dataModel
                                        settings:       Settings.getSettings('plant-view')
                                        colorPalette:   new EditorPalette
                                            toolInfos:      editorColors.initialTools
                                            newWordColor:   editorColors.newWordColor
                                        letterMetrics: @letterMetrics

            @textBoxView        = new EditorTextBoxView
                                        controller:     @
                                        model:          @model
                                        dataModel:      @dataModel
                                        settings:       Settings.getSettings('plant-view')
                                        letterMetrics:  @letterMetrics

            @toolbarView        = new BuilderToolbarView
                                        controller: @

            @pageView           = new EditorPageView
                                        controller: this
                                        canvasView: @canvasView
                                        subviews:
                                            '.canvas-container':            [@canvasView]
                                            '.text-to-canvas-container':    @textBoxView
                                            '.toolbar-container':           @toolbarView
                                        containerEl: containerElement

            @canvasView.setParentView(@pageView)
            @textBoxView.setParentView(@pageView)

        start: ()       -> @pageView.render()

    module.exports =
        PlantEditorController:          PlantEditorController
