    'use strict'

    _ = require('underscore')
    {enumerate, deepCopy, avg} = require('./../common/utils')
    {
        applyDiff
        getInvertedDiff
        getInvertedDiffs
        rewindUsingDiffs
    } = require('./../common/diffs/utils')
    {reduceDiff} = require('./../common/diffs/reductions')
    {
        ParallelAnimation
        SerialAnimation
    } = require('./../common/animations/animations')
    {Timeline} = require('./../common/timeline')
    settings = require('./../settings')
    {PlaybackMode} = require('./constants')
    {Metrics} = require('./../metrics/models/metrics')
    {getDefaultDiffData} = require('./customdiffs/base')
    {findAutoKeyFramePositions} = require('./../common/autokeyframes')


    class PlayerTimeline extends Timeline

        playbackMode: PlaybackMode.DEFAULT

        initialize: (options={}) ->
            super
            @setPropertyFromOptions(options, 'canvasView', required: true)
            @setPropertyFromOptions(options, 'textBoxView', required: true)

            @setupDiffsAndPosition()

            @listenTo(@dataModel, 'plantredirect', @onPlantRedirect)
            @listenTo(@stateModel, 'plantredirect', @onPlantRedirect)
            @listenTo(@controller, 'sync:dataModel', @onModelSync)

            @setPropertyFromOptions(options, 'startPosition', default: 0)
            @setPropertyFromOptions(options, 'useKeyframes', default: true)
            @setPropertyFromOptions(options, 'playbackMode')
            @setPropertyFromOptions(options, 'getCustomDiffData',
                                    optionName: 'customDiffDataGenerator')

            @animationFPSData = []
            @targetPosition = null

        remove: ->
            @pause()
            @textBoxView = null
            @canvasView = null
            super

        getMetric: -> @controller.getMetric().subMetric("playertimeline")

        getCustomDiffData: -> null

        getModelStations: -> @modelStations.slice(0)

        setupDiffsAndPosition: ->
            endState = @dataModel.getRewindedState()
            @modelStations = endState.stations.deepClone()
            @originalStationDiffPositions = @dataModel.getStationPositions()
            @originalDiffs = (changeModel.get('operations') for changeModel in @dataModel.changes.models)

            @keyFramePositions = @dataModel.getKeyFramePositions()
            @currentSnapshotPosition = 0
            @currentSnapshot = @dataModel.initialState.toJSON()
            @currentFramePosition = 0
            @currentAnimation = null
            @playing = false

            @mergeDiffs()

            if @startPosition > 0
                @rewind(@startPosition)
            else if @startPosition < 0
                @rewind(@getTotalTime())

            @updateView()

            if @targetPosition?
                if @startPosition < @targetPosition
                    @play()
                else if @targetPosition < @startPosition
                    @play(true)

        setupStartPosition: (position, previousPosition) ->
            position = parseInt(position, 10)
            previousPosition ?= position
            previousPosition = parseInt(previousPosition, 10)
            delta = previousPosition - position
            if delta != 0
                @targetPosition = position
            else
                @targetPosition = null
            @startPosition = previousPosition
            return

        getTargetPosition: ->
            if @targetPosition?
                @targetPosition
            else
                @startPosition

        setUseKeyframes: (useKeyframes) ->
            if @useKeyframes == useKeyframes
                # use keyframes already set, nothing to do there
                return
            @rewind(0)
            @useKeyframes = useKeyframes
            @mergeDiffs()
            @updateView()

        ###
        Calculated this.diffs using the original plant diffs and keyFrames
        setting.

        assert @currentSnapshotPosition == 0
        ###
        mergeDiffs: ->
            inputData =
                dataSnapshot: @dataModel.toJSON()
                originalDiffs: @originalDiffs
                startSnapshot: @dataModel.initialState.toJSON()
                stationPositions: @dataModel.getTrueStationPositions()
                useKeyframes: @useKeyframes
                keyFramePositions: @keyFramePositions

            customDiffData = @getCustomDiffData(inputData)
            customDiffData ?= getDefaultDiffData(inputData)
            if customDiffData.diffsList?
                @diffsList = customDiffData.diffsList
            else
                @diffsList = ([diff] for diff in customDiffData.diffs)
            @stationPositions = customDiffData.stationPositions or []

            if customDiffData.activityStartSnapshot?
                @activityStartSnapshot = customDiffData.activityStartSnapshot

            if customDiffData.startSnapshot?
                @startSnapshot = customDiffData.startSnapshot
                @activityStartSnapshot ?= @startSnapshot
                @currentSnapshot = deepCopy(@startSnapshot)

            if customDiffData.endSnapshot?
                @endSnapshot = customDiffData.endSnapshot

            @recalculateStationDiffPositions()
            @triggerChange()

        triggerChange: ->
            @trigger('progresschange', this)
            @trigger('annotationschange', this)

        generateAnimations: ->
            @diffAnimations = []
            @diffReverseAnimations = []
            for [i, diffs] in enumerate(@diffsList)
                do =>
                    parallelAnimations = []
                    parallelRevAnimations = []

                    # We are using reduceDiff because we want the diff(s) in
                    # the form:
                    # - insert obj at index=0
                    # - replace property1 at index=0
                    # - replace property2 at index=0
                    invDiffs = (reduceDiff(idiff) for idiff in getInvertedDiffs(diffs))
                    nextPos = i + 1
                    prevPos = i

                    for diff in diffs
                        diffAnimation = new ParallelAnimation
                            animations: @canvasView.getAnimations(
                                diff,
                                reverseDiffFlag: false
                            )
                            debugInfo:
                                diff: diff
                        parallelAnimations.push(diffAnimation)

                    for invDiff in invDiffs
                        diffRevAnimation = new ParallelAnimation
                            animations: @canvasView.getAnimations(
                                invDiff,
                                reverseDiffFlag: true
                            )
                            debugInfo:
                                diff: invDiff
                        parallelRevAnimations.push(diffRevAnimation)

                    serialAnimation = new SerialAnimation
                        animations: parallelAnimations
                        endCallback: => @onFrameUpdate(this, nextPos, false)
                    serialRevAnimation = new SerialAnimation
                        animations: parallelRevAnimations
                        endCallback: => @onFrameUpdate(this, prevPos, true)
                    @diffAnimations.push(serialAnimation)
                    @diffReverseAnimations.push(serialRevAnimation)

            return

        isPlaying: -> @playing

        setPlayback: (playing) ->
            if playing != @playing
                @playing = playing
                @trigger('playbackchange', this)

        setFramePosition: (framePos) ->
            if framePos != @currentFramePosition
                @currentFramePosition = framePos
                @trigger('progresschange', this)
                if @isRewindedAtEnd()
                    @trigger('progress:change:end', this)
                else if @currentFramePosition == 0
                    @trigger('progress:change:start', this)

        ###Updates the stations/keyframes/smooth playback mode.###
        setPlaybackMode: (playbackMode) ->
            if playbackMode != @playbackMode
                @playbackMode = playbackMode
                @trigger('playbackmodechange', this)

        ###
        Uses the frame diffs to rewind the snapshot to given position.
        ###
        rewindSnapshot: (framePos) ->
            difference = framePos - @currentSnapshotPosition
            diffs = (_.flatten(_diffs) for _diffs in @diffsList)
            @currentSnapshot = rewindUsingDiffs(
                @currentSnapshot,
                diffs,
                @currentSnapshotPosition,
                framePos
            )
            @currentSnapshotPosition = framePos
            difference

        ###
        Updates the view according to the current snapshot. Please remember
        that the current snapshot may not be containing the current frame,
        and should be rewinded using this.rewindSnapshot().
        ###
        updateView: ->
            @stateModel.set(@currentSnapshot)
            @updateTextBoxView()
            # the viewSelectors may be evaluated on non-existing subviews,
            # therefore we need to reload them
            @generateAnimations()

        updateTextBoxView: ->
            @textBoxView?.render()

        # assert snapshot is in sync with frame position
        # assert currentAnimation
        startCurrentFrame: (playBackwards=false) ->
            if playBackwards
                if @currentFramePosition > 0
                    @currentAnimation = @diffReverseAnimations[@currentFramePosition - 1]
                    @setPlayback(true)
                    @currentAnimation.start()
                else
                    @pause()
            else
                if @currentFramePosition < @getDiffsLength()
                    @currentAnimation = @diffAnimations[@currentFramePosition]
                    @setPlayback(true)
                    @currentAnimation.start()
                    @updateTextBoxView()
                else
                    if @groovyParent?
                        redirectInfo =
                            plantId: @groovyParent.id
                            startPosition: @groovyParent.startPosition
                            groovy: false
                        @redirectToPlant(redirectInfo)
                    else
                        @pause()

        play: (backwards=false, jumpAtStart=true) ->
            if not backwards and @isRewindedAtEnd()
                if jumpAtStart
                    # when we play forwards, and are at the end, then we
                    # move at the beginning
                    @setFramePosition(0)
                else
                    #do nothing
                    return

            @rewindSnapshot(@currentFramePosition)
            @updateView()
            @startCurrentFrame(backwards)

        pause: ->
            @currentAnimation?.stop()
            @currentAnimation = null
            @setPlayback(false)

        stop: ->
            @pause()
            @rewind(0)

        rewind: (framePos=0) ->
            wasPlaying = @playing
            @pause()
            @rewindSnapshot(framePos)
            @updateView()
            @setFramePosition(framePos)
            if wasPlaying
                @startCurrentFrame()

        hasNextFrame: -> not @isRewindedAtEnd()

        hasPreviousFrame: -> @currentFramePosition > 0

        playOneFrame: (backwards=false) ->
            @stopAfterFrame = true
            @play(backwards, false)

        setStationPosition: (stationPosition) ->
            @pause()
            super

        shiftToNextFrame: ->
            if @isPlaying()
                @stopAfterFrame = true
            else if @hasNextFrame()
                @playOneFrame()

        shiftToPreviousFrame: ->
            if @isPlaying()
                @stopAfterFrame = true
            else if @hasPreviousFrame()
                @playOneFrame(true)

        shiftToNextStation: ->
            fast = false
            if @isPlaying()
                @pause()
                fast = true
            if @hasNextFrame()
                if fast
                    @rewind(@currentFramePosition + 1)
                else
                    @play()
            return

        shiftToPreviousStation: ->
            fast = false
            if @isPlaying()
                @pause()
                fast = true
            if @hasPreviousFrame()
                if fast
                    @rewind(@currentFramePosition - 1)
                else
                    @play(true)
            return

        shiftToNextFrameOrStation: ->
            switch @playbackMode
                when PlaybackMode.STATIONS then @shiftToNextStation()
                else @shiftToNextFrame()

        shiftToPreviousFrameOrStation: ->
            switch @playbackMode
                when PlaybackMode.STATIONS then @shiftToPreviousStation()
                else @shiftToPreviousFrame()

        shouldStopPlayback: (framePos) ->
            if @playbackMode != PlaybackMode.SMOOTH
                if @targetPosition?
                    framePos == @targetPosition
                else
                    framePos in @stationPositions
            else
                false

        getAllActivityLinks: ->
            modelStations = @modelStations
            activityLinks = []
            for station in modelStations.models
                activityLinks.push(station.activityLinks.models...)
            activityLinks

        getActivityLinksByStationPosition: (position) ->
            modelStations = @modelStations
            if modelStations.length == 0
                return []
            if not position? or position == 0
                return []
            stationIndex = position - 1
            currentStation = modelStations.at(stationIndex)
            if not currentStation?
                return []
            currentStation.activityLinks.slice(0)

        getAllActivityIds: ->
            (al.get('activityId') for al in @getAllActivityLinks())

        getActivityIdsByStationPosition: (position) ->
            (al.get('activityId') for al in @getActivityLinksByStationPosition(
                position))

        getCurrentActivityLinks: ->
            position = @getStationPosition()
            @getActivityLinksByStationPosition(position)

        getCurrentActivityIds: ->
            position = @getStationPosition()
            @getActivityIdsByStationPosition(position)

        #TODO: deprecated, remove
        getActivityLinksByStationIndex: (stationIndex) ->
            @getActivityLinksByStationPosition(stationIndex + 1)

        #TODO: deprecated, remove
        getActivityIdsByStationIndex: (stationIndex) ->
            @getActivityLinksByStationPosition(stationIndex + 1)

        #TODO: deprecated, remove
        getCurrentStationIndex: ->
            @getStationPosition() - 1

        ###
        this event handler handles the animation ending
        ###
        onFrameUpdate: (sender, framePos, playBackwards) ->
            @updateFPSStats(@currentAnimation.getFinalFPS())
            @currentAnimation = null
            @setFramePosition(framePos)
            @updateTextBoxView()
            if @shouldStopPlayback(framePos)
                @targetPosition = null
                @pause()
            else if @stopAfterFrame
                @stopAfterFrame = false
                @targetPosition = null
                @pause()
            else
                # if position is not station, continue playback
                @startCurrentFrame(playBackwards)

        onPlantRedirect: (model, redirectInfo) ->
            @redirectToPlant(redirectInfo)

        onModelSync: ->
            @setupDiffsAndPosition()

        redirectToPlant: (redirectInfo) ->
            navigationInfo = _.extend {}, redirectInfo,
                type: 'play-plant'
                groovyParentId: @dataModel.get('id')
                groovyParentPosition: 0

            navigationInfo.groovy ?= true

            if @useKeyframes
                navigationInfo.groovyParentPosition = @currentFramePosition

            @trigger('navigate', this, navigationInfo)

        getStationDiffPositions: ->
            if @useKeyframes
                [0..@diffsList.length]
            else
                @originalStationDiffPositions

        getDiffPosition: -> @currentFramePosition

        getDiffsLength: -> @diffsList.length

        isRewindedAtEnd: -> @currentFramePosition == @diffsList.length

        getAnnotations: =>
            annotations = {}
            for pos in @stationPositions
                annotations[pos] = ['station']
            annotations

        updateFPSStats: (animFPS) ->
            if animFPS?
                @animationFPSData.push(animFPS)

        getFPSStats: ->
            minFPS = _.min(@animationFPSData)
            maxFPS = _.max(@animationFPSData)

            minFPS: Math.round(minFPS)
            maxFPS: Math.round(maxFPS)
            avgFPS: Math.round(avg(@animationFPSData))
            minFPSIndex: _.indexOf(@animationFPSData, minFPS)
            maxFPSIndex: _.indexOf(@animationFPSData, maxFPS)

        setActivityStartState: ->
            @stateModel.set(@activityStartSnapshot)


    module.exports =
        Timeline: PlayerTimeline
