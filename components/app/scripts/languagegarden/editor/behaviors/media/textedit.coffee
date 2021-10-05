    'use strict'

    {SelectBehavior} = require('./select')
    {MediumType} = require('./../../constants')


    class TextEditSelectBehavior extends SelectBehavior

        onClick: (view, event) =>
            if view.model.get('type') == MediumType.TEXT and view.isInEditMode
                return
            super


    module.exports =
        TextEditSelectBehavior: TextEditSelectBehavior
