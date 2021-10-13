    'use strict'

    _               = require('underscore')

    {Action}        = require('./base')
    {Point}         = require('./../math/points')
    {PlantElement}  = require('./../models/elements')
    {
        getWordSplits
        getWordSplitIndices
    }               = require('./../views/utils/elementsplit')


    class SplitWordElement extends Action

        id: 'word-split'

        isAvailable: ->
            if @canvasView.insertView?
                @canvasView.insertView.canSplitWord()
            else if @canvasView.wordSplitContext?
                {model, position} = @getWordSplitContext()
                @canSplitAt(model.get('text'), position)
            else
                false

        perform: ->

            {position, view, model} = @getWordSplitContext()
            text = model?.get('text')

            @removeSplitContext()

            if text and @canSplitAt(text, position)
                model = @splitWord(view, @getSplitIndices(text, position))[0]
                makesnapshot = true

            _.delay => @canvasView.startUpdating(model) if model?

            makesnapshot or false

        splitWord: (view, indices) ->

            origElemModel           = view.model
            elemCollection          = @model.elements
            text                    = origElemModel.get('text')
            indices                 ?= @getSplitIndices(text)
            elemCollectionPosition  = elemCollection.indexOf(origElemModel)
            newModelData            = []
            previousSplit           = null
            previousWord            = null

            for split in getWordSplits(view, indices)
                options = @getSubWordsParams(view, split.lettersRange...)
                [startPoint, controlPoints..., endPoint] = split.pathPoints
                _.extend options,
                    startPoint: startPoint
                    controlPoints: controlPoints
                    endPoint: endPoint
                word = new PlantElement(options)

                if @lettersRangesAreAdjacent(previousSplit, split)
                    previousWord.set('nextLetter', text[split.lettersRange[0]])
                    word.set('previousLetter', text[previousSplit.lettersRange[1]])

                addOptions = {}
                if elemCollectionPosition?
                    addOptions.at = elemCollectionPosition
                    elemCollectionPosition = null
                newModelData.push([word, addOptions])

                if not previousWord?
                    firstWord = word
                    prevLetter =  origElemModel.get('previousLetter')
                    if prevLetter?
                        firstWord.set('previousLetter', prevLetter)

                previousSplit   = split
                previousWord    = word

            if previousWord?
                lastWord = previousWord
                nextLetter = origElemModel.get('nextLetter')
                if nextLetter?
                    lastWord.set('nextLetter', nextLetter)

            elemCollection.remove(origElemModel)
            for [word, addOptions] in newModelData
                elemCollection.add(word, addOptions)
                word

        getSubWordsParams: (view, startli, endli) ->
            text: view.model.get('text')[startli..endli]
            transformMatrix: view.model.get('transformMatrix')
            fontSize: view.model.get('fontSize')
            lettersAttributes: view.model.get('lettersAttributes')[startli..endli]

        lettersRangesAreAdjacent: (previousSplit, split) ->
            if not previousSplit?
                return false
            if not split?
                return false
            return previousSplit.lettersRange[1] + 1 == split.lettersRange[0]

        canSplitAt: (text, position) -> 0 < position < text.length

        getWordSplitContext: ->

            context = @canvasView.wordSplitContext

            if not context?
                return null

            model = context.model

            view = @canvasView.getElementViewByModelCid(model.cid)

            position:   context.position
            view:       view
            model:      model

        removeSplitContext:         -> @canvasView.wordSplitContext = null

        getSplitIndices: (args...)  -> getWordSplitIndices(args...)


    module.exports =
        SplitWordElement: SplitWordElement
