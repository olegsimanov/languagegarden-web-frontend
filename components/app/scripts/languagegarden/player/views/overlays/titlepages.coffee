'use strict'

{RenderableView} = require('./../../../common/views/renderable')
{template} = require('./../../../common/templates')
{TitlePageOverlay} = require('./../../../common/views/overlays/titlepages')
{
    RetryLessonButton
    StartLessonButton
} = require('./../buttons')


class PlayerTitleStatsView extends RenderableView
    template: template('./player/titlepages/stats.ejs')
    class: 'title-page__stats-container'

    countStats: ->
        activityIds = @controller.sidebarState.getElementsIds()
        activities = @controller.dataCache.getActivitiesJSONByIds(activityIds)
        activityEntries = @controller
            .activityRecords.getEntriesByActivityIds(activityIds)

        @stats = {}
        @stats.activities_count = _.filter(activities, (act) -> act.active).length
        @stats.completed_activities_count = _.filter(activityEntries,
            (act) -> act.get('done')
        ).length
        @stats.tries_count = 0
        @stats.score = 0;

        for activity in activityEntries
            @stats.tries_count += 1 if activity.get('done')
            @stats.tries_count += activity.get('numOfFailures')

        if @stats.tries_count > 0
            @stats.score = Math.ceil(
                (@stats.activities_count / @stats.tries_count) * 100
            )

    getRenderContext: ->
        @countStats()
        ctx = super
        _.extend(ctx, @stats)
        ctx

    renderCore: ->
        super

        if @stats.tries_count > 0
            actionBtnView = new RetryLessonButton(controller: @controller)
        else
            actionBtnView = new StartLessonButton(controller: @controller)

        @$el.find('.title-page__action').append(actionBtnView.el)
        actionBtnView.render()


class PlayerTitlePageOverlay extends TitlePageOverlay
    statsViewClass: PlayerTitleStatsView
    className: "#{TitlePageOverlay::className} title-page_player"

    initialize: ->
        super
        @statsView = new @statsViewClass
            controller: @controller
            model: @controller.dataModel

    renderCore: ->
        super
        @$el.append(@statsView.render().el)


module.exports =
    PlayerTitlePageOverlay: PlayerTitlePageOverlay
