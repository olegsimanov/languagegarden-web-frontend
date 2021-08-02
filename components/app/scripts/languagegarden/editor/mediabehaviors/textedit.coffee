    'use strict'

    {MediumType} = require('./../../common/constants')
    {SelectBehavior} = require('./select')


    class TextEditSelectBehavior extends SelectBehavior

        storeMetric: =>
            # disabling metric logging
            # I don't think we should log this one at all

        onClick: (view, event) =>
            if view.model.get('type') == MediumType.TEXT and view.isInEditMode
                # prevent re-toggling current active text in edit mode
                return
            super


    module.exports =
        TextEditSelectBehavior: TextEditSelectBehavior
