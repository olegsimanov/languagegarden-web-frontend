    'use strict'

    {DblClickBehavior} = require('./base')
    {MediumType} = require('./../../common/constants')


    class EditBehavior extends DblClickBehavior

        storeMetric: =>
            # disabling metric logging
            # these are logged by respective actions

        onDblClick: (view, event) =>
            super
            switch view.model?.get('type')
                when MediumType.TEXT
                    if not view.isInEditMode
                        @parentView.startTextEditing(view)

    module.exports =
        EditBehavior: EditBehavior
