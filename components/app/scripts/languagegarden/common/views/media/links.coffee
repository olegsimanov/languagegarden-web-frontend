    'use strict'

    {disableSelection} = require('./../../domutils')
    {HtmlMediumView} = require('./base')


    PlantLinkView = class extends HtmlMediumView
        className: "medium html-media-float btn btn-success"
        width: 200
        height: 40

        initialize: (options) =>
            super
            @listenTo(@model, 'change:name', @render)
            disableSelection(@el)

        remove: =>
            @stopListening(@model)
            super

        render: =>
            centerPoint = @model.get('centerPoint')
            @$el
            .text(@model.get('name'))
            .css
                left: centerPoint.x
                top: centerPoint.y

            super


    module.exports =
        PlantLinkView: PlantLinkView
