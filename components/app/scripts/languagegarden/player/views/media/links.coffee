    'use strict'

    {PlantLinkView} = require('./../../../common/views/media/links')
    {getRedirectInfoFromUrl} = require('./../../../common/planturls')


    PlayerPlantLinkView = class extends PlantLinkView

        initialize: (options) ->
            super
            @$el.click(@onClick)

        onClick: =>
            redirectInfo = getRedirectInfoFromUrl(@model.get('href'))
            if redirectInfo?
                @model.trigger('plantredirect', @model, redirectInfo)

    module.exports =
        PlayerPlantLinkView: PlayerPlantLinkView
