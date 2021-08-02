'use strict'

{HtmlMediumView} = require('./base')
{PlacementType} = require('./../../constants')


class InstructionsView extends HtmlMediumView
    className: 'instructions-box'

    getPlacementType: -> PlacementType.UNDERSOIL

    updateViewTextData: (textData) -> @$el.text(textData)

    updateFromModel: ->
        textData = @model.get('text') or ''
        @updateViewTextData(textData)

    render: ->
        super
        @updateFromModel()
        this

module.exports =
    InstructionsView: InstructionsView
