    'use strict'

    _ = require('underscore')
    {EventObject} = require('./events')
    {enumerate} = require('./utils')


    class Timeline extends EventObject

        constructor: (options) ->
            super
            @syncStateModel(silent: true)
            @recalculateStationDiffPositions()

        initialize: (options) ->
            super
            @setPropertyFromOptions(options, 'controller', required: true)
            @setPropertyFromOptions(options, 'stateModel', required: true)
            @setPropertyFromOptions(options, 'dataModel', required: true)
            @setPropertyFromOptions(options, 'diffPosition')
            @listenTo(@dataModel, 'change:changes', @onModelChangesChange)
            @listenTo(@stateModel, 'change', @onModelChange)

        getDataModel: -> @dataModel

        getSnapshotModel: -> @stateModel

        getStateModel: -> @stateModel

        syncStateModel: (options) ->
            @diffPositionEndDelta = @dataModel.getDiffsLength()
            @stateModel.set(@dataModel.initialState.toJSON(), options)

        _setDiffPosition: (diffPosition, options) ->
            @diffPositionEndDelta = @getDiffsLength() - diffPosition
            if not options?.silent
                @trigger('progresschange', this)
            return

        rewind: (diffPosition, options) ->
            oldDiffPosition = @getDiffPosition()
            @stateModel.rewindUsingDiffs(@dataModel.getDiffs(),
                                         oldDiffPosition, diffPosition, options)
            @_setDiffPosition(diffPosition, options)

        rewindToEnd: (options) ->
            @rewind(@getDiffsLength(), options)

        isRewindedAtEnd: -> @getDiffPosition() == @getDiffsLength()

        getDiffPosition: ->
            diffPositon = @getDiffsLength() - @diffPositionEndDelta
            diffPositon

        getDiffsLength: -> @dataModel.getDiffsLength()

        getStationDiffPositions: -> @dataModel.getStationPositions()

        recalculateStationDiffPositions: ->
            positions = @getStationDiffPositions()
            positions = [0].concat(positions)

            diffsLength = @getDiffsLength()

            if positions[positions.length - 1] != diffsLength
                positions.push(diffsLength)

            # remove all duplicated station positions
            positions = _.uniq(positions, true)

            @stationDiffPositions = positions

        getStationPositionByDiffPosition: (diffPosition) ->
            previousStationPos = -1
            for [i, stationPos] in enumerate(@stationDiffPositions)
                if (previousStationPos <= diffPosition and
                        diffPosition < stationPos)
                    return i - 1
                previousStationPos = stationPos
            # assert diffPosition == @getDiffsLength()
            @getStationsLength()

        getDiffPositionByStationPosition: (stationPosition) ->
            @stationDiffPositions[stationPosition]

        setProgressTime: (time) -> @rewind(Math.round(time))

        getStationPosition: ->
            @getStationPositionByDiffPosition(@getDiffPosition())

        getStationsLength: -> @stationDiffPositions.length - 1

        setStationPosition: (stationPosition) ->
            @rewind(@getDiffPositionByStationPosition(stationPosition))

        getProgressTime: -> @getDiffPosition()

        getTotalTime: -> @getDiffsLength()

        getAnnotations: -> {}

        isPlaying: -> false

        getTargetPosition: -> @getStationPosition()

        _getModelStations: ->
            state = @dataModel.initialState.deepClone()
            endPos = @dataModel.getDiffsLength()
            state.rewindUsingDiffs(@dataModel.getDiffs(), 0, endPos)
            state.stations.slice(0)

        getModelStations: ->
            if not @_modelStations?
                @_modelStations = @_getModelStations()
            @_modelStations

        isLastChangeActivityOrStation: ->
            lastChange = @dataModel.changes.at(@getDiffPosition() - 1)
            if not lastChange?
                return false
            lastChange.isStationInsert() or lastChange.isActivityChange()

        getCurrentStation: ->
            if not @isLastChangeActivityOrStation()
                # an empty station for when there are some changes after last
                # station or last station's activities and do not have an
                # explicit station model
                return {implicit: true}

            @stateModel.stations.last()

        getCurrentActivityLinksCollection: ->
            @getCurrentStation()?.activityLinks

        getCurrentActivityLinks: ->
            @getCurrentStation()?.activityLinks?.models.slice(0) or []

        onModelChangesChange: ->
            @_modelStations = null
            @recalculateStationDiffPositions()
            @trigger('progresschange', this)
            @trigger('annotationschange', this)

        onModelChange: ->
            @_modelStations = null
            @trigger('progresschange', this)
            @trigger('annotationschange', this)


    module.exports =
        Timeline: Timeline
