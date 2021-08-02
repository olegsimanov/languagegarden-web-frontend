    'use strict'

    {NavigationAction} = require('./base')


    class GoToActivityList extends NavigationAction
        id: 'go-to-activity-list'

        initialize: (options) ->
            super
            @setPropertyFromOptions(options, 'startPosition')

        getNavInfo: ->
            parentPlantInfo = @controller.getParentPlantInfo() or {}
            navType = parentPlantInfo.navType or 'nav-plant-activities'
            plantId = parentPlantInfo.id or @dataModel.get('parentId')
            startPosition = @startPosition
            startPosition ?= parentPlantInfo.startPosition
            startPosition ?= 0
            previousPosition = parentPlantInfo.startPosition

            if startPosition == 0
                # if the position is 0 (title page) we make
                # immediate jump
                previousPosition = 0

            type: navType
            plantId: plantId
            startPosition: startPosition
            previousPosition: previousPosition

    class GoToActivityThroughChapter extends GoToActivityList

        initialize: (options) ->
            super
            @setPropertyFromOptions(options, 'activityId')

        getNavInfo: ->
            result = super
            result.activityId = @activityId
            result


    class GoToActivity extends NavigationAction

        initialize: (options) ->
            super
            activityLink = options.activityLink
            @setPropertyFromOptions(options, 'activityId',
                                    default: activityLink?.get('activityId')
                                    required: true)


    class GoToActivityFromPlayer extends GoToActivity
        id: 'go-to-activity-from-player'

        initialize: (options) ->
            super
            @setPropertyFromOptions(options, 'sidebarTimeline', required: true)
            @setPropertyFromOptions(options, 'activityRecords')

        getCurrentStationPosition: ->
            console.error('getCurrentStationPosition is not defined')

        getPlantId: -> console.error('getPlantId is not defined')

        getNavType: -> 'play-plant'

        getFastFlag: -> false

        getAllActivityIds: ->
            console.error('getAllActivityIds is not defined')

        getNavInfo: ->
            type: 'play-activity-passive'
            activityId: @activityId
            fast: @getFastFlag()
            parentPlant:
                id: @getPlantId()
                startPosition: @getCurrentStationPosition()
                navType: @getNavType()

        perform: ->
            @sidebarTimeline.activateElementByActivityId(@activityId,
                                                         silent: true)
            super

        isAvailable: ->
            if not @activityRecords?
                return true
            activityIds = @getAllActivityIds()
            if not activityIds?
                return false
            blockingIds = (
                @activityRecords.filterBlockingActivityIdsNotCompleted(
                    activityIds))
            if @activityId in blockingIds
                @activityId == blockingIds[0]
            else
                true


    class GoToActivityFromPlantPlayer extends GoToActivityFromPlayer
        id: 'go-to-activity-from-plant-player'

        initialize: (options) ->
            super
            @setPropertyFromOptions(options, 'position')

        getCurrentStationPosition: ->
            if @position?
                @position
            else
                @timeline.getProgressTime()

        getPlantId: -> @dataModel.id

        getAllActivityIds: -> @timeline.getAllActivityIds()


    class GoToActivityFromActivityPlayer extends GoToActivityFromPlayer
        id: 'go-to-activity-from-activity-player'

        initialize: (options) ->
            super
            @setPropertyFromOptions(options, 'chapterIndex')

        getParentPlantInfo: -> @controller.getParentPlantInfo() or {}

        getCurrentStationPosition: ->
            parentPlantInfo = @getParentPlantInfo()
            parentPlantInfo.startPosition or 0

        getPlantId: ->
            parentPlantInfo = @getParentPlantInfo()
            parentPlantInfo.id or @dataModel.get('parentId')

        getNavType: ->
            parentPlantInfo = @getParentPlantInfo()
            parentPlantInfo.navType

        getAllActivityIds: ->
            activityIds = []
            for chapter in @sidebarTimeline.sidebarState.chapters.models
                activityIds.push(chapter.elements.pluck('activityId')...)
            activityIds


    class GoToActivityFromNavigator extends GoToActivity

        id: 'go-to-activity-from-navigator'

        getNavInfo: ->
            #TODO: return to activity list on proper station
            type: 'play-activity-passive'
            activityId: @activityId
            parentPlant:
                id: @dataModel.id
                navType: 'nav-plant'


    module.exports =
        GoToActivityFromPlantPlayer: GoToActivityFromPlantPlayer
        GoToActivityFromActivityPlayer: GoToActivityFromActivityPlayer
        GoToActivityFromNavigator: GoToActivityFromNavigator
        GoToActivityList: GoToActivityList
        GoToActivityThroughChapter: GoToActivityThroughChapter
