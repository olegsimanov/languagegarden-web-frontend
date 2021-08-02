    'use strict'

    {PageView} = require('./../../../common/views/page/base')
    {template} = require('./../../../common/templates')


    class InfoPageView extends PageView

        navigate: (navInfo) ->
            @controller.trigger('navigate', this, navInfo)

        onGoToDemo: (e) =>
            e.preventDefault()
            @navigate
                type: 'demo'


    class WelcomePageView extends InfoPageView
        template: template('./common/page/demo/welcome.ejs')
        events:
            'click .demo-link': 'onGoToDemo'


    class SummaryPageView extends InfoPageView
        template: template('./common/page/demo/summary.ejs')
        events:
            'click .demo-link': 'onGoToDemo'

        getRenderContext: ->
            ctx = super
            ctx.fpsStats = @controller.fpsStats
            ctx.fpsStatsAvailable = ctx.fpsStats?
            ctx.globalFpsStats = @controller.globalFpsStats
            ctx.globalFpsStatsAvailable = ctx.globalFpsStats?
            ctx.globalFpsStatsLoading = (ctx.fpsStatsAvailable and
                                         not ctx.globalFpsStatsAvailable)
            ctx


    module.exports =
        WelcomePageView: WelcomePageView
        SummaryPageView: SummaryPageView
