    'use strict'

    _ = require('underscore')
    {OperationType} = require('./diffs/operations')
    {getInvertedDiff, getInvertedDiffs} = require('./diffs/utils')


    isElementOperationContextNames = (ctxNames) ->
        ctxNames.length > 1 and ctxNames[0] == 'elements'


    isElementOperation = (operation) ->
        isElementOperationContextNames(operation.getContextNames())


    isElementPropertyOperationFactory = (opType, propName) ->
        (operation, options) ->
            if operation.type != opType
                return false

            level = options?.contextLevel or 0
            ctxNames = operation.getContextNames()

            if level == 0 and not isElementOperationContextNames(ctxNames)
                return false

            ctxNames.length == 3 - level and ctxNames[2 - level] == propName


    isElementTextReplace = isElementPropertyOperationFactory(
        OperationType.REPLACE, 'text')


    isElemendPathReplace = (operation, options) ->
        if operation.type != OperationType.REPLACE
            return false

        level = options?.contextLevel or 0
        ctxNames = operation.getContextNames()

        if level == 0 and not isElementOperationContextNames(ctxNames)
            return false

        if (ctxNames.length == 4 - level and
                ctxNames[2 - level] in ['startPoint', 'endPoint'] and
                ctxNames[3 - level] in ['x', 'y'])
            true
        else if (ctxNames.length == 5 - level and
                ctxNames[2 - level]  == 'controlPoints' and
                ctxNames[4 - level] in ['x', 'y'])
            true
        else
            false


    isElementLettersAttributesDelete = (operation, options) ->
        if operation.type != OperationType.DELETE
            return false

        level = options?.contextLevel or 0
        ctxNames = operation.getContextNames()

        if level == 0 and not isElementOperationContextNames(ctxNames)
            return false

        (ctxNames.length == 4 - level and
                ctxNames[2 - level] == 'lettersAttributes')


    isElementInsertion = (operation, options) ->
        if operation.type != OperationType.INSERT
            return false

        level = options?.contextLevel or 0
        ctxNames = operation.getContextNames()

        if level == 0 and not isElementOperationContextNames(ctxNames)
            return false

        ctxNames.length == 2 - level


    isElementDeletion = (operation, options) ->
        isElementInsertion(operation.getInverted(), options)


    isElementSpecificChange = (operation, elementIndex, options) ->
        level = options?.contextLevel or 0
        ctxNames = operation.getContextNames()

        if level == 0 and not isElementOperationContextNames(ctxNames)
            return false

        if ctxNames.length < 3 - level
            return false

        ctxNames[1 - level] == "#{elementIndex}"


    splitDiffAllowedOperationPredicates = [
        isElementLettersAttributesDelete
        isElementPropertyOperationFactory(OperationType.INSERT, 'nextLetter')
        isElementPropertyOperationFactory(OperationType.INSERT, 'previousLetter')
        isElementPropertyOperationFactory(OperationType.REPLACE, 'nextLetter')
        isElementPropertyOperationFactory(OperationType.REPLACE, 'previousLetter')
        isElementPropertyOperationFactory(OperationType.REPLACE, 'objectId')
        isElementTextReplace
        isElemendPathReplace
        isElementInsertion
    ]

    isSplitDiffAllowedOperation = (operation, options) ->
        _.any(splitDiffAllowedOperationPredicates, (pred) ->
            pred(operation, options))


    isElementSplitDiff = (diff, options) ->

        for op in diff
            if not isSplitDiffAllowedOperation(op, options)
                return false

        level = options?.contextLevel or 0
        indicesSet = {}

        if level <= 1
            for op in diff
                if isElementInsertion(op, options)
                    continue
                ctxNames = op.getContextNames()
                if ctxNames.length >= 2 - level
                    indicesSet[ctxNames[1 - level]] = 1

        if _.size(indicesSet) != 1
            return false

        textChangeOp = null

        # find unique text change operation
        for op in diff
            if isElementTextReplace(op, options)
                if textChangeOp?
                    # already found, noting to do here
                    return false
                else
                    textChangeOp = op

        if not textChangeOp?
            return false

        elementInsertionOps = (op for op in diff when isElementInsertion(
                                    op, options))

        if elementInsertionOps.length == 0
            return false

        startText = textChangeOp.oldValue
        endText = textChangeOp.newValue

        appendedTexts = (op.newValue.text for op in elementInsertionOps)

        texts = [endText].concat(appendedTexts)

        reconstructedText1 = texts.join('')
        reconstructedText2 = texts.join('')

        startText == reconstructedText1 or startText == reconstructedText2


    isElementSplitReversedDiff = (diff, options) ->
        isElementSplitDiff(getInvertedDiff(diff), options)

    isElementDeletionDiff = (diff, options) ->
        _.any(diff, (op) -> isElementDeletion(op, options))


    findElementInsertion = (diff, options) ->
        for op in diff
            if isElementInsertion(op, options)
                return op
        null


    isElementSpecificChangeDiff = (diff, elementIndex, options) ->
        _.all diff, (op) -> isElementSpecificChange(op, elementIndex, options)


    findElementInsertionAndChangesRange = (diffs, options) ->
        startPosition = options?.startPosition
        insOp = null
        if startPosition?
            # The insertion needs to be at startPosition
            insOp = findElementInsertion(diffs[startPosition])
        else
            # The insertion may occur later
            searchStartPosition = options?.searchStartPosition or 0
            for i in [searchStartPosition...diffs.length]
                diff = diffs[i]
                insOp = findElementInsertion(diff)
                if insOp?
                    startPosition = i
                    break

        if not insOp?
            return null

        ctxNames = insOp.getContextNames()
        elementIndex = ctxNames[ctxNames.length - 1]
        endPosition = startPosition + 1

        for i in [(startPosition + 1)...diffs.length]
            diff = diffs[i]
            if not isElementSpecificChangeDiff(diff, elementIndex, options)
                break
            endPosition = i + 1

        [startPosition, endPosition]


    findElementDeletionsRange = (diffs, options) ->
        startPosition = options.startPosition
        endPosition = startPosition
        for i in [startPosition...diffs.length]
            diff = diffs[i]
            if not isElementDeletionDiff(diff, options)
                break
            endPosition = i + 1

        if startPosition == endPosition
            return null

        [startPosition, endPosition]


    findCriticalDiffPositions = (diffs) ->
        positions = []

        for i in [0...diffs.length]
            diff = diffs[i]

            if isElementSplitDiff(diff) or isElementSplitReversedDiff(diff)
                positions.push(i)
                positions.push(i + 1)

        _.uniq(positions, true)


    findAutoKeyFramePositions = (diffs) ->
        positions = []
        i = 0

        while i < diffs.length
            diff = diffs[i]
            inc = 1

            if isElementSplitDiff(diff) or isElementSplitReversedDiff(diff)
                positions.push(i)
                positions.push(i + 1)
            else if (rng = findElementDeletionsRange(diffs, startPosition: i))?
                # put only the keyframe after the deletions
                positions.push(rng[1])
                inc = rng[1] - i
            else if (rng = findElementInsertionAndChangesRange(diffs, startPosition: i))?
                positions.push(rng[0])
                positions.push(rng[1])
                inc = rng[1] - i

            i += inc

        _.uniq(positions, true)


    module.exports =
        isElementSplitDiff: isElementSplitDiff
        isElementSplitReversedDiff: isElementSplitReversedDiff
        findElementInsertionAndChangesRange: findElementInsertionAndChangesRange
        findAutoKeyFramePositions: findAutoKeyFramePositions
        findCriticalDiffPositions: findCriticalDiffPositions
