    'use strict'

    {BaseView} = require('./../base')


    class BaseProgressView extends BaseView
        shouldAppendToContainer: true

        initialize: (options) ->
            super
            @setOption(options, 'total', 0)
            @setOption(options, 'progress', 0)
            @setOption(options, 'annotations', {})
            @setOption(options, 'hidden', false)
            @rendered = false

        setTotal: (total) =>
            @total = total or 0
            if @rendered
                @updateTotal()
                @updateAnnotations()
                @updateProgress()

        setProgress: (progress) =>
            @progress = progress
            if @rendered
                @updateProgress()

        setProgressAndTotal: (progress, total) =>
            @progress = progress
            @total = total or 0
            if @rendered
                @updateTotal()
                @updateAnnotations()
                @updateProgress()

        setAnnotations: (annotations) ->
            @annotations = annotations
            if @rendered
                @updateAnnotations()

        getFraction: (position) ->
            if @total > 0
                position / @total
            else
                1.0

        getPercentOfPosition: (position) ->
            if position is 0
                0
            else
                Math.round(@getFraction(position) * 1000) / 10

        updateProgress: ->

        updateTotal: ->

        updateAnnotations: ->

        render: ->
            if @hidden
                @$el.hide()
            else
                if @position?
                    @$el.css(left: @position.x, top: @position.y)
                @updateTotal()
                @updateAnnotations()
                @updateProgress()
                if @$el.css('display') == 'hidden'
                    console.log('show')
                    @$el.show()
            @rendered = true
            @appendToContainerIfNeeded()

        onModelBind: (options)->
            @listenTo(@model, 'progresschange', @onModelProgressChange)
            @listenTo(@model, 'annotationschange', @onModelAnnotationsChange)

            @setProgressAndTotal(@model.getProgressTime(),
                                 @model.getTotalTime())
            @setAnnotations(@model.getAnnotations())

        onModelProgressChange: ->
            @setProgressAndTotal(@model.getProgressTime(),
                                 @model.getTotalTime())

        onModelAnnotationsChange: ->
            @setAnnotations(@model.getAnnotations())


    module.exports =
        BaseProgressView: BaseProgressView
