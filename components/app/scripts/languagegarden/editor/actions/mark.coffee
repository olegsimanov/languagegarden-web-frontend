'use strict'

{Action} = require('./base')


class MarkAllElements extends Action
    id: 'mark-all-elements'

    initializeListeners: ->
        @listenTo(@model.elements, 'change', @triggerAvailableChange)

    isAvailable: ->
        not @model.elements.all (element) -> element.get('marked')

    perform: ->
        for element in @model.elements.models
            element.set('marked', true)
        return


module.exports =
    MarkAllElements: MarkAllElements
