    'use strict'

    _ = require('underscore')
    {MediumType, PlacementType} = require('./../../common/constants')
    {TextBoxView} = require('./../../common/views/textboxes')
    {
        TextToPlantPlaceholderView
    } = require('./../../common/views/media/text_to_plant')


    class PlayerTextBoxView extends TextBoxView

        getMediumViewClass: (model) ->
            if (model.get('placementType') != PlacementType.HIDDEN and
                    model.get('type') == MediumType.TEXT_TO_PLANT)
                TextToPlantPlaceholderView
            else
                super


    module.exports =
        PlayerTextBoxView: PlayerTextBoxView
