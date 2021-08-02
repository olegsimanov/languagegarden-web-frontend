    'use strict'

    _ = require('underscore')
    {EventObject} = require('./../events')
    {SidebarState} = require('./../models/sidebars')
    {buildPropertySupportPrototype} = require('./../properties')


    BaseSidebarTimeline = EventObject
    .extend(buildPropertySupportPrototype('rootTimeline'))
    .extend(buildPropertySupportPrototype('sidebarState'))


    class SidebarTimeline extends BaseSidebarTimeline

        initialize: (options={}) ->
            super
            @setPropertyFromOptions(options, 'controller', required: true)
            @setPropertyFromOptions(options, 'blocked', default: false)
            @setRootTimeline(options.rootTimeline, force: true, initialize: true)
            sidebarState = @buildSidebarState(options)
            @setSidebarState(sidebarState, force: true, initialize: true)
            @updateSidebarState()

        onRootTimelineBind: ->
            super
            @listenTo(@rootTimeline, 'annotationschange', @onRootTimelineUpdate)
            @listenTo(@rootTimeline, 'progresschange',
                      @onRootTimelineProgressChange)
            @dataModel = @rootTimeline.getDataModel()
            @listenTo(@dataModel, 'change:titleImage',
                      @onTitleImageChange)

        onRootTimelineUnbind: ->
            @stopListening(@dataModel)
            @stopListening(@rootTimeline)
            delete @dataModel

        buildSidebarState: (options) ->
            previousSidebarState = options.sidebarState
            if (previousSidebarState? and
                    not previousSidebarState.get('placeholder'))
                previousSidebarState
            else if @rootTimeline?
                model = @rootTimeline.getDataModel()
                new SidebarState
                    plantId: model.id
            else
                new SidebarState
                    placeholder: true

        updateSidebarState: ->
            if not @rootTimeline?
                return

            url = @dataModel.titleImage.getUrlForSize('medium')
            @sidebarState.set('titlePageImageUrl', url)
            chapters = @sidebarState.getChapters()
            stationsLength = @rootTimeline.getStationsLength()
            emptyModel = stationsLength == 0
            if emptyModel
                chapters.reset([])
                @activateChapterByIndex(0)
            else
                stationPosition = @rootTimeline.getTargetPosition()
                chapterData = []
                destActivityId = @controller.getDestinationActivityId()

                # adding chapter 0, not represented by any station position
                chapterData.push
                    elements: []
                    activeElementIndex: null

                # adding chapters representing by stations
                for station in @rootTimeline.getModelStations()
                    activityLinks = station.activityLinks
                    if destActivityId?
                        index = null
                        for index in [0...activityLinks.length]
                            link = activityLinks.at(index)
                            if link.get('activityId') == destActivityId
                                break
                        if index == activityLinks.length
                            index = null
                    chapterData.push
                        elements: activityLinks.toJSON()
                        activeElementIndex: index

                # adding additional chapter for non-station timeline end
                if chapterData.length < stationsLength + 1
                    chapterData.push
                        elements: []
                        activeElementIndex: null

                oldActiveChapterIndex = @sidebarState.getActiveChapterIndex()
                oldChapterData = chapters.toJSON()
                if (_.isEqual(oldChapterData, chapterData) and
                        oldActiveChapterIndex == stationPosition)
                    return
                chapters.reset(chapterData, silent: true)
                chapters.trigger('reset', chapters)
                if destActivityId?
                    @activateElementByActivityId(destActivityId)
                else
                    @activateChapterByIndex(stationPosition)

        isBlocked: -> @blocked

        setBlocked: (bool) ->
            @blocked = bool
            @trigger('blocked:change', @blocked)

        getSidebarState: -> @sidebarState

        getRootTimeline: -> @rootTimeline

        activateChapterByIndex: (index) ->
            @sidebarState.activateChapterByIndex(index)

        activateElementByIndex: (index, options) ->
            @sidebarState.getActiveChapter().activateElementByIndex(index,
                                                                    options)

        activateElementByActivityId: (activityId, options) ->
            @sidebarState.activateElementByActivityId(activityId, options)

        onRootTimelineUpdate: -> @updateSidebarState()

        onRootTimelineProgressChange: ->
            activityId = @controller.getDestinationActivityId()
            if activityId?
                @activateElementByActivityId(activityId)
            else
                @activateChapterByIndex(@rootTimeline.getStationPosition())

        onTitleImageChange: -> @updateSidebarState()


    module.exports =
        SidebarTimeline: SidebarTimeline
