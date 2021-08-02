    'use strict'

    _ = require('underscore')
    {structuralEquals} = require('./../utils')
    {Operation, OperationType} = require('./operations')


    ###
    Find the duplication indices of ALL elements in oldValue in newValue.
    for instance for parameters [1, 4]; [1, 2, 3, 4] it should return [0, 3].
    If not all elements are found on newValue, return null.
    ###
    findDuplicationIndices = (oldValue, newValue) ->
        if oldValue.length > newValue.length
            return null

        j = 0
        indices = []
        for i in [0...oldValue.length]
            equals = false
            while j < newValue.length
                equals = structuralEquals(oldValue[i], newValue[j])
                if equals
                    break
                j += 1
            if equals
                indices.push(j)
                j += 1
            else
                return null

        indices


    ###
    Find the diff containing array insertions. If these insertions cannot
    be found then return null.
    ###
    getArrayInsertions = (oldValue, newValue, options) ->
        dupIndices = findDuplicationIndices(oldValue, newValue)
        if not dupIndices?
            return null

        context = options.context
        prefix = if context then "#{context}." else ""

        dupIndices = dupIndices.concat([newValue.length])

        operations = []

        prevDupIndex = 0
        for i in dupIndices
            for j in [prevDupIndex...i]
                operations.push(Operation.fromJSON
                    type: OperationType.INSERT
                    context: "#{prefix}#{j}"
                    newValue: newValue[j]
                )
            prevDupIndex = i + 1

        operations


    ###
    Find the diff containing array deletions. If these deletions cannot
    be found then return null.
    ###
    getArrayDeletions = (oldValue, newValue, options) ->
        operations = getArrayInsertions(newValue, oldValue, options)
        if not operations?
            return null
        getInvertedDiff(operations)


    ###
    note: this solution does not calculate the perfect (optimal) diff
    for changes in array. calculating the optimal solution would require
    some algorithm using dynamic programming method. But since usually there
    will be at most one element added/removed to/from the array the currently
    implemented solution will produce the optimal result.

    the current solution finds the region (range) for the new array and the
    old array where is the difference ([oldDiffStart...oldDiffEnd],
    [newDiffStart...newDiffEnd]). Then it applies the replacements, and uses
    insertions/deletions where the range lengths differ.
    ###
    getSuboptimalDiffOfArrays = (oldValue, newValue, options) ->
        context = options.context
        prefix = if context then "#{context}." else ""

        oldDiffStart = 0
        oldDiffEnd = oldValue.length
        newDiffStart = 0
        newDiffEnd = newValue.length

        for [oldElem, newElem] in _.zip(oldValue, newValue)
            if structuralEquals(oldElem, newElem)
                oldDiffStart += 1
                newDiffStart += 1
            else
                break

        oldTailRev = oldValue[oldDiffStart..].reverse()
        newTailRev = newValue[newDiffStart..].reverse()
        minTailLen = _.min([oldTailRev.length, newTailRev.length])

        oldTailRev = oldTailRev[0...minTailLen]
        newTailRev = newTailRev[0...minTailLen]

        for [oldElem, newElem] in _.zip(oldTailRev, newTailRev)
            if structuralEquals(oldElem, newElem)
                oldDiffEnd -= 1
                newDiffEnd -= 1
            else
                break

        oldDiffRange = [oldDiffStart...oldDiffEnd]
        newDiffRange = [newDiffStart...newDiffEnd]
        minDiffLen = _.min([oldDiffRange.length, newDiffRange.length])

        operations = []

        for i in oldDiffRange[minDiffLen..].reverse()
            operations.push(Operation.fromJSON
                type: OperationType.DELETE
                context: "#{prefix}#{i}"
                oldValue: oldValue[i])

        for [i,j] in _.zip(oldDiffRange[0...minDiffLen], newDiffRange[0...minDiffLen])
            subOptions = _.extend {}, options,
                context: "#{prefix}#{i}"
            diff = getDiff(oldValue[i], newValue[j], subOptions)
            operations.push(diff...)

        for j in newDiffRange[minDiffLen..]
            operations.push(Operation.fromJSON
                type: OperationType.INSERT
                context: "#{prefix}#{j}"
                newValue: newValue[j])

        operations


    ###
    Note: this does not generate optimal diffs. See the description of
    getSuboptimalDiffOfArrays for details.
    ###
    getDiffOfArrays = (oldValue, newValue, options) ->
        # handling special case when we have only insertions
        operations = getArrayInsertions(oldValue, newValue, options)
        if operations?
            return operations

        # handling special case when we have only deletions
        operations = getArrayDeletions(oldValue, newValue, options)
        if operations?
            return operations

        getSuboptimalDiffOfArrays(oldValue, newValue, options)


    getDiffOfDicts = (oldValue, newValue, options) ->
        context = options.context
        operations = []
        newKeys = _.keys(newValue)
        oldKeys = _.keys(oldValue)
        insertedKeys = _.difference(newKeys, oldKeys)
        deletedKeys = _.difference(oldKeys, newKeys)
        sharedKeys = _.intersection(newKeys, oldKeys)
        prefix = if context then "#{context}." else ""

        for key in insertedKeys
            operations.push(Operation.fromJSON
                    type: OperationType.INSERT
                    context: "#{prefix}#{key}"
                    newValue: newValue[key])

        for key in deletedKeys
            operations.push(Operation.fromJSON
                type: OperationType.DELETE
                context: "#{prefix}#{key}"
                oldValue: oldValue[key])

        for key in sharedKeys
            subOptions = _.extend {}, options,
                context: "#{prefix}#{key}"
            for op in getDiff(oldValue[key], newValue[key], subOptions)
                operations.push(op)

        #TODO: perform compression if all keys are replaced
        operations


    isPatternContext = (context, ctxPatterns) ->
        _.any(ctxPatterns, (re) -> re.exec(context))


    ###
    gets the diff from two values, assuming that they are JSON-friendly
    data structures.
    ###
    getDiff = (oldValue, newValue, options={}) ->
        operations = []
        context = options.context or ''
        replaceCtxPatterns = options.replacementContextPatterns or []

        if _.isArray(newValue)
            if not _.isArray(oldValue)
                operations.push(Operation.fromJSON
                    type: OperationType.REPLACE
                    context: context
                    newValue: newValue
                    oldValue: oldValue)
            else
                if isPatternContext(context, replaceCtxPatterns)
                    if not _.isEqual(oldValue, newValue)
                        operations.push(Operation.fromJSON
                            type: OperationType.REPLACE
                            context: context
                            newValue: newValue
                            oldValue: oldValue)
                else
                    operations = getDiffOfArrays(oldValue, newValue, options)

        else if _.isObject(newValue)
            if not _.isObject(oldValue) or _.isArray(oldValue)
                operations.push(Operation.fromJSON
                    type: OperationType.REPLACE
                    context: context
                    newValue: newValue
                    oldValue: oldValue)
            else
                if isPatternContext(context, replaceCtxPatterns)
                    if not _.isEqual(oldValue, newValue)
                        operations.push(Operation.fromJSON
                            type: OperationType.REPLACE
                            context: context
                            newValue: newValue
                            oldValue: oldValue)
                else
                    operations = getDiffOfDicts(oldValue, newValue, options)
        else
            if newValue != oldValue
                operations.push(Operation.fromJSON
                    type: OperationType.REPLACE
                    context: context
                    newValue: newValue
                    oldValue: oldValue)

        operations

    ###
    Returns an Operation for a text replace operation. This operation can have
    multiple subsequent edits appended.
    ###
    getTextDiff = (oldValue, newValue, options={}) ->
        operations = []
        context = options.context or ''

        operations.push(Operation.fromJSON
            type: OperationType.TEXT_REPLACE
            context: context
            oldValue: oldValue
            newValue: newValue)

        operations

    ###
    applies the diff on given value and returns the new value.

    WARNING: this function modifies the data, so be sure to deepCopy() the
    value first if you want to preserve the old changes.
    ###
    applyDiff = (value, diff, options) ->
        for operation in diff
            value = operation.apply(value, options)
        value


    ###
    dumps the diff (list of operations) for diagnostic purposes.
    ###
    dumpDiff = (diff) ->
        operationStrings = (op.toString() for op in diff)
        operationStrings.join('\n')


    ###
    inverts the diff (list of operations) and as the result returns
    the diff (list of operations) which can be used to revert the changes
    made by the input diff.
    ###
    getInvertedDiff = (diff) ->
        invOperations = (operation.getInverted() for operation in diff)
        invOperations.reverse()


    ###
    inverts the list of diffs
    ###
    getInvertedDiffs = (diffs) ->
        invDiffs = (getInvertedDiff(diff) for diff in diffs)
        invDiffs.reverse()

    ###
    splits the diff into a list containing pairs in the form
    (attribute, attributeDiff). the attribute could be also an empty string
    which means that diff should be applied on the whole object, not its
    attribute.
    reduceContext=true will remove the nonempty attribute from the operations
    context.
    the differenceFunction is an optional parameter, which can be
    used for instance when we want to differentiate just between
    'empty/nonempty' attribute.

    basically, this function works similar to _.groupBy, but uses the array
    instead of a dict to preserve the order of operations.
    ###
    splitDiff = (diff, reduceContext=true, differenceFunction) ->
        differenceFunction = differenceFunction or (a, b) -> a != b
        attrsChanges = []
        lastAttrName = null
        lastChanges = null
        for op in diff
            path = op.context.split('.')
            attrName = if path.length > 0 then path[0] else ''
            if differenceFunction(lastAttrName, attrName)
                lastChanges = []
                attrsChanges.push([attrName, lastChanges])
            rest = path[1..].join('.')
            if reduceContext
                opCopy = op.clone()
                opCopy.context = rest
            else
                opCopy = op
            lastChanges.push(opCopy)
            lastAttrName = attrName
        attrsChanges


    rewindUsingDiffs = (value, diffs, currentPosition, rewindPosition, options) ->
        while currentPosition > rewindPosition
            diff = diffs[currentPosition - 1]
            invDiff = getInvertedDiff(diff)
            value = applyDiff(value, invDiff, options)
            currentPosition -= 1

        while currentPosition < rewindPosition
            diff = diffs[currentPosition]
            value = applyDiff(value, diff, options)
            currentPosition += 1
        value


    module.exports =
        getDiff: getDiff
        getTextDiff: getTextDiff
        getInvertedDiff: getInvertedDiff
        getInvertedDiffs: getInvertedDiffs
        applyDiff: applyDiff
        dumpDiff: dumpDiff
        splitDiff: splitDiff
        rewindUsingDiffs: rewindUsingDiffs
