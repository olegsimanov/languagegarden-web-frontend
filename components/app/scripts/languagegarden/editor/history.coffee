    'use strict'

    _ = require('underscore')
    {deepCopy, structuralEquals} = require('./../common/utils')
    {
        getDiff
        getTextDiff
        applyDiff
        getInvertedDiff
    } = require('./../common/diffs/utils')
    {EventObject} = require('./../common/events')
    {MediumType} = require('./../common/constants')


    class History extends EventObject

        initialize: (options) ->
            super
            @trackChanges = true
            @setPropertyFromOptions(options, 'model', required: true)
            @makeInitialSnapshot()
            @listenTo(@model, 'change', @onModelChange)
            @listenTo(@model, 'childchange', @onModelChange)
            @listenTo(@model, 'trackchanges', @onModelTrackChanges)

        remove: ->
            @stopListening(@model)
            super

        ###
        Getters/predicates
        ###

        isUndoAvailable: -> @position > 0

        isRedoAvailable: -> @position < @diffs.length

        isAtSavedPosition: -> @savedPosition == @position

        canUndoToSavedPosition: ->
            @savedPosition >= 0 and @savedPosition <= @position

        isModelSaved: -> @isAtSavedPosition()

        getModelSnapshot: ->
            snapshot = @model.toJSON()
            # Because the ids of the model may change during time (and this
            # does not affect the model structure) we delete them from the
            # snapshot.
            delete snapshot[@model.idAttribute]
            snapshot

        pushDiffToDataModel: (diff) ->
            @trigger('pushdiff', this, @model, diff)

        popDiffFromDataModel: (diff) ->
            @trigger('popdiff', this, @model, diff)


        ###
        Trigger functions
        ###

        changeUndoAvailable: -> @trigger('change:undoAvailable', this)

        changeRedoAvailable: -> @trigger('change:redoAvailable', this)

        changeModelSaved: -> @trigger('change:modelSaved', this)

        selectChange: -> @trigger('selectchange', this)

        fireChangeEvents: ->
            @changeUndoAvailable()
            @changeRedoAvailable()
            @changeModelSaved()

        ###
        Undo/Redo helpers
        ###

        makeSnapshot: ->
            #using the ... notation because [0..-1] != [0...0]
            snapshot = @getModelSnapshot()
            if @position < @savedPosition
                # the saved history point will be overriden, so we
                # setting it to a 'impossible' position number, which will
                # cause the save state to be dirty
                @savedPosition = -2

            options =
                replacementContextPatterns: [
                    /^elements.[0-9]+.lettersAttributes.[0-9]+.labels$/
                ]

            diff = getDiff(@currentSnapshot, snapshot, options)

            @diffs = (@diffs[0...@position]).concat([diff])
            @pushDiffToDataModel(diff)
            @position += 1

            @currentSnapshot = snapshot

            @fireChangeEvents()
            true

        makeInitialSnapshot: (options={}) ->
            @currentSnapshot = @getModelSnapshot()
            @diffs = []
            @position = @diffs.length
            @savedPosition = if options.savedPosition? then options.savedPosition else @diffs.length
            @fireChangeEvents()
            true

        ###
        Undo/Redo interface
        ###

        undo: ->
            if @isUndoAvailable()
                diff = @diffs[@position - 1]
                invDiff = getInvertedDiff(diff)
                snapshot = applyDiff(deepCopy(@currentSnapshot), invDiff)
                # temporarily disable tracking changes
                oldTrackChanges = @trackChanges
                @trackChanges = false
                if @model.set(snapshot) != false
                    @trackChanges = oldTrackChanges
                    @currentSnapshot = snapshot
                    @position -= 1
                    @popDiffFromDataModel(diff)
                    @fireChangeEvents()
                    # firing 'selectchange' because all selections are now lost
                    @selectChange()
                    true
                else
                    @trackChanges = oldTrackChanges
                    false
            else
                false

        redo: ->
            if @isRedoAvailable()
                diff = @diffs[@position]
                snapshot = applyDiff(deepCopy(@currentSnapshot), diff)
                # temporarily disable tracking changes
                oldTrackChanges = @trackChanges
                @trackChanges = false
                if @model.set(snapshot) != false
                    @trackChanges = oldTrackChanges
                    @currentSnapshot = snapshot
                    @position += 1
                    @pushDiffToDataModel(diff)
                    @fireChangeEvents()
                    # firing 'selectchange' because all selections are now lost
                    @selectChange()
                    true
                else
                    @trackChanges = oldTrackChanges
                    false
            else
                false

        _makeChangeSnapshot: ->
            snapshot = @getModelSnapshot()
            if not structuralEquals(snapshot, @currentSnapshot)
                @makeSnapshot()
            else
                false

        markAsSaved: ->
            @savedPosition = @position
            @changeModelSaved()

        ###
        Event listeners
        ###
        onModelChange: (senderModel, plantModel) ->

            if not @trackChanges
                return

            @_makeChangeSnapshot()

        onModelTrackChanges: (model, flag) ->

            oldTrackChanges = @trackChanges
            @trackChanges = flag
            if not oldTrackChanges and @trackChanges
                @onModelChange()


    module.exports =
        History: History
