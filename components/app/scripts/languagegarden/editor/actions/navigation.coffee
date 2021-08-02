    'use strict'

    _ = require('underscore')
    {Action, ToolbarStateAction} = require('./base')
    {EditorMode} = require('./../constants')
    {Save} = require('./history')
    {DeleteLastStation} = require('./stations')
    {ToolbarEnum} = require('./../../common/views/toolbars/constants')


    class GoToStationCreationMenu extends ToolbarStateAction
        state: ToolbarEnum.STATION_CREATION


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


    class GoToPlayerBase extends GoToControllerBase
        navigationType: 'play-plant'


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

        perform: ->
            history = @controller.history
            if not history.isAtSavedPosition()
                if not window.confirm(
                    'There are unsaved changes that will be lost!
                    \n\nAre your sure you want to continue?')
                    return

            while not history.isAtSavedPosition()
                if not history.undo()
                    return false
            @navigateToController()

        isAvailable: -> @controller.history.canUndoToSavedPosition()


    class SaveAndGoToNavigator extends GoToNavigatorBase
        id: 'save-and-go-to-navigator'

        initialize: (options) ->
            super
            saveActionOptions = _.extend {}, options,
                onSaveSuccess: =>
                    @navigateToController()
                allowSaveWithoutChanges: true
            @saveAction = new Save(saveActionOptions)

        initializeListeners: ->
            super
            @listenTo(@saveAction, 'change:available', @triggerAvailableChange)

        remove: ->
            @saveAction.remove()
            @saveAction = null
            super

        perform: ->
            @saveAction.fullPerform()

        isAvailable: ->
            @saveAction.isAvailable()


    class GoToStationEditor extends GoToBuilderBase
        id: 'go-to-station-editor'
        newStation: false

        isAvailable: ->
            super and @timeline.getCurrentActivityLinks().length == 0

        getHelpText: -> 'Edit current station'


    class GoToStationCreator extends GoToBuilderBase
        id: 'go-to-station-creator'

        isNewStation: -> @timeline.getDiffsLength() > 0

        getHelpText: -> 'Create a new station'


    class DuplicateStationAndGoToCreator extends GoToStationCreator
        id: 'duplicate-station-go-to-creator'

        initialize: (options) ->
            super
            @setPropertyFromOptions(options, 'stationIndex', required: true)

        getHelpText: -> 'Duplicate station'

        getNavigationInfo: ->
            navInfo = super
            navInfo.stationIndex = @stationIndex
            navInfo


    module.exports =
        GoToStationCreationMenu: GoToStationCreationMenu
        GoToPlantsList: GoToPlantsList
        DiscardAndGoToNavigator: DiscardAndGoToNavigator
        SaveAndGoToNavigator: SaveAndGoToNavigator
        GoToStationEditor: GoToStationEditor
        GoToStationCreator: GoToStationCreator
        DuplicateStationAndGoToCreator: DuplicateStationAndGoToCreator
