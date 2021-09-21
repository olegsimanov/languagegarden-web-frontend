    'use strict'

    _ = require('underscore')
    {Action} = require('./base')
    {EditorMode} = require('./../constants')

    ###
    Action that allows navigating to player, prompting to save the plant in
    the process.
    ###
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


    class DoActionAndGoToController extends GoToControllerBase

        actionClass: null

        initialize: (options) ->
            super
            @action = new @actionClass(@getActionOptions(options))

        getActionOptions: (options) -> options

        perform: ->
            @action.perform()
            super

        isAvailable: -> super and @action.isAvailable()

        getHelpText: -> @action.getHelpText()


    class GoToNavigatorBase extends GoToControllerBase
        navigationType: 'nav-plant'


    class DoActionAndGoToNavigator extends DoActionAndGoToController
        navigationType: 'nav-plant'


    class GoToPlantsList extends GoToControllerBase
        navigationType: 'list-plants'
        id: 'go-to-plants-list'


    class DiscardAndGoToNavigator extends GoToNavigatorBase
        id: 'go-to-navigator'

    class SaveAndGoToNavigator extends GoToNavigatorBase
        id: 'save-and-go-to-navigator'

        initialize: (options) ->
            super
            saveActionOptions = _.extend {}, options,
                onSaveSuccess: =>
                    @navigateToController()
                allowSaveWithoutChanges: true

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
        GoToPlantsList: GoToPlantsList
        DiscardAndGoToNavigator: DiscardAndGoToNavigator
        SaveAndGoToNavigator: SaveAndGoToNavigator
        GoToStationEditor: GoToStationEditor
