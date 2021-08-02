    'use strict'

    _ = require('underscore')
    {Action} = require('./base')


    class GoToSidebarChapter extends Action

        id: 'go-to-sidebar-chapter'

        initialize: (options) ->
            super
            @setPropertyFromOptions(options, 'sidebarTimeline', required: true)
            @setPropertyFromOptions(options, 'chapterIndex', required: true)
            @setPropertyFromOptions(options, 'activityRecords',
                                    default: @controller.activityRecords)

        rewindTimeline: (index) ->
            rootTimeline = @sidebarTimeline.getRootTimeline()
            currentIndex = rootTimeline.getStationPosition()
            if rootTimeline.shiftToNextStation? and currentIndex + 1 == index
                rootTimeline.shiftToNextStation()
            else if (rootTimeline.shiftToPreviousStation and
                        currentIndex - 1 == index)
                rootTimeline.shiftToPreviousStation()
            else
                rootTimeline.setStationPosition(index)

        perform: ->
            @sidebarTimeline.activateChapterByIndex(@chapterIndex)
            @rewindTimeline(@chapterIndex)

        getPreviousActivityIds: ->
            rootTimeline = @sidebarTimeline.getRootTimeline()
            if @chapterIndex > 0
                rootTimeline.getActivityIdsByStationPosition(@chapterIndex - 1)
            else
                []

        isAvailable: ->
            if not @activityRecords?
                return true
            activityIds = @getPreviousActivityIds()
            if not activityIds?
                return false
            blockingIds = (
                @activityRecords.filterBlockingActivityIdsNotCompleted(
                    activityIds))
            blockingIds.length == 0


    class GoToTitlePage extends GoToSidebarChapter

        id: 'go-to-title-page'

        initialize: (options) ->
            options = _.clone(options)
            options.chapterIndex = 0
            super(options)


    module.exports =
        GoToSidebarChapter: GoToSidebarChapter
        GoToTitlePage: GoToTitlePage

