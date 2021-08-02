    'use strict'

    _ = require('underscore')
    $ = require('jquery')
    require('jquery.cookie')
    settings = require('./../../settings')
    config = require('./../../config')
    {Point} = require('./../../math/points')
    {enumerate, generateRanges, pathJoin} = require('./../utils')
    {OperationType} = require('./../diffs/operations')
    {
        applyDiff
        getInvertedDiffs
        rewindUsingDiffs
    } = require('./../diffs/utils')
    {rebaseDiffs} = require('./../diffs/rebasing')
    {reduceDiff} = require('./../diffs/reductions')
    {findCriticalDiffPositions} = require('./../autokeyframes')
    {PlantElements} = require('./elements')
    {PlantMedium, PlantMedia} = require('./media')
    {PlantChanges, UnitChange} = require('./changes')
    {Stations} = require('./stations')
    {BaseModelWithSubCollections} = require('./base')
    {MediumType, ActivityType, VisibilityType} = require('./../constants')
    {UnitDataCache} = require('../datacache')


    # This is based on IPad I resolution
    SIDEBAR_WIDTH = 120
    DEFAULT_CANVAS_WIDTH = 1004 - SIDEBAR_WIDTH
    DEFAULT_CANVAS_HEIGHT = 462


    wrapError = (model, options) ->
        error = options.error
        options.error = (resp) ->
            error?(model, resp, options)
            model.trigger('error', model, resp, options)


    class UnitState extends BaseModelWithSubCollections
        subCollectionConfig: [
            name: 'elements'
            collectionClass: PlantElements
        ,
            name: 'media'
            collectionClass: PlantMedia
        ,
            name: 'stations'
            collectionClass: Stations
        ]

        # add childchange to support nesting in stations collection
        forwardedEventNames: [
            'childchange',
        ].concat(BaseModelWithSubCollections::forwardedEventNames)

        initialize: (options) ->
            super
            @setDefaultAttributes()

        setDefaultAttributes: ->
            @setDefaultValue('bgColor', '#FFFFFF')
            if not (MediumType.TEXT_TO_PLANT in @media.pluck('type'))
                @media.add
                    type: MediumType.TEXT_TO_PLANT
                    textElements: []

        get: (attr) ->
            if attr in @getSubCollectionNames()
                @[attr].toJSON()
            else if attr == 'inPlantToTextMode'
                @media.any((medium) -> medium.get('inPlantToTextMode'))
            else
                super

        rewindUsingDiffs: (diffs, currentPosition, position, options) ->
            positionDifference = position - currentPosition
            if positionDifference == 0
                # no rewinding, quitting!
                return 0
            snapshot = @toJSON()
            snapshot = rewindUsingDiffs(snapshot, diffs,
                                        currentPosition, position)
            @set(snapshot, options)
            return positionDifference

        stopTrackingChanges: -> @trigger('trackchanges', this, false)

        startTrackingChanges: -> @trigger('trackchanges', this, true)

        addElement: (model, options) -> @elements.add(model, options)

        removeElement: (model, options) -> @elements.remove(model, options)

        addMedium: (model, options) -> @media.add(model, options)

        removeMedium: (model, options) -> @media.remove(model, options)

        onSubCollectionChange: (sender, ctx) ->
            super
            @trigger('childchange', sender, this, ctx)

        setupActivity: (options={}) ->
            switch options.activityType
                when ActivityType.PLANT_TO_TEXT
                    @_setupPlantToTextActivity()
                when ActivityType.PLANT_TO_TEXT_MEMO
                    @_setupPlantToTextActivity()
                when ActivityType.DICTIONARY
                    @_setupDictionaryActivity()
                when ActivityType.CLICK
                    @_setupClickActivity()

        _setupPlantToTextActivity: ->
            p2tNoteData =
                type: MediumType.PLANT_TO_TEXT_NOTE
                inPlantToTextMode: true
            @media.add(p2tNoteData, silent: true)
            for element in @elements.models
                element.set('visibilityType', VisibilityType.PLANT_TO_TEXT_FADED,
                            silent: true)
            @trigger('change', this)
            return

        _setupDictionaryActivity: ->

        _setupClickActivity: ->
            instructionNoteData =
                type: MediumType.INSTRUCTIONS_NOTE
                text: ''
            @media.add(instructionNoteData, silent: true)

            for element in @elements.models
                element.set('marked', false, silent: true)
            @trigger('change', this)
            return


    class UnitData extends BaseModelWithSubCollections
        subCollectionConfig: [
            name: 'initialState'
            modelClass: UnitState
        ,
            name: 'changes'
            collectionClass: PlantChanges
        ,
            name: 'titleImage'
            modelConstructor: ->
                PlantMedium.fromJSON
                    type: MediumType.IMAGE
        ]

        # add childchange to support nesting in stations collection
        forwardedEventNames: [
            'childchange',
        ].concat(BaseModelWithSubCollections::forwardedEventNames)

        forwardedAttrsMap:
            'id': 'id'
            'title': 'title'
            'description': 'description'
            'color_palette': 'colorPalette'
            'active': 'public'
        plantDataAttrName: 'data'

        initialize: (options) ->
            super
            @setDefaultAttributes()

        setDefaultAttributes: ->
            @setDefaultValue('title', '')
            @setDefaultValue('description', '')
            @setDefaultValue('language', 'English')
            @setDefaultValue('colorPalette', 'default')
            @setDefaultValue('public', true)
            @setDefaultValue('version', '0.7')
            @setDefaultValue('canvasWidth', DEFAULT_CANVAS_WIDTH)
            @setDefaultValue('canvasHeight', DEFAULT_CANVAS_HEIGHT)
            @setDefaultValue('activityType', ActivityType.MOVIE)
            @setDefaultValue('textDirection', 'ltr')

        validate: (attrs, options) ->
            if not (attrs.textDirection in ['ltr', 'rtl'])
                return 'invalid textDirection'
            return

        get: (attr) ->
            if attr in @getSubCollectionNames()
                @[attr].toJSON()
            else
                super

        toJSON: (options) ->
            data = super
            if options?.unparse
                # we are passing unparse option in the sync
                @unparse(data)
            else
                data

        parse: (response, options) ->
            data = JSON.parse(response[@plantDataAttrName])
            if data
                for name, forwardName of @forwardedAttrsMap
                    data?[forwardName] = response?[name]
            data

        unparse: (data) ->
            response = {}
            data = _.clone(data)
            for name, forwardName of @forwardedAttrsMap
                response[name] = data[forwardName]
            delete data[@idAttribute]
            response[@plantDataAttrName] = JSON.stringify(data)
            response

        url: ->
            id = @get(@idAttribute)
            urlRoot = _.result(this, 'urlRoot')

            if id?
                urlPrefix = pathJoin(urlRoot, encodeURIComponent(id))
            else
                urlPrefix = urlRoot
            url = pathJoin(urlPrefix, '/')
            url

        getCachePayload: (id) -> null

        sync: (method, model, options) ->
            options ?= {}
            if method == 'read' and options.success? and @has('id')
                # special case for fetching lesson/activity - trying to find
                # the payload in cache
                result = @getCachePayload(@get('id'))
                if result?
                    # success callback was constructed in Backbone.Model::fetch
                    # so we use it to update the model
                    setTimeout((-> options.success(result)), 0)
                    # TODO: mock XHR object which is returned by sync
                    return

            options.unparse = true

            if method != 'read'
                originalBeforeSend = options.beforeSend
                options.beforeSend = (xhr) ->
                    csrftoken = $.cookie('csrftoken')
                    xhr.setRequestHeader('X-CSRFToken', csrftoken);
                    originalBeforeSend?(xhr)

            super


        getDiffs: -> @changes.getDiffsSlice()

        getDiffsSlice: (beginIndex, endIndex) ->
            @changes.getDiffsSlice(beginIndex, endIndex)

        getChangesSettings: ->
            @changes.map (change) ->
                data = change.toJSON()
                delete data.operations
                data

        getDiffsLength: -> @changes.length

        getChangesSlice: (beginIndex, endIndex) ->
            @changes.slice(beginIndex, endIndex)

        getRewindedState: (rewindPos) ->
            state = @initialState.deepClone()
            if not rewindPos?
                rewindPos = @getDiffsLength()
            state.rewindUsingDiffs(@getDiffs(), 0, rewindPos)
            state

        pushDiff: (diff, options) ->
            changeData =
                operations: diff
            @changes.add(changeData, options)

        popDiff: (diff, options) ->
            position = options?.at

            if not position?
                position = @getDiffsLength()

            if position == 0
                return false

            change = @changes.at(position - 1)
            @changes.remove(change)

        squash: (options={}) ->
            opts =
                silent: options.silent

            diffPosition = options.diffPosition
            diffPosition ?= @getDiffsLength()

            @initialState.rewindUsingDiffs(@getDiffs(), 0, diffPosition, opts)
            @changes.reset([], opts)
            @initialState.stations.reset([], opts)

        ###
        Groups adjacent positions, returning the last position for each
        adjacent group. The result is a list of these "last" positions.
        ###
        groupAdjacentPositions: (positions) ->
            if positions.length == 0
                return []
            lastPos = positions[0]
            lastPositions = []
            for pos in positions
                if lastPos + 1 < pos
                    lastPositions.push(lastPos)
                lastPos = pos
            lastPositions.push(lastPos)
            lastPositions

        filterChangePositions: (predicate, group=false) ->
            positions = []
            for [i, model] in enumerate(@changes.models)
                if predicate(model)
                    positions.push(i + 1)
            if group
                positions = @groupAdjacentPositions(positions)
            positions

        getOnlyKeyFramePositions: ->
            predicate = (change) -> change.get('keyFrame')
            @filterChangePositions(predicate)

        getKeyFramePositions: ->
            # we assume that stations are also keyframes
            onlyKeyFramePositions = @getOnlyKeyFramePositions()
            stationPositions = @getStationPositions()
            # TODO: this can be done faster using linear merging of two
            # sorted arrays
            keyFramePositions = onlyKeyFramePositions.concat(stationPositions)
            keyFramePositions = _.sortBy(keyFramePositions)
            keyFramePositions = _.uniq(keyFramePositions, true)
            keyFramePositions

        ###
        Returns the "true" station positions. "True" station position is:
        * position of station insertion if it has no activities,
        * position of last activity change operation just after
          station insertion if this station has any activities.
        ###
        getTrueStationPositions: ->
            positions = []
            for [i, change] in enumerate(@changes.models)
                if change.isStationInsert()
                    # push current change position, if there are activities,
                    # else will take care of cleaning up
                    positions.push(i + 1)
                else if change.isActivityChange()
                    # assuming that activities can can only be added after a
                    # station they belong to, just change last index up by one
                    positions[positions.length - 1] = i + 1
            positions

        ###
        Alias of getTrueStationPositions, for deprecated usage
        ###
        getStationPositions: -> @getTrueStationPositions()

        ###
        Returns all station positions, where the first station position is
        always 0, and the last one is getDiffsLength()
        ###
        getAllStationPositions: ->
            positions = @getTrueStationPositions()
            if positions.length == 0 or positions[0] != 0
                positions = [0].concat(positions)

            diffsLength = @getDiffsLength()

            if positions[positions.length - 1] != diffsLength
                positions.push(diffsLength)

            positions

        cloneActivityTemplate: (options) ->
            modelCopy = @deepClone(ActivityData)

            # remove the plant id
            modelCopy.unset(@idAttribute)

            # remove changes
            modelCopy.squash(options)

            activityType = options.activityType or ActivityType.DICTIONARY

            modelCopy.set('parentId', @id)
            modelCopy.set('activityType', activityType)
            modelCopy.set('description', '')
            modelCopy.set('title', 'Unnamed Activity')
            modelCopy

        deepClone: (constructor) ->
            constructor ?= @constructor
            modelCopy = new constructor(@toJSON())
            modelCopy

        getRebasedDiffs: (rebasingDiff, startDiffPosition) ->
            allDiffs = @getDiffs()
            diffsToRebase = allDiffs[startDiffPosition..]
            rebaseDiffs(rebasingDiff, diffsToRebase)

        getRebasedChanges: (rebasingDiff, startDiffPosition) ->
            changeClass = PlantChanges.model
            allChangesSettings = @getChangesSettings()
            rebasedChangesSettings = allChangesSettings[startDiffPosition..]
            rebasedDiffs = @getRebasedDiffs(rebasingDiff, startDiffPosition)
            pairs = _.zip(rebasedDiffs, rebasedChangesSettings)
            for [rebasedDiff, settings] in pairs
                if rebasedDiff.length == 0
                    continue
                attributes = _.extend({}, settings, operations: rebasedDiff)
                new changeClass(attributes)

        resetChanges: (models, options) ->
            @changes.reset(models, options)

        _isStationRelatedOp: (op) ->
            ctxNames = op.getContextNames()
            ctxNames.length >= 2 and ctxNames[0] == 'stations'

        _isStationRelatedDiff: (diff) -> _.all(diff, @_isStationRelatedOp, this)

        ###
        duplicates the state at diffPosition (e.g. the initial state with
        applied first diffPosition changes) at the "end" of the data model
        timeline.
        ###
        duplicateState: (diffPosition, options) ->
            diffs = @getDiffs()
            diffs = diffs[diffPosition..]
            diffs = (diff for diff in diffs when not @_isStationRelatedDiff(diff))

            positions = findCriticalDiffPositions(diffs)

            reducedDiffs = []
            for [start, end] in generateRanges(positions, diffs.length)
                reducedDiffs.push(reduceDiff(_.flatten(diffs[start...end])))

            revDiffs = getInvertedDiffs(reducedDiffs)
            for revDiff in revDiffs
                change = new UnitChange
                    operations: revDiff
                @changes.add(change, options)
            return


    class LessonData extends UnitData
        urlRoot: -> config.getUrlRoot(settings.apiResourceNames.lessons)
        forwardedAttrsMap: _.extend({}, UnitData::forwardedAttrsMap,
            'categories': 'categories'
            'levels': 'levels'
        )

        setDefaultAttributes: ->
            super
            @setDefaultValue('categories', [])
            @setDefaultValue('levels', [])

        getCachePayload: (id) ->
            cache = UnitDataCache.getInstance()
            cache.getLessonPayload(id)

    class ActivityData extends UnitData
        urlRoot: -> config.getUrlRoot(settings.apiResourceNames.activities)
        forwardedAttrsMap: _.extend({}, UnitData::forwardedAttrsMap,
            'type': 'activityType'
            'lesson': 'parentId'
        )

        getCachePayload: (id) ->
            cache = UnitDataCache.getInstance()
            cache.getActivityPayload(id)


    module.exports =
        UnitState: UnitState
        LessonData: LessonData
        ActivityData: ActivityData
        SIDEBAR_WIDTH: SIDEBAR_WIDTH
