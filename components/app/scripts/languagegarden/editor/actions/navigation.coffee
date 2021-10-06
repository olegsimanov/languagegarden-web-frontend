    'use strict'

    _                   = require('underscore')
    {Action}            = require('./base')

    class GoToControllerBase extends Action

        navigationType:     null
        trackingChanges:    false

        perform:                -> @controller.trigger('navigate', this, @getNavigationInfo())
        isAvailable:            -> true

        getNavigationInfo: ->
            type:       @navigationType
            plantId:    @controller.dataModel.id


    class DiscardAndGoToNavigator   extends GoToControllerBase
        navigationType: 'nav-plant'
        id:             'discard-and-go-to-navigator'

    class SaveAndGoToNavigator      extends GoToControllerBase
        navigationType: 'nav-plant'
        id:             'save-and-go-to-navigator'
        isAvailable:    -> false


    module.exports =
        DiscardAndGoToNavigator:    DiscardAndGoToNavigator
        SaveAndGoToNavigator:       SaveAndGoToNavigator
