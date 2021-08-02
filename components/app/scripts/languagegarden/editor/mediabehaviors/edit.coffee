    'use strict'

    {DblClickBehavior} = require('./../../common/mediabehaviors/base')
    {EditSound, EditImage} = require('./../actions/media')
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
                when MediumType.IMAGE
                    @parentView.enterEditMedium = view.model
                    action = new EditImage(parentView: @parentView)
                    action.fullPerform()
                when MediumType.SOUND
                    @parentView.enterEditMedium = view.model
                    action = new EditSound(parentView: @parentView)
                    action.fullPerform()


    module.exports =
        EditBehavior: EditBehavior
