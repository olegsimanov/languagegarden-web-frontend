    'use strict'

    _           = require('underscore')
    {Action}    = require('./base')


    class ColorBaseAction extends Action

        initialize: (options) ->
            super
            @setPropertyFromOptions(options, 'toolModel', required: true)

        isAvailable: => @canvasView.getSelectedElements().length > 0

        perform: (model, letter_index) =>
            if letter_index?
                @letterPerform(model, letter_index)
            else
                @wordPerform(model)

        fullPerform: (model, letter_index) =>
            if not model? and not @isAvailable()
                return false
            @onPerformStart()
            @perform(model, letter_index)
            @onPerformEnd()

        wordPerform: (models) =>
            [@letterPerform(model, null) for model in models]
            true

        letterPerform: (model, letter_i) =>
            console.log('ColorBaseAction.letterPerform')
            true

    class ColorAction extends ColorBaseAction

        id: 'color'

        letterPerform: (model, letter_i) =>
            model.setLetterAttribute(letter_i, 'labels', [@toolModel.get('label')])
            true

    class RemoveColorAction extends ColorBaseAction

        id: 'remove-color'

        letterPerform: (model, letter_i) =>
            model.setLetterAttribute(letter_i, 'labels', [])
            true

    class SplitColorAction extends ColorBaseAction

        id: 'split-color'

        letterPerform: (model, letter_i) =>
            model.setLetterAttribute(letter_i, 'labels', @toolModel.getLabels())
            true

    module.exports =
        ColorAction:        ColorAction
        RemoveColorAction:  RemoveColorAction
        SplitColorAction:   SplitColorAction
