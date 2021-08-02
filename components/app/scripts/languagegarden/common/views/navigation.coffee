    'use strict'

    _ = require('underscore')
    {
        GoToActivityFromNavigator
        GoToActivityFromPlantPlayer
        GoToActivityList
    } = require('./../actions/navigation')
    {DivButton} = require('./buttons')



    class NavigationActionButton extends DivButton

        initializeProperties: (options) ->
            super
            @setPropertyFromOptions(options, 'timeline',
                                    default: @controller?.timeline
                                    required: true)
            @setPropertyFromOptions(options, 'sidebarTimeline',
                                    default: @controller?.sidebarTimeline
                                    required: true)

        # TODO: make RenderableView copy backbone properties like
        # className to dom in setElement

        getActionOptions: ->
            timeline: @timeline
            controller: @controller

        remove: ->
            delete @timeline
            super


    class GoToActivityButton extends NavigationActionButton

        initializeProperties: (options) ->
            super
            @setPropertyFromOptions(options, 'activityLink')
            @setPropertyFromOptions(options, 'activityId',
                                    default: @activityLink?.get('activityId')
                                    required: true)

        getActionOptions: ->
            _.extend({
                activityLink: @activityLink
                activityId: @activityId
            }, super)

        remove: ->
            delete @activityLink
            super


    class GoToActivityFromNavigatorButton extends GoToActivityButton
        actionClass: GoToActivityFromNavigator


    class GoToActivityFromPlayerButton extends GoToActivityButton
        customClassName: 'icon icon_goto-activity'
        actionClass: GoToActivityFromPlayer

        initializeProperties: (options) ->
            super
            @setPropertyFromOptions(options, 'activityRecords',
                                    default: @controller?.activityRecords
                                    required: true)

        initialize: (options) ->
            super
            @disabled = not @isEnabled()
            wasCompleted = @activityRecords.entryHasProperty(@activityId, 'completed')
            @$el.toggleClass('activity-seen', wasCompleted)

        isEnabled: -> @action.isAvailable()

        getActionOptions: (options) ->

            _.extend({
                activityRecords: @activityRecords
                sidebarTimeline: @sidebarTimeline
            }, super)


    class GoToActivityListButton extends NavigationActionButton

        actionClass: GoToActivityList
        customClassName: 'icon icon_goto-activity-list'


    module.exports =
        GoToActivityFromNavigatorButton: GoToActivityFromNavigatorButton
        GoToActivityFromPlayerButton: GoToActivityFromPlayerButton
        GoToActivityListButton: GoToActivityListButton
