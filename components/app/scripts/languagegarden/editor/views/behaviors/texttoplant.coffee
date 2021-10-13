    'use strict'

    {ClickBehavior} = require('./base')


    class TextToPlantLetterClickBehavior extends ClickBehavior

        id: 't2p'

        onClick: (view, event, {letter}) =>
            @parentView.model.stopTrackingChanges()
            activeModel = @parentBehavior.getActiveModel()
            activeModel.addElement(view.model)
            @parentView.model.startTrackingChanges()
            super


    module.exports =
        TextToPlantLetterClickBehavior: TextToPlantLetterClickBehavior
