    'use strict'

    {DblClickBehavior} = require('./../../common/letterbehaviors/base')


    class EditBehavior extends DblClickBehavior

        onDblClick: (view, event, options) =>
            super
            @parentView.startUpdating(view.model)
            event.preventDefault()


    module.exports =
        EditBehavior: EditBehavior
