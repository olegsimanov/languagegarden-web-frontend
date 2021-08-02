    'use strict'

    _ = require('underscore')
    {enumerate, toIndex} = require('./../utils')
    {Operation, OperationType} = require('./operations')
    {reduceDiff} = require('./reductions')


    getSharedContextNames = (contextNames1, contextNames2) ->
        sharedContextNames = []
        for [name1, name2] in _.zip(contextNames1, contextNames2)
            if name1 == name2
                sharedContextNames.push(name1)
            else
                break
        sharedContextNames


    getOperationWithShiftedIndex = (operation, level, delta) ->
        operation.getWithShiftedIndex(level, delta)


    ###
    we assume that context of op is wider than the context of prependedOp
    ###
    defaultMakeOperationCoherent = (prependedOp, op) ->
        diff = reduceDiff([prependedOp.getInverted(), op])
        if diff.length == 0
            # reduced to empty diff - returning noop
            Operation.fromJSON
                type: OperationType.NOOP
                context: prependedOp.context
        else
            # assert only one element in diff
            diff[0]

    defaultRebaseOperation = (prependedOperation, operation, options) ->
        prepCtxNames = prependedOperation.getContextNames()
        ctxNames = operation.getContextNames()
        sharedCtxNames = getSharedContextNames(prepCtxNames, ctxNames)
        prepCtxLen = prepCtxNames.length
        ctxLen = ctxNames.length
        sharedCtxLen = sharedCtxNames.length
        makeOperationCoherent = options?.makeOperationCoherent or defaultMakeOperationCoherent

        if sharedCtxLen < ctxLen and sharedCtxLen < prepCtxLen
            # the contexts are diverging

            if sharedCtxLen + 1 == prepCtxLen
                # the prepended operation context is diverging by one
                # context name
                level = prepCtxLen - 1
                prepIndex = toIndex(prepCtxNames[level])
                index = toIndex(ctxNames[level])
                if not _.isNaN(prepIndex) and not _.isNaN(index) and prepIndex < index
                    # the insert/delete operations on an array cause
                    # the indexes to be shifted
                    if prependedOperation.type == OperationType.INSERT
                        return getOperationWithShiftedIndex(operation, level, 1)
                    else if prependedOperation.type == OperationType.DELETE
                        return getOperationWithShiftedIndex(operation, level, -1)

            # in other case, operation is unaffected, nothing to do there
            operation
        else if sharedCtxLen == prepCtxLen
            # the operation context is narrower than or equal the prepended
            # operation context, therefore the next operations may still be
            # affected.
            if prepCtxLen > 0
                level = prepCtxLen - 1
                if not _.isNaN(toIndex(prepCtxNames[level]))
                    if prependedOperation.type == OperationType.INSERT
                        return getOperationWithShiftedIndex(operation, level, 1)

            if prependedOperation.type == OperationType.DELETE
                #TODO: test
                if operation.type == OperationType.DELETE and sharedCtxLen == ctxLen
                    # we met deletion from the future - the rest of operations
                    # is not affected!
                    options.stopPropagation()
                # drop current operation (use NoOp operation)
                Operation.fromJSON
                    type: OperationType.NOOP
                    context: operation.context

            else
                # assert prependedOperation.type == OperationType.REPLACE
                #TODO: test
                if sharedCtxLen == ctxLen
                    # prepended operation and current operation are operating
                    # at the same context. therefore we need to make the
                    # current operation coherent with the prepended operation
                    # and we stop propagation, because the next operations
                    # are not affected
                    options.stopPropagation()
                    makeOperationCoherent(prependedOperation, operation)
                else
                    # in other cases, the parent structure has been modified
                    # by the prepended operation, therefore we drop the
                    # current operation (by using NoOp)
                    Operation.fromJSON
                        type: OperationType.NOOP
                        context: operation.context
        else if sharedCtxLen == ctxLen # and sharedCtxLen < prepCtxLen
            # the operation context is wider than the prepended
            # operation context, therefore the next operations aren't affected
            # but this operation may be affected.
            #TODO: test
            options.stopPropagation()
            makeOperationCoherent(prependedOperation, operation)
        else
            operation


    defaultRebaseDiff = (prependedOperation, diff, options) ->
        if options.isPropagationStopped()
            diff
        else
            rebaseOperation = options.rebaseOperation or defaultRebaseOperation
            newDiff = []
            for op in diff
                if options.isPropagationStopped()
                    newOp = op
                else
                    newOp = rebaseOperation(prependedOperation, op, options)
                newDiff.push(newOp) if not newOp.isNoOp()
            newDiff


    rebaseDiffs = (prependedDiff, diffs, options={}) ->

        diffHandler = options.handler or options.diffHandler
        operationHandler = options.operationHandler

        if diffHandler?
            rebaseDiff = (prependedOperation, diff, options) ->
                rebasedDiff = diffHandler(prependedOperation, diff, options)
                if rebasedDiff?
                    rebasedDiff
                else
                    defaultRebaseDiff(prependedOperation, diff, options)
        else
            rebaseDiff = defaultRebaseDiff

        if operationHandler?
            rebaseOperation = (prependedOperation, operation, options) ->
                rebasedOp = operationHandler(prependedOperation, operation, options)
                if rebasedOp?
                    rebasedOp
                else
                    defaultRebaseOperation(prependedOperation, operation, options)
        else
            rebaseOperation = defaultRebaseOperation

        # this is useful to share information of specific diff between
        # different prepended operations
        diffsOptions = ({} for i in [0...diffs.length])

        firstOp = true

        for prependedOp in prependedDiff
            do ->
                prependedOperation = prependedOp
                propagate = true
                opts = _.extend {}, options,
                    rebaseOperation: rebaseOperation
                    stopPropagation: -> propagate = false
                    isPropagationStopped: -> not propagate
                    replacePrependedOperation: (op) ->
                        prependedOperation = op
                    initialPrependOperation: firstOp

                newDiffs = []
                for [i, diff] in enumerate(diffs)
                    opts.diffOptions = diffsOptions[i]
                    newDiffs.push(rebaseDiff(prependedOperation, diff, opts))
                diffs = newDiffs
            firstOp = false

        diffs


    module.exports =
        defaultRebaseOperation: defaultRebaseOperation
        rebaseDiffs: rebaseDiffs
