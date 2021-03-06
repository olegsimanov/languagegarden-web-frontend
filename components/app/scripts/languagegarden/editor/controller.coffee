    'use strict'

    _ = require('underscore')
    $ = require('jquery')

    require('../../../styles/layout.less')
    require('../../../font/languagegarden-regular-webfont.css')
    require('../../../font/eskorte-arabic-regular-webfont.css')

    {EventsAwareClass}      = require('./events')
    editorColors            = require('./colors')

    {EditorPalette}         = require('./models/palette')
    {Settings}              = require('./models/settings')
    {UnitState, UnitData}   = require('./models/plants')

    {PageView}              = require('./views/page')
    {CanvasView}            = require('./views/canvas')
    {TextBoxView}           = require('./views/textbox')
    {ToolbarView}           = require('./views/toolbar')
    {LetterMetrics}         = require('./views/svg/svgmetrics')

    settings                = require('./../settings')

    class PlantController extends EventsAwareClass

        constructor: (enclosingHtmlEl) ->

            @dataModel          = new UnitData()
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

            @textBoxView        = new TextBoxView
                                        controller:     @
                                        model:          @model
                                        dataModel:      @dataModel
                                        settings:       Settings.getSettings('plant-view')
                                        letterMetrics:  @letterMetrics

            @toolbarView        = new ToolbarView( { controller: @ } )

            @pageView           = new PageView
                                        controller: this
                                        subviews:
                                            '.canvas-container':            [@canvasView]           # this array is required because this format is used by the toolbarView as well
                                            '.text-to-canvas-container':    @textBoxView
                                            '.toolbar-container':           @toolbarView
                                        containerEl: enclosingHtmlEl

            @canvasView.setParentView(@pageView)
            @textBoxView.setParentView(@pageView)

        start: ()       -> @pageView.render()

    module.exports =
        PlantController:    PlantController
