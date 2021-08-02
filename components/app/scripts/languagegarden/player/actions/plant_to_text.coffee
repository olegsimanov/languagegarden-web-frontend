'use strict'

{CanvasMode} = require('./../../common/constants')
{capitalize} = require('./../../common/utils')
{MediumType, PunctuationCharacter} = require('./../../common/constants')
{getMediumSnapshotByType} = require('../customdiffs/base')
{Action} = require('./base')


class PlantToTextAction extends Action

    initialize: ->
        super
        @findMediumByType = @model.media.findByAttribute('type')

    initializeListeners: ->
        @listenTo(@model, 'childchange', @triggerAvailableChange)

    getActiveModelIndex: ->
        activeObjectId = @canvasView.activePlantToTextObjectId
        if activeObjectId
            @model.media.findIndexByObjectId(activeObjectId)
        else
            @model.media.findIndexByType(MediumType.PLANT_TO_TEXT_NOTE)

    getActiveModel: ->
        index = @getActiveModelIndex()
        @model.media.at(index)

    isAvailable: -> @getActiveModel()?

    getHelpTextFromId: ->
        if @id.substr(0, 4) == 'p2t-'
            shortId = @id.substr(4)
            capitalize(shortId).replace(/-/g, ' ')
        else
            super

    getNoteFinalSnapshot: ->
        getMediumSnapshotByType(@timeline.endSnapshot,
                                MediumType.PLANT_TO_TEXT_NOTE)

    getElementByObjectId: (objectId) ->
        for element in @timeline.endSnapshot.elements
            return element if element.objectId == objectId


class AddPunctuation extends PlantToTextAction

    perform: -> @getActiveModel().appendPunctuation(@character)

    isAvailable: ->
        snapshot = @getNoteFinalSnapshot()
        if not snapshot?
            return false
        for wordArray in snapshot.noteTextContent
            for segmentObj in wordArray
                if segmentObj.text == @character
                    return true
        false


class Clear extends PlantToTextAction

    id: 'p2t-clear'

    perform: -> @getActiveModel().removeAllWords()

    isAvailable: -> @getActiveModel()?.hasContent() or false


class Remove extends PlantToTextAction

    id: 'p2t-remove'

    perform: -> @getActiveModel().removeLastWordOrPunctuation()

    isAvailable: -> @getActiveModel()?.hasContent() or false


class Join extends PlantToTextAction

    id: 'p2t-join'

    perform: -> @getActiveModel().joinLastWords()

    isAvailable: ->
        model = @getActiveModel()
        snapshot = @getNoteFinalSnapshot()

        if not snapshot or not model
            return false

        for wordArray in snapshot.noteTextContent
            words = _.filter(wordArray, (word) ->
                word.text not in PunctuationCharacter.CHARACTERS
            )
            if words.length > 1
                return @getActiveModel()?.canJoinWords()
        false


class ChangeCapitalizationBase extends PlantToTextAction
    isCapitalizationUsed: ->
        snapshot = @getNoteFinalSnapshot()
        return false unless snapshot

        for wordArray in snapshot.noteTextContent
            for segmentObj in wordArray
                # Skip puncutation character
                if segmentObj.text in PunctuationCharacter.CHARACTERS
                    continue

                canvasEl = @getElementByObjectId(segmentObj.objectId)
                canvasChar = canvasEl.text.charAt(0)
                segmentChar = segmentObj.text.charAt(0)

                if canvasChar != segmentChar
                    return true
        false


class ToUpper extends ChangeCapitalizationBase

    id: 'p2t-upper'

    perform: -> @getActiveModel().capitalizeLastWord()

    isAvailable: ->
        model = @getActiveModel()
        if not model?
            return false
        return @isCapitalizationUsed() and model.hasContent() and
                not model.isLastWordUppercase()


class ToLower extends ChangeCapitalizationBase

    id: 'p2t-lower'

    perform: -> @getActiveModel().lowercaseLastWord()

    isAvailable: ->
        model = @getActiveModel()
        if not model?
            return false
        return @isCapitalizationUsed() and model.hasContent() and
                model.isLastWordUppercase()


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


class StartPlantToTextMemoTest extends Action

    perform: ->
        @controller.toolbarView.setState('pt2-memo-test')
        @controller.canvasView.setMode(CanvasMode.PLANT_TO_TEXT)
        plantToTextBox = @controller.model.media.findByType(
            MediumType.PLANT_TO_TEXT_NOTE)
        plantToTextBox.removeAllWords()


class RetryPlantToTextMemoStart extends Action

    perform: ->
        @controller.canvasView.setNoOpMode()
        @controller.toolbarView.setState('start')
        @timeline.setActivityStartState()


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
    StartPlantToTextMemoTest: StartPlantToTextMemoTest
    RetryPlantToTextMemoStart: RetryPlantToTextMemoStart
