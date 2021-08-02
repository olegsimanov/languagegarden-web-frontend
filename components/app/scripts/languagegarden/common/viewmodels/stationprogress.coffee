    'use strict'

    {EventObject} = require('./../events')
    {enumerate} = require('./../utils')
    {buildPropertySupportPrototype} = require('./../properties')


    TimelineSupportPrototype = buildPropertySupportPrototype('timeline')


    class StationTimeline extends EventObject.extend(TimelineSupportPrototype)

        initialize: (options) ->
            super
            @setTimeline(options.timeline)

        onTimelineBind: ->
            super
            @setupEventForwarding(@timeline,
                                  ['progresschange', 'annotationschange'])

        getAnnotations: -> {}

        setProgressTime: (time) ->
            @timeline.setStationPosition(Math.round(time))

        getProgressTime: ->
            @timeline.getStationPosition()

        getTotalTime: ->
            @timeline.getStationsLength()


    module.exports =
        StationTimeline: StationTimeline
