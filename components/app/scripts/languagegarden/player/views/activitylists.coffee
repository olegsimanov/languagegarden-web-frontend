    'use strict'

    {BaseView} = require('./../../common/views/base')
    {GoToActivityFromPlayerButton} = require('./../../common/views/navigation')
    {DivButton} = require('./../../common/views/buttons')


    class ActivityListView extends BaseView
        className: 'buttons-group'

        initialize: (options) ->
            super
            @setOption(options, 'timeline', null, true)
            @setOption(options, 'activityRecords', @controller?.activityRecords, true)
            @listenTo(@timeline, 'progresschange', @onPositionChange)
            @buttons = []

        removeButtons: ->
            for button in @buttons
                button.remove()

        remove: ->
            @removeButtons()
            @stopListening(@timeline)
            super

        onPositionChange: ->
            @render()

        render: ->
            @removeButtons()
            @$el.empty()
            @buttons = []
            activityIds = @timeline.getCurrentActivityIds()
            for activityId in activityIds
                button = new GoToActivityFromPlayerButton
                    activityId: activityId
                    controller: @controller
                    activityRecords: @activityRecords
                @buttons.push(button)
                button.render()
                @$el.append(button.el)

            this


    module.exports =
        ActivityListView: ActivityListView
