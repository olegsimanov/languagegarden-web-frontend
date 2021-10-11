    'use strict'

    _                   = require('underscore')
    {Action}            = require('./base')

    class GoToControllerBaseAction extends Action

        navigationType:     null
        trackingChanges:    false

        perform:                -> @controller.trigger('navigate', this, @getNavigationInfo())
        isAvailable:            -> true

        getNavigationInfo: ->
            type:       @navigationType
            plantId:    @controller.dataModel.id


    class DiscardAndGoToNavigatorAction   extends GoToControllerBaseAction
        navigationType: 'nav-plant'
        id:             'discard-and-go-to-navigator'

    class SaveAndGoToNavigatorAction     extends GoToControllerBaseAction
        navigationType: 'nav-plant'
        id:             'save-and-go-to-navigator'
        isAvailable:    -> false


    module.exports =
        DiscardAndGoToNavigatorAction:    DiscardAndGoToNavigatorAction
        SaveAndGoToNavigatorAction:       SaveAndGoToNavigatorAction
