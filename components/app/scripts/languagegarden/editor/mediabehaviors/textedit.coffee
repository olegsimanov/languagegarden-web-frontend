    'use strict'

    {MediumType} = require('./../constants')
    {SelectBehavior} = require('./select')


    class TextEditSelectBehavior extends SelectBehavior

        onClick: (view, event) =>
            if view.model.get('type') == MediumType.TEXT and view.isInEditMode
                return
            super


    module.exports =
        TextEditSelectBehavior: TextEditSelectBehavior
