    'use strict'

    _ = require('underscore')
    {Action} = require('./base')
    {Line} = require('./../../math/lines')
    {Point} = require('./../../math/points')
    {PlantElement} = require('./../models/elements')
    {
        getWordSplits
        getSentenceSplitIndices
        getWordSplitIndices
    } = require('./../../common/views/elementsplit')


    class SplitActionBase extends Action

        lettersRangesAreAdjacent: (previousSplit, split) ->
            if not previousSplit?
                return false
            if not split?
                return false
            return previousSplit.lettersRange[1] + 1 == split.lettersRange[0]

        ###Performs the splitting by indices. Does not perform any assertions
        based on the word content, simply adds the words required.
        ###
        splitWord: (view, indices) ->
            origElemModel = view.model
            elemCollection = @model.elements
            text = origElemModel.get('text')
            indices ?= @getSplitIndices(text)
            elemCollectionPosition = elemCollection.indexOf(origElemModel)

            newModelData = []

            previousSplit = null
            previousWord = null

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
                    # word is the first word
                    firstWord = word
                    prevLetter =  origElemModel.get('previousLetter')
                    if prevLetter?
                        firstWord.set('previousLetter', prevLetter)

                previousSplit = split
                previousWord = word

            if previousWord?
                # previousWord is the last word
                lastWord = previousWord
                nextLetter = origElemModel.get('nextLetter')
                if nextLetter?
                    lastWord.set('nextLetter', nextLetter)

            elemCollection.remove(origElemModel)
            for [word, addOptions] in newModelData
                elemCollection.add(word, addOptions)
                word

        ### Returns attributes to copy from the original model. ###
        getSubWordsParams: (view, startli, endli) ->
            text: view.model.get('text')[startli..endli]
            transformMatrix: view.model.get('transformMatrix')
            fontSize: view.model.get('fontSize')
            lettersAttributes: view.model.get('lettersAttributes')[startli..endli]

        ###Override this to return the desired split positions.###
        getSplitIndices: (text) ->
            console.log('getSplitIndices method missing!')


    class SplitSentenceElement extends SplitActionBase

        id: 'sentence-split'

        getViewsToProcess: -> @canvasView.getSelectedElementViews()

        perform: ->
            for elemView in @getViewsToProcess()
                if @canSplit(elemView.model)
                    @splitWord(elemView)
            true

        isAvailable: ->
            models = @canvasView.getSelectedElements()
            models.length == 1 and @canSplit(models)

        ### At least one of the selected words must contain a space. ###
        canSplit: (models) ->
            models = [models] if not _.isArray(models)
            _.some models, (e) => e.get('text').search(' ') != -1

        getSplitIndices: (args...) => getSentenceSplitIndices(args...)


    class SplitWordElement extends SplitActionBase

        id: 'word-split'

        isAvailable: ->
            if @canvasView.insertView?
                @canvasView.insertView.canSplitWord()
            else if @canvasView.wordSplitContext?
                {model, position} = @getWordSplitContext()
                @canSplitAt(model.get('text'), position)
            else
                false

        canSplitAt: (text, position) ->
            # note: zero is before the first letter
            0 < position < text.length

        getWordSplitContext: ->

            context = @canvasView.wordSplitContext

            if not context?
                return null

            model = context.model

            view = @canvasView.getElementViewByModelCid(model.cid)

            position: context.position
            view: view
            model: model

        removeSplitContext: ->
            @canvasView.wordSplitContext = null

        perform: ->
            {position, view, model} = @getWordSplitContext()
            text = model?.get('text')

            @removeSplitContext()

            # with the auto-trimming on insert, we need to re-check if the
            # user did not attempt to just cut off the trailing/leading spaces
            # in which case there is nothing to do
            if text and @canSplitAt(text, position)
                # if parameters are valid, cut the word in half
                model = @splitWord(view, @getSplitIndices(text, position))[0]
                makesnapshot = true

            # Re-selecting the model after cutting
            #
            # The canvasView.startUpdating does it's own stopTrackingChanges that
            # collides with this action's calling startTrackingChanges before
            # returning. Delaying the call untill action finishes.
            _.delay => @canvasView.startUpdating(model) if model?

            makesnapshot or false

        getSplitIndices: (args...) -> getWordSplitIndices(args...)


    module.exports =
        SplitSentenceElement: SplitSentenceElement
        SplitWordElement: SplitWordElement
