    'use strict'

    _ = require('underscore')
    {RenderableView} = require('./../renderable')


    class PlantTitleView extends RenderableView

        className: 'plant-name'

        initialize: (options) ->
            super
            @listenTo(@model, 'change:title', @render)

        render: ->
            super
            @$el.html(@model.get('title'))
            @$el.css('display', if @model.get('title')? then '' else 'none')
            this


    module.exports =
        PlantTitleView: PlantTitleView
