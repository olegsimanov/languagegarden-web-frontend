    'use strict'

    {capitalize} = require('./../../common/utils')
    {PunctuationCharacter} = require('./../../common/constants')
    {Action} = require('./base')


    class PlantToTextAction extends Action

        initializeListeners: ->
            @listenTo(@model, 'childchange', @triggerAvailableChange)

        getActiveModel: ->
            activeObjectId = @canvasView.activePlantToTextObjectId
            @model.media.findByObjectId(activeObjectId)

        isAvailable: -> @getActiveModel()?.hasContent() or false

        getHelpTextFromId: ->
            if @id.substr(0, 4) == 'p2t-'
                shortId = @id.substr(4)
                capitalize(shortId).replace(/-/g, ' ')
            else
                super


    class AddPunctuation extends PlantToTextAction

        perform: -> @getActiveModel().appendPunctuation(@character)

        isAvailable: -> @getActiveModel()?


    class Clear extends PlantToTextAction

        id: 'p2t-clear'

        perform: -> @getActiveModel().removeAllWords()


    class Remove extends PlantToTextAction

        id: 'p2t-remove'

        perform: -> @getActiveModel().removeLastWordOrPunctuation()


    class Join extends PlantToTextAction

        id: 'p2t-join'

        isAvailable: -> @getActiveModel()?.canJoinWords() or false

        perform: -> @getActiveModel().joinLastWords()


    class ToUpper extends PlantToTextAction

        id: 'p2t-upper'

        isAvailable: -> super and not @getActiveModel().isLastWordUppercase()

        perform: -> @getActiveModel().capitalizeLastWord()


    class ToLower extends PlantToTextAction

        id: 'p2t-lower'

        isAvailable: -> super and @getActiveModel().isLastWordUppercase()

        perform: -> @getActiveModel().lowercaseLastWord()


    class AddComma extends AddPunctuation
        id: 'p2t-add-comma'
        character: PunctuationCharacter.COMMA


    class AddPeriod extends AddPunctuation
        id: 'p2t-add-period'
        character: PunctuationCharacter.PERIOD


    class AddQuestionMark extends AddPunctuation
        id: 'p2t-add-question-mark'
        character: PunctuationCharacter.QUESTION_MARK


    class AddSemicolon extends AddPunctuation
        id: 'p2t-add-semicolon'
        character: PunctuationCharacter.SEMICOLON


    class AddColon extends AddPunctuation
        id: 'p2t-add-colon'
        character: PunctuationCharacter.COLON


    class AddExclamationMark extends AddPunctuation
        id: 'p2t-add-exclamation-mark'
        character: PunctuationCharacter.EXCLAMATION_MARK


    class AddDash extends AddPunctuation
        id: 'p2t-add-dash'
        character: PunctuationCharacter.DASH


    class AddQuotationMark extends AddPunctuation
        id: 'p2t-add-quotation-mark'
        character: PunctuationCharacter.QUOTATION_MARK


    module.exports =
        Clear: Clear
        Remove: Remove
        Join: Join
        ToUpper: ToUpper
        ToLower: ToLower
        AddComma: AddComma
        AddPeriod: AddPeriod
        AddQuestionMark: AddQuestionMark
        AddSemicolon: AddSemicolon
        AddColon: AddColon
        AddExclamationMark: AddExclamationMark
        AddDash: AddDash
        AddQuotationMark: AddQuotationMark
