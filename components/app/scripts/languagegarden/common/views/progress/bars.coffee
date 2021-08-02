    'use strict'

    _ = require('underscore')
    $ = require('jquery')
    {Point} = require('./../../../math/points')
    {getScaleFactor} = require('./../../domutils')
    {BaseProgressView} = require('./base')


    class ProgressBar extends BaseProgressView
        className: 'progress-bar'

        initialize: (options) =>
            super

            @$progressEl = $('<ul />')
            .addClass('progress-bar__bar')
            .css('width', '0%')
            .appendTo @$el

            @position = options.position or new Point(0, 0)
            @updateAnnotations()
            @$el.on('click', @onClick)

        remove: =>
            @$el.off()
            super

        updateProgress: =>
            @$progressEl.css('width', "#{@getPercentOfPosition(@progress)}%")

        updateAnnotations: ->
            this.$('.annotation').remove()
            for own pos, tags of @annotations
                $div = $('<div>')
                .addClass('annotation')
                .css('left', "#{@getPercentOfPosition(pos)}%")
                for tag in tags
                    $div.addClass("annotation-#{tag}")
                $div.appendTo(@el)

        onClick: (event) =>
            scaleFactor = getScaleFactor(@el)
            offset = @$el.offset()
            fractionX = (event.pageX - offset.left) / (@$el.width() * scaleFactor)
            @trigger('progressclick', this, fractionX * @total)


    class ModelProgressBar extends ProgressBar

        initialize: (options) =>
            super
            @model = null
            @setModel(options.model)
            @listenTo(this, 'progressclick', @onProgressClick)

        remove: =>
            @setModel(null)
            @stopListening(this)
            super

        onProgressClick: (source, newProgress) =>
            @model.setProgressTime(newProgress)


    class SoundProgressBar extends ModelProgressBar
        className: 'progress-bar progress-bar_sound'

        initialize: (options) =>
            super
            model = options.model or options.soundPlayer
            @setModel(model)

        setSoundPlayer: (soundPlayer) => @setModel(soundPlayer)


    module.exports =
        SoundProgressBar: SoundProgressBar
