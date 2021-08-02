    'use strict'

    $ = require('jquery')
    settings = require('./../settings')
    {BaseController} = require('./../common/controllers')
    {LetterMetrics} = require('./../common/svgmetrics')
    {WelcomePageView, SummaryPageView} = require('./views/page/base')
    {PlantPlayerController} = require('./../player/controllers')
    {PlaybackMode} = require('./../player/constants')


    class BaseInfoController extends BaseController
        viewClass: null

        initialize: (options) ->
            super
            @view = new @viewClass
                controller: this
                containerEl: @containerElement

            # hack used for preloading font
            @letterMetrics = new LetterMetrics()
            @letterMetrics.getLength('A', 20)
            @listenTo(@view, 'navigate', @onObjectNavigate)

        remove: ->
            @letterMetrics.remove()
            views = [@view]
            for obj in views
                @stopListening(obj)
                obj.remove()
            @view = null
            super

        start: ->
            super
            @view.render()


    class WelcomeController extends BaseInfoController
        viewClass: WelcomePageView


    class DemoController extends PlantPlayerController
        modelId: settings.demo.plantId
        toolbarViewClass: null
        canvasTimelineButtonClasses: []
        playbackMode: PlaybackMode.SMOOTH

        initialize: (options) ->
            super
            @listenTo(@timeline, 'progress:change:end', @onProgressChangeEnd)

        onModelSync: ->
            super
            if not @timeline.isPlaying()
                @timeline.play()

        onProgressChangeEnd: ->
            @trigger('navigate', this, type: 'demo-summary')


    class SummaryController extends BaseInfoController
        viewClass: SummaryPageView

        initialize: (options) ->
            super
            @fpsStats = options.fpsStats

        getAnalyticsData: ->
            fpsStats = @fpsStats or {}

            if @fpsStats? and settings.urlRoots?.demostats?
                inputData = {}
                for key in ['avgFPS', 'minFPS', 'maxFPS']
                    inputData[key] = fpsStats[key]

                $.ajax
                    type: 'POST'
                    data: JSON.stringify(inputData)
                    dataType: 'json'
                    url: settings.urlRoots.demostats
                    success: (data) =>
                        if data.result?
                            @globalFpsStats = data.result
                            @view.render()

            'dimension1': settings.demo?.plantId
            'dimension2': settings.heroku?.version
            'metric1': fpsStats.avgFPS
            'metric2': fpsStats.minFPS
            'metric3': fpsStats.maxFPS
            'metric4': fpsStats.minFPSIndex
            'metric5': fpsStats.maxFPSIndex
            'metric6': if @fpsStats? then 1 else 0


    module.exports =
        WelcomeController: WelcomeController
        DemoController: DemoController
        SummaryController: SummaryController
