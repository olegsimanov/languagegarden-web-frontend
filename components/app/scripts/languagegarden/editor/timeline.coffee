    'use strict'

    _ = require('underscore')
    {
        applyDiff
        getInvertedDiff
        rewindUsingDiffs
    } = require('./../common/diffs/utils')
    {rebaseDiffs} = require('./../common/diffs/rebasing')
    {Timeline} = require('./../common/timeline')


    class EditorTimeline extends Timeline

        constructor: (options) ->
            super
            @rewindToEnd()

        initialize: (options) ->
            super
            @setPropertyFromOptions(options, 'history', required: true)
            @listenTo(@history, 'pushdiff', @onPushDiff)
            @listenTo(@history, 'popdiff', @onPopDiff)
            @trackingDisabled = false

        remove: ->
            @stopListening(@history)
            super

        getAnnotations: ->
            throw 'not implemented'
            annotations = {}
            for pos in @model.getKeyFramePositions()
                annotations[pos] ?= []
                annotations[pos].push('keyframe')
            for pos in @model.getStationPositions()
                annotations[pos] ?= []
                annotations[pos].push('station')
            annotations

        disabledTrackingBegin: (options) ->
            @trackingDisabled = true
            @_oldTrackChanges = @history.trackChanges
            @history.trackChanges = false

        disabledTrackingEnd: (options) ->
            @history.trackChanges = @_oldTrackChanges
            @history.makeInitialSnapshot(options)
            @trackingDisabled = false

        syncStateModel: (options) ->
            @disabledTrackingBegin(options)
            result = super
            @disabledTrackingEnd(options)
            result

        rewind: (diffPosition, options) ->
            @disabledTrackingBegin(options)
            result = super
            @disabledTrackingEnd(options)
            result

        saveModel: (options={}) ->
            success = options.success or ->
            error = options.error or ->

            @dataModel.save {},
                success: =>
                    @history.markAsSaved()
                    success()
                error: error

        loadModel: (id, options={}) ->
            if @dataModel.id == id or id == 0
                return

            success = options.success or ->
            error = options.error or ->

            @dataModel.clear(silent: true)
            @dataModel.set('id', id, silent: true)
            @dataModel.fetch
                success: =>
                    @syncStateModel(silent: true)
                    @rewindToEnd()
                    success()
                error: error

        createEmptyModel: ->
            @dataModel.clear(silent: true)
            @dataModel.initialState.setDefaultAttributes()
            @dataModel.setDefaultAttributes()
            @syncStateModel(silent: true)
            @rewindToEnd
                savedPosition: -1


        ###Builder has requested a new station, sometimes it's not neccessary
        to add a station, as it may be implicit.
        ###
        capWithStation: ->
            # skip adding station just after last activity of previous one
            pos = @getDiffPosition()
            if pos == 0
                return false
            change = @dataModel.changes.at(pos - 1)
            if change.isActivityChange() or change.isStationInsert()
                return false

            @stateModel.stations.add({})

        ###Whenever an activityLink is added it must follow a station or an
        existing activityLink.
        ###
        addActivityLink: (model) ->
            @capWithStation()
            @getCurrentStation().activityLinks.add(model)

        removeActivityLink: (model) ->
            if model.activityId?
                model = @getCurrentActivityLinksCollection().find(
                    (a) => a.get('activityId') == model.activityId
                )
            @getCurrentStation().activityLinks.remove(model)

        repositionActivityLink: (sourceIndex, targetIndex, options) ->
            collection = @getCurrentActivityLinksCollection()
            models = collection.models
            models.splice(targetIndex, 0, models.splice(sourceIndex, 1)[0])
            collection.set(models, options)

        deleteCurrentStation: ->
            endDiffPosition = @getDiffPosition()
            endStationPos = @getStationPositionByDiffPosition(endDiffPosition)
            if endStationPos == 0
                return
            startStationPos = endStationPos - 1
            startDiffPosition = @getDiffPositionByStationPosition(startStationPos)
            @rewind(startDiffPosition)
            previousChanges = @dataModel.getChangesSlice(0, startDiffPosition)
            diffsToRemove = @dataModel.getDiffsSlice(startDiffPosition,
                                                     endDiffPosition)
            rebasingDiff = getInvertedDiff(_.flatten(diffsToRemove))
            rebasedChanges = @dataModel.getRebasedChanges(rebasingDiff,
                                                          endDiffPosition)
            @dataModel.resetChanges(previousChanges.concat(rebasedChanges))

        onPushDiff: (source, model, diff) ->
            if @trackingDisabled
                return
            pos = @getDiffPosition()
            @dataModel.pushDiff(diff, at: pos)

        onPopDiff: (source, model, diff) ->
            if @trackingDisabled
                return
            pos = @getDiffPosition()
            @dataModel.popDiff(diff, at: pos)


    module.exports =
        Timeline: EditorTimeline
