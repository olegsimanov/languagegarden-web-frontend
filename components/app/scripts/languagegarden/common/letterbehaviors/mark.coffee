    'use strict'

    {ClickBehavior} = require('./../../common/letterbehaviors/base')


    class MarkBehavior extends ClickBehavior

        id: 'mark'

        onClick: (view, event, options) =>
            element = view.model
            marked = element.get('marked') or false
            element.set('marked', not marked)
            super


    module.exports =
        MarkBehavior: MarkBehavior
