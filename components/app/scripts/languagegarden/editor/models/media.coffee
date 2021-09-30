    'use strict'

    _ = require('underscore')
    {Point} = require('./../../math/points')
    {PlantChildModel, PlantChildCollection} = require('./base')
    {deepCopy, startsWith, structuralEquals} = require('./../../common/utils')
    {
        MediumType
        VisibilityType
        PunctuationCharacter
    } = require('./../constants')


    class PlantMedium extends PlantChildModel

        initialize: (options) ->
            if not PlantMedium.factoryRunningFlag
                throw "please use the fromJSON factory class method"
            super
            @setDefaultValue('centerPoint', new Point(0,0))
            @setDefaultValue('scaleVector', new Point(1,1))
            @setDefaultValue('maxDeviationVector', null)
            @setDefaultValue('rotateAngle', 0)

        set: (key, val, options) ->
            # normalize input
            if typeof key == 'object'
                attrs = _.clone(key) or {}
                options = val
            else
                attrs = {}
                attrs[key] = val

            # apply point wrappers
            for name in ['centerPoint', 'scaleVector', 'maxDeviationVector']
                if attrs[name]?
                    attrs[name] = Point.fromValue(attrs[name])

            # defensive deep copying of array of textElements, if present.
            for name in ['textElements', 'noteTextContent']
                if attrs[name]?
                    attrs[name] = deepCopy(attrs[name])

            super(attrs, options)

        toJSON: =>
            data = super

            # dumping Point objects to ordinary object
            for name in ['centerPoint', 'scaleVector']
                data[name] = data[name].toJSON()

            # defensive deep copying of array of textElements, if present.
            for name in ['textElements', 'noteTextContent']
                if data[name]?
                    data[name] = deepCopy(data[name])

            data

        @fromJSON: (attrs, options) =>
            @factoryRunningFlag = true
            if attrs?.type == MediumType.PLANT_TO_TEXT_NOTE
                model = new PlantToTextBox(attrs, options)
            else if attrs?.type == MediumType.IMAGE
                model = new UnitImage(attrs, options)
            else
                model = new this(attrs, options)
            @factoryRunningFlag = false
            model


    class PlantToTextBox extends PlantMedium

        initialize: (options) ->
            super
            @setDefaultValue('noteTextContent', [])
            @setDefaultValue('okNoteTextContent', null)

        toJSON: ->
            data = super
            delete data.okNoteTextContent
            data

        findElementByObjectId: (objectId) ->
            stateModel = @collection?.getParentModel()
            stateModel.elements.findByObjectId(objectId)

        isInPlantToTextMode: -> @get('inPlantToTextMode')

        ###
        Should return list of strings, is considered only with 'text' value of
        model's noteTextContent.
        ###
        getTextWords: (noteTextContent)->
            noteTextContent ?= @get('noteTextContent')
            words = []
            for itemList in noteTextContent
                wordParts = ((item.text or '') for item in itemList)
                words.push(wordParts.join(''))
            words

        ###
        Returns objectIds of elements added to this model.
        ###
        getContentElementIDs: ->
            (item.objectId for item in _.flatten(@get('noteTextContent')))

        getContentLength: -> @get('noteTextContent').length

        hasContent: -> @getContentLength() > 0

        getTextContent: (noteTextContent) ->
            # TODO: automerge punctuation by string.replace
            @getTextWords(noteTextContent).join('\n')

        canJoinWords: -> @getContentLength() > 1

        isLastWordUppercase: ->
            textContent = @get('noteTextContent')
            if textContent.length > 0
                char = textContent[textContent.length - 1][0]['text'].charAt(0)
                char != char.toLowerCase()
            else
                false

        ###General purpose method for changing noteTextContext.
        Copies the value, feeds it to the given callback and saves the result.
        Does a copy, so that the value is treated as updated.
        ###
        updateNoteTextContent: (fun) ->
            oldContent = @get('noteTextContent')
            newContent = deepCopy(oldContent)
            oldContentElIds = _.uniq(@getContentElementIDs())

            fun(newContent)

            if not structuralEquals(oldContent, newContent)
                @set('noteTextContent', newContent, silent:true)

                newContentElIds = _.uniq(@getContentElementIDs())

                delElIds = _.difference(oldContentElIds, newContentElIds)
                insElIds = _.difference(newContentElIds, oldContentElIds)

                for objectId in delElIds
                    elemModel = @findElementByObjectId(objectId)
                    if not elemModel?
                        continue
                    @selectElementViaVisibility(elemModel, false)

                for objectId in insElIds
                    elemModel = @findElementByObjectId(objectId)
                    if not elemModel?
                        continue
                    @selectElementViaVisibility(elemModel, true)

                @trigger('change', this)
                @trigger('change:noteTextContent', newContent)

        ###Store plant element to noteTextContent. It should contain objects
        representing strings/objects to join eg:
        [
            [{'objectId': 'pid_1', 'text': 'Some'}],
            [ # effect of a join
                {'objectId': 'pid_24', 'text': 'cat'},
                {'objectId': 'pid_25', 'text': 's'},
            ],
            [{'objectId': 'pid_14', 'text': 'like'}],
        ]

        Nesting is required by the text join operation. The objectId is required
        only for deselecting element views.
        ###
        addElement: (elemModel) ->
            @updateNoteTextContent (textContent) =>
                segmentObj =
                    objectId: elemModel.get('objectId')
                    text: elemModel.get('text')

                oldTextContent = deepCopy(textContent)
                textContent.push([segmentObj])

                @noteTextContentMagicalJoin(textContent, oldTextContent)

        ###
        "Magical glue"

        This will modify the textContent list in-place.
        ###
        noteTextContentMagicalJoin: (textContent, oldTextContent) ->
            okNoteTextContent = @get('okNoteTextContent')

            if not okNoteTextContent?
                return

            textContentJoined = deepCopy(textContent)
            @noteTextContentJoin(textContentJoined)
            okText = @getTextContent(okNoteTextContent)
            oldText = @getTextContent(oldTextContent)
            newText = @getTextContent(textContent)
            joinedText = @getTextContent(textContentJoined)

            # "Magical glue"
            if (startsWith(okText, oldText) and
                    not startsWith(okText, newText) and
                    startsWith(okText, joinedText))
                @noteTextContentJoin(textContent)


        selectElementViaVisibility: (elemModel, flag, options) ->
            if flag
                visibilityType = VisibilityType.VISIBLE
            else
                visibilityType = VisibilityType.PLANT_TO_TEXT_FADED
            elemModel.set('visibilityType', visibilityType, options)

        removeAllWords: ->
            @updateNoteTextContent (textContent) -> textContent.length = 0

        removeLastWordOrPunctuation: ->
            @updateNoteTextContent (textContent) ->
                lastWord = textContent[textContent.length - 1]
                lastSegment = lastWord[lastWord.length - 1]

                # Remove only punctuation char
                if lastWord.length > 1 and
                   lastSegment.text in PunctuationCharacter.CHARACTERS
                    lastWord.pop()
                else
                    textContent.pop()

        noteTextContentJoin: (textContent) ->
            if textContent.length > 1
                last = textContent.pop()
                newLast =textContent[textContent.length - 1].concat(last)
                textContent[textContent.length - 1] = newLast

        joinLastWords: ->
            @updateNoteTextContent (textContent) =>
                @noteTextContentJoin(textContent)

        capitalizeLastWord: ->
            @updateNoteTextContent (textContent) ->
                if textContent.length > 0
                    toCap = textContent[textContent.length - 1][0]['text']
                    toCap = toCap.charAt(0).toUpperCase() + toCap.slice(1)
                    textContent[textContent.length - 1][0]['text'] = toCap

        lowercaseLastWord: ->
            @updateNoteTextContent (textContent) ->
                if textContent.length > 0
                    toCap = textContent[textContent.length - 1][0]['text']
                    toCap = toCap.charAt(0).toLowerCase() + toCap.slice(1)
                    textContent[textContent.length - 1][0]['text'] = toCap

        appendPunctuation: (character) ->
            @updateNoteTextContent (textContent) ->
                if textContent.length > 0
                    textContent[textContent.length - 1].push
                        text: character
                        objectId: null
                else
                    textContent.push([
                        text: character
                        objectId: null
                    ])


    class UnitImage extends PlantMedium
        # Replace filename.png with filename_size.png
        # Currently we support 'medium' and 'small' sizes
        getUrlForSize: (size) ->
            url = @get('url')
            if url
                url.replace(/.[^.]+$/, (match) -> "_#{size}#{match}")
            else
                null


    class PlantMedia extends PlantChildCollection
        modelFactory: PlantMedium.fromJSON
        objectIdPrefix: 'medium'

        initialize: ->
            super
            @findByType = @findByAttribute('type')
            @findIndexByType = @findIndexByAttribute('type')


    module.exports =
        PlantMedium: PlantMedium
        PlantMedia: PlantMedia
