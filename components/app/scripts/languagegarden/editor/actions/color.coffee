    'use strict'

    _ = require('underscore')
    {Action} = require('./base')
    {ColorMode} = require('./../constants')


    ### Handles basic word/letter input. ###
    class WordActionBase extends Action

        initialize: (options) ->
            super
            @setPropertyFromOptions(options, 'toolModel', required: true)

        ### Allows tooltip integration. ###
        isAvailable: => @canvasView.getSelectedElements().length > 0

        ### Sanitize the data, call correct handler add selected group args. ###
        perform: (model, letter_index) =>
            if letter_index?
                @letterPerform(model, letter_index)
            else
                # model is a list of selected models
                @wordPerform(model)

        fullPerform: (model, letter_index) =>
            if not model? and not @isAvailable()
                return false
            @onPerformStart()
            @perform(model, letter_index)
            @onPerformEnd()

        letterPerform: => console.log('WordActionBase letter perform')
        wordPerform: => console.log('WordActionBase word perform')

    class ColorBaseAction extends WordActionBase

        ### Applies letterPerform with null letter indicating the whole word.
        ###
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

    class HideAction extends Action

        id: 'word-hide'

        letterPerform: => console.log('HideAction letter perform')
        wordPerform: => console.log('HideAction word perform')

    module.exports =
        ColorAction: ColorAction
        RemoveColorAction: RemoveColorAction
        SplitColorAction: SplitColorAction
        HideAction: HideAction
