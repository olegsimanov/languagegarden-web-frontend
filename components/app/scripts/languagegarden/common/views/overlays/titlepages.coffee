    'use strict'

    _ = require('underscore')
    {BaseView} = require('./../base')
    {template} = require('./../../templates')
    {RenderableView} = require('./../renderable')


    class TitleView extends RenderableView
        template: template('./common/titlepages/title.ejs')
        className: 'title-page__title-container title-container'

        onModelBind: ->
            @listenTo(@model, 'change:title', @invalidate)

        getRenderContext: ->
            ctx = super
            ctx.title = @model.get('title')
            ctx


    class TitleImageView extends RenderableView
        template: template('./common/titlepages/image.ejs')
        className: 'title-page__image-container image-container'

        onModelBind: ->
            super
            @listenTo(@model.titleImage, 'change:url', @invalidate)

        onModelUnbind: ->
            @stopListening(@model.titleImage)
            super

        getRenderContext: ->
            ctx = super
            ctx.url = @model.titleImage.get('url')
            ctx


    class TitlePageOverlay extends BaseView
        className: 'title-page'
        titleViewClass: TitleView
        imageViewClass: TitleImageView

        initialize: (options) ->
            super
            @setPropertyFromOptions(options, 'timeline', required: true)
            @listenTo(@timeline, 'progresschange', @onTimelineProgressChange)
            @listenTo(@timeline, 'playbackchange', @onTimelinePlaybackChange)

            @titleView = new @titleViewClass
                controller: @controller
                model: @controller.dataModel

            @imageView = new @imageViewClass
                controller: @controller
                model: @controller.dataModel

        toggleVisibility: ->
            titlePageShown = @timeline.getStationPosition() == 0 and
                    not @timeline.isPlaying()
            @$el.toggleClass('title-page--visible', titlePageShown)

        renderCore: ->
            super
            @$el.append(@titleView.el)
            @$el.append(@imageView.el)
            @titleView.render()
            @imageView.render()
            @toggleVisibility()

        onTimelineProgressChange: -> @toggleVisibility()

        onTimelinePlaybackChange: -> @toggleVisibility()


    module.exports =
        TitleImageView: TitleImageView
        TitlePageOverlay: TitlePageOverlay
