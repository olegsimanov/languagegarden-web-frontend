    'use strict'

    {DblClickBehavior} = require('./base')
    {MediumType} = require('./../constants')


    class EditBehavior extends DblClickBehavior

        onDblClick: (view, event) =>
            super
            switch view.model?.get('type')
                when MediumType.TEXT
                    if not view.isInEditMode
                        @parentView.startTextEditing(view)

    module.exports =
        EditBehavior: EditBehavior
