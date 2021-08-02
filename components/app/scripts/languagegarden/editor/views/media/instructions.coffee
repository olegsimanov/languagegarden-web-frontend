'use strict'

{InstructionsView} = require('./../../../common/views/media/instructions')


class EditorInstructionsView extends InstructionsView
    tagName: 'textarea'
    events:
        'change': 'onTextArea'

    getViewTextData: -> @$el.val()

    updateViewTextData: (textData) -> @$el.val(textData)

    setModelContent: ->
        textData = @getViewTextData()
        @model.set('text', textData)

    onTextArea: ->
        @setModelContent()


module.exports =
    EditorInstructionsView: EditorInstructionsView
