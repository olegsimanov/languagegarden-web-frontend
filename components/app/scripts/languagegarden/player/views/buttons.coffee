    'use strict'

    _ = require('underscore')
    {DivButton} = require('./../../common/views/buttons')
    {PlayHiddenSound} = require('./../actions/media')
    {
        GoToNextActivityOrIntro
        RetryLesson
    } = require('./../actions/navigation')


    class TimelineDivButton extends DivButton

        initialize: (options) ->
            super
            @setOption(options, 'timeline', @controller?.timeline, true)

        remove: ->
            @stopListening(@timeline)
            delete @timeline
            super


    class TimelineActionButton extends TimelineDivButton

        initialize: (options) ->
            super
            @disabled = not @isEnabled()
            @hidden = @isHidden()
            @listenTo(@timeline, 'progresschange', @onChange)

        getActionOptions: ->
            timeline: @timeline
            controller: @controller

        isEnabled: -> @action.isAvailable()

        isHidden: -> not @isEnabled()

        onChange: ->
            @disabled = not @isEnabled()
            @hidden = @isHidden()
            @render()


    class PlayHiddenSoundButton extends TimelineActionButton
        customClassName: 'icon'
        actionClass: PlayHiddenSound

        initialize: (options) ->
            super
            @setOption(options, 'bus', @controller?.bus, true)
            @setPropertyFromOptions(options, 'toolbarView')
            @listenTo(@bus, 'playbackchange', @onBusPlaybackChange)
            if @toolbarView?
                @listenTo(@toolbarView, 'activeChanged', @onToolbarActiveChanged)

        onBusPlaybackChange: (source) ->
            if source != @action.getSoundPlayer()
                return
            @toggleState()

        render: ->
            super
            @toggleVisibility(@action.getHiddenSoundMedium()?)
            @toggleState()

        toggleState: ->
            playing = @action.getSoundPlayer().isPlaying()
            @$el.toggleClass('icon_sound-play', not playing)
            @$el.toggleClass('icon_sound-pause', playing)

        onToolbarActiveChanged: ->
            unless @toolbarView.active
                player = @action.getSoundPlayer()
                player.stop() if player.isPlaying()


    class NextActivityButton extends DivButton
        customClassName: 'icon icon_bold-arrow-right'
        actionClass: GoToNextActivityOrIntro

        initialize: ->
            super
            activityRecords = @controller.activityRecords
            if activityRecords?
                @listenTo(activityRecords.entries, 'change', @render)
            @sidebarTimeline = @controller.sidebarTimeline
            @listenTo(@sidebarTimeline, 'blocked:change', @updateVisibility)

        render: ->
            super
            @updateVisibility()

        updateVisibility: ->
            @toggleVisibility(not @sidebarTimeline.isBlocked() and
                              @action.isAvailable())


    class StartLessonButton extends DivButton
        actionClass: GoToNextActivityOrIntro
        customClassName: 'button_start-lesson'
        templateString: '
            <div class="icon icon_lesson-start"></div>
            <div class="button__caption">
                Start
            </div>'


    class RetryLessonButton extends DivButton
        actionClass: RetryLesson
        customClassName: 'button_retry-lesson'
        templateString: '
            <div class="icon icon_lesson-retry"></div>
            <div class="button__caption">
                Retry
            </div>'


    module.exports =
        RetryLessonButton: RetryLessonButton
        StartLessonButton: StartLessonButton
        PlayHiddenSoundButton: PlayHiddenSoundButton
        NextActivityButton: NextActivityButton
