    'use strict'

    {Action} = require('./base')
    {EditorMode} = require('./../constants')


    class HistoryAction extends Action
        trackingChanges: false

        initialize: (options) ->
            super
            @setPropertyFromOptions(options, 'history',
                                    default: @controller.history
                                    required: true)
        remove: ->
            delete @history
            super


    class Undo extends HistoryAction
        id: 'undo'

        initializeListeners: ->
            @listenTo(@history, 'change:undoAvailable', @triggerAvailableChange)

        perform: -> @history.undo()

        isAvailable: -> @history.isUndoAvailable()


    class Redo extends HistoryAction
        id: 'redo'

        initializeListeners: ->
            @listenTo(@history, 'change:redoAvailable', @triggerAvailableChange)

        perform: -> @history.redo()

        isAvailable: -> @history.isRedoAvailable()


    class Save extends HistoryAction
        id: 'save'

        initialize: (options) ->
            super
            @setPropertyFromOptions(options, 'onSaveSuccess')
            @setPropertyFromOptions(options, 'allowSaveWithoutChanges',
                                    default: false)

        initializeListeners: ->
            @listenTo(@history, 'change:modelSaved', @triggerAvailableChange)

        perform: ->
            while true
                title = @dataModel.get('title')
                if title? and title != ''
                    break
                newTitle = prompt('Please specify the name of the plant:')
                if not newTitle?
                    # cancel was pressed
                    return false
                @dataModel.set('title', newTitle)
            @timeline.saveModel
                success: => @onSaveSuccess()

        onSaveSuccess: ->

        isAvailable: ->
            if not @timeline.isRewindedAtEnd()
                return false
            if @allowSaveWithoutChanges
                return true
            not @history.isModelSaved()


    module.exports =
        Undo: Undo
        Redo: Redo
        Save: Save
