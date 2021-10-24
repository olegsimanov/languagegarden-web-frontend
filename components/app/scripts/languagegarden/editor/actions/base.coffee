    'use strict'

    {capitalize}        = require('./../utils')
    {EventsAwareClass}  = require('./../events')

    class Action extends EventsAwareClass

        id: 'action-id-undefined'

        constructor: (options) ->
            @initialize(options)
            @initializeListeners(options)

        initialize: (options)   -> @setPropertyFromOptions(options, 'controller', required: true)
        initializeListeners:    ->

        triggerAvailableChange: -> @trigger('change:available', this, @isAvailable())
        triggerToggledChange:   -> @trigger('change:toggled',   this, @isToggled())

        perform: ->

        isAvailable:            -> true
        isToggled:              -> false

        fullPerform: =>
            if not @isAvailable()
                return false
            @onPerformStart()
            @perform()
            @onPerformEnd()

        onPerformStart:         ->
        onPerformEnd:           ->

        getHelpTextFromId:      -> capitalize(@id).replace(/-/g, ' ')

        getHelpText: ->
            if @help?
                @help
            else
                @getHelpTextFromId()


    class UnitAction extends Action

        initialize: (options) ->
            super
            @setPropertyFromOptions(options, 'canvasView',  { default: @controller.canvasView,  required: true} )
            @setPropertyFromOptions(options, 'textBoxView', { default: @controller.textBoxView, required: true} )
            @setPropertyFromOptions(options, 'model',       { default: @controller.model,       required: true} )
            @setPropertyFromOptions(options, 'dataModel',   { default: @controller.dataModel,   required: true} )
            # for deprecated usage
            @parentView = @canvasView


    class EditorAction extends UnitAction

        trackingChanges: true

        onPerformStart: ->
            super
            if @trackingChanges
                @model.stopTrackingChanges()

        onPerformEnd: ->
            if @trackingChanges
                @model.startTrackingChanges()
            super


    class ToolbarStateAction extends EditorAction

        state: null

        perform: -> @controller.setToolbarState(@state)

        isAvailable: -> true


    module.exports =
        Action:             EditorAction
        EditorAction:       EditorAction
        ToolbarStateAction: ToolbarStateAction
