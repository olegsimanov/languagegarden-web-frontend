    'use strict'

    _ = require('underscore')
    $ = require('jquery')
    {TextToPlantView} = require('./../../../common/views/media/text_to_plant')


    EditorTextToPlantView = class extends TextToPlantView

        initialize: (options) ->
            super
            @setEditableMode(true)

        isSelected: -> false

        select: ->


    MarkableTextToPlantView = class extends TextToPlantView

        isSelected: -> false

        select: ->

        updateFromModel: ->
            @$(@spanSelector).off('click', @onElementClick)
            super
            @$(@spanSelector).on('click', @onElementClick)

        onElementClick: (event) =>
            $elem = $(event.target)
            $elem.toggleClass('marked')
            @setModelContent()


    module.exports =
        MarkableTextToPlantView: MarkableTextToPlantView
        EditorTextToPlantView: EditorTextToPlantView
