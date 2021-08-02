    'use strict'

    _ = require('underscore')
    {SoundProgressBar} = require('./../../../common/views/progress/bars')
    {PlayHiddenSound} = require('./../../actions/media')


    class HiddenSoundProgressBar extends SoundProgressBar

        initialize: (options) ->
            # overriding model with null, we will set it later
            options = _.extend({}, options, model: null)
            super(options)
            @setOption(options, 'timeline', @controller?.timeline, true)
            @position = null
            @action = new PlayHiddenSound
                controller: @controller
                timeline: @timeline
            @setSoundPlayer(@action.getSoundPlayer())
            @listenTo(@timeline, 'progresschange', @onTimelineProgressChange)

        render: ->
            super
            @toggleVisibility(@action.getHiddenSoundMedium()?)

        toggleVisibility: (show) ->
            @$el.toggleClass('hide', !show)

        remove: ->
            @stopListening(@timeline)
            super

        onTimelineProgressChange: ->
            @setSoundPlayer(@action.getSoundPlayer())
            @toggleVisibility(@action.getHiddenSoundMedium()?)


    module.exports =
        HiddenSoundProgressBar: HiddenSoundProgressBar
