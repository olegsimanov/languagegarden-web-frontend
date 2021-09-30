    'use strict'

    _ = require('underscore')
    {Action} = require('./base')
    {EditorMode} = require('./../constants')

    class GoToControllerBase extends Action
        navigationType: null
        trackingChanges: false

        perform: -> @navigateToController()

        isAvailable: -> true

        navigateToController: ->
            @controller.trigger('navigate', this, @getNavigationInfo())

        getNavigationInfo: ->
            type: @navigationType
            plantId: @controller.dataModel.id


    class GoToBuilderBase extends GoToControllerBase
        navigationType: 'edit-plant'
        newStation: null

        isNewStation: -> @newStation

        getNavigationInfo: ->
            navInfo = super
            navInfo.newStation = @isNewStation()
            navInfo

        isAvailable: -> @timeline.isRewindedAtEnd()

    class GoToNavigatorBase extends GoToControllerBase
        navigationType: 'nav-plant'

    class DiscardAndGoToNavigator extends GoToNavigatorBase
        id: 'go-to-navigator'

    class SaveAndGoToNavigator extends GoToNavigatorBase
        id: 'save-and-go-to-navigator'

        initialize: (options) ->
            super

        initializeListeners: ->
            super

        remove: ->
            super


    class GoToStationEditor extends GoToBuilderBase
        id: 'go-to-station-editor'
        newStation: false

        isAvailable: ->
            super

        getHelpText: -> 'Edit current station'

    module.exports =
        DiscardAndGoToNavigator: DiscardAndGoToNavigator
        SaveAndGoToNavigator: SaveAndGoToNavigator
        GoToStationEditor: GoToStationEditor
