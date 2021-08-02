    'use strict'

    _ = require('underscore')
    $ = require('jquery')
    {BaseProgressView} = require('./base')


    class HoldButton extends BaseProgressView
        initialize: (options) ->
            super
            @model = null
            @$el
            .on('click', @onClick)
            .on('mousedown', @onMouseDown)
            .on('mouseup', @onMouseUp)
            .on('mouseout', @onMouseOut)
            @setModel(options.model)
            @timeout = null
            @timeoutExecuted = false

        clearTimeout: (clearFlag=true) ->
            if clearFlag
                @timeoutExecuted = false
            clearTimeout(@timeout)

        onClick: (event) =>
            event.preventDefault()
            if not @timeoutExecuted
                @performAction()
            @clearTimeout()

        onMouseDown: (event) =>
            @timeout = setTimeout(@onTimeout, 1000)

        onMouseUp: (event) =>
            # we do not clear this.timeoutExecuted because the click event
            # follows
            @clearTimeout(false)

        onMouseOut: (event) =>
            @clearTimeout()

        onTimeout: =>
            @performAction()
            @timeoutExecuted = true
            @timeout = setTimeout(@onTimeout, 100)

        performAction: ->

        render: => this


    class GotoToNextButton extends HoldButton
        className: 'goto-next'

        performAction: ->
            if @progress < @total
                @model.setProgressTime(@progress + 1)


    class GotoToPreviousButton extends HoldButton
        className: 'goto-previous'

        performAction: ->
            if @progress > 0
                @model.setProgressTime(@progress - 1)


    class ProgressNumbersView extends BaseProgressView
        className: 'progress-numbers-container'

        initialize: (options) ->
            super
            @model = null
            @gotoPreviousButton = new GotoToPreviousButton(options)
            @gotoNextButton = new GotoToNextButton(options)
            @$el.append(@gotoPreviousButton.render().el)
            @$el.append(@gotoNextButton.render().el)
            @$el.append('<form class="progress-number-form"><input type="text" class="progress-number"></form>')
            @$el.append('<p class="total-number"></p>')
            @$('.progress-number').on('change', @onProgressInputChange)
            @$('.progress-number-form').on('submit', @onProgressFormSubmit)
            @setModel(options.model)

        updateProgress: ->
            @$('.progress-number').val(@progress)

        updateTotal: ->
            @$('.total-number').text(@total)

        updateAnnotations: ->

        onProgressFormSubmit: (event) =>
            event.preventDefault()
            @updateModelFromInput()

        onProgressInputChange: (event) =>
            @updateModelFromInput()

        updateModelFromInput: ->
            progress = parseInt(@$('.progress-number').val(), 10)
            if not _.isNaN(progress)
                if 0 > progress
                    progress = 0
                if progress > @total
                    progress = @total
                @model.setProgressTime(progress)
            else
                @updateProgress()


    class ProgressNumberView extends BaseProgressView
        className: 'station-form'
        tagName: 'form',

        events:
            'submit': 'onProgressFormSubmit'
            'change .station-number': 'onProgressInputChange'

        initialize: (options) ->
            super
            @$currentStation = $('<input type="text" class="no-bs station-number" />')

        updateProgress: ->
            @$currentStation.val(@progress)

        updateTotal: ->

        updateAnnotations: ->

        onProgressFormSubmit: (event) =>
            event.preventDefault()
            @updateModelFromInput()

        onProgressInputChange: (event) =>
            @updateModelFromInput()

        updateModelFromInput: ->
            progress = parseInt(@$currentStation.val(), 10)
            if not _.isNaN(progress)
                if 0 > progress
                    progress = 0
                if progress > @total
                    progress = @total
                    @updateProgress()
                @model.setProgressTime(progress)
            else
                @updateProgress()

        render: ->
            @$el.append(@$currentStation)
            super
            this


    module.exports =
        ProgressNumbersView: ProgressNumbersView
        ProgressNumberView: ProgressNumberView
