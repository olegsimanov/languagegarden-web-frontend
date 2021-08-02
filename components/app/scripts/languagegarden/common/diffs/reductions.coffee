    'use strict'

    _ = require('underscore')
    {
        structuralEquals
        enumerate
        deepCopy
        toIndex
        insertIntoArray
        deleteFromArray
    } = require('./../utils')
    {Operation, OperationType} = require('./operations')
    {getInvertedDiff} = require('./utils')


    ###
    Helper class used for holding children of ReductionNode. the behavior of
    this collection (whether it is array or a dict-like object) depends on the
    first context name retrieved (see this.ensureSetupUsingContextName() for
    details).
    ###
    class ReductionChildrenNodes

        constructor: ->
            @nodes = null

        setupNodesAsArray: ->
            # array
            @_reset = => @nodes = []
            @_getKeyOrIndex = toIndex
            @_getIndices = => [0...@nodes.length]
            @_remove = (name) =>
                deleteFromArray(@nodes, toIndex(name))
            @_insert = (name) =>
                index = toIndex(name)
                newNode = new ReductionNode()
                if _.size(@nodes) < index
                    @nodes[index] = newNode
                else
                    # this will shift all elements bigger than index
                    insertIntoArray(@nodes, index, newNode)
                @nodes[index]
            @_replace = (name) =>
                index = toIndex(name)
                if not @nodes[index]?
                    @nodes[index] = new ReductionNode()
                @nodes[index]
            @_processNameForDelete = (name) =>
                # this allows us to move the delete operation
                # before other insert operations.
                index = toIndex(name)
                shift = 0
                for node in @nodes[0...index]
                    if node? and node.insertion
                        shift += 1
                return index - shift

        setupNodesAsDict: ->
            # dict
            @_reset = => @nodes = {}
            @_getKeyOrIndex = _.identity
            @_getIndices = => _.keys(@nodes)
            @_remove = (name) =>
                delete @nodes[name]
            @_insert = (name) =>
                @nodes[name] = new ReductionNode()
                @nodes[name]
            @_replace = (name) =>
                if not @nodes[name]?
                    @nodes[name] = new ReductionNode()
                @nodes[name]
            @_processNameForDelete = _.identity


        ensureSetupUsingContextName: (name) ->
            if @nodes?
                return
            if _.isNaN(toIndex(name))
                # dict
                @setupNodesAsDict()
            else
                # array
                @setupNodesAsArray()

            @reset()

        isEmpty: -> if @nodes? then _.isEmpty(@nodes) else true

        reset: -> @_reset?()

        getIndices: -> @_getIndices?() or []

        getKeys: -> @getIndices()

        get: (name) ->
            @ensureSetupUsingContextName(name)
            @nodes[@_getKeyOrIndex(name)]

        retrieve: (name, insertFlag) ->
            @ensureSetupUsingContextName(name)
            if insertFlag
                @_insert(name)
            else
                @_replace(name)

        processNameForDelete: (name) ->
            if _.isFunction(@_processNameForDelete)
                @_processNameForDelete(name)
            else
                name

        remove: (name) -> @_remove(name)

        getKeyValuePairs: ->
            ([key, @get(key)] for key in @getKeys())

    ###
    Helper class used by reduceDiff function
    ###
    class ReductionNode

        constructor: ->
            @childrenOperations = []
            @children = new ReductionChildrenNodes()

            @insertion = false
            @replacement = false
            @deletion = false

            @newValue = null
            @oldValue = null

        isEmpty: ->
            (not @insertion and not @replacement and not @deletion and
                @children.isEmpty() and _.isEmpty(@childrenOperations))

        ###
        helper method for forwardToChild. reduces the insertion node
        to replacement node, occasionaly to empty node if oldValue and
        this.newValue are the same.

        assert this.insertion == true
        ###
        upgradeInsertionToReplacement: (oldValue) ->
            if _.isEqual(oldValue, @newValue)
                # replacing to the same value -> noop
                @oldValue = null
                @newValue = null
                @insertion = false
                @replacement = false
            else
                @oldValue = oldValue
                @insertion = false
                @replacement = true

        ###
        forwards the operation to child node
        ###
        forwardToChild: (op) ->
            [contextName, rest...] = op.getContextNames()
            # we set only the insert flag when we have insert operation
            # and the contextName is the last
            insertFlag = op.type == OperationType.INSERT and rest.length == 0
            subNode = @children.retrieve(contextName, insertFlag)
            opCopy = op.clone()
            opCopy.context = rest.join('.')
            subNode.addOperation(opCopy)

            # special case: child reduced to delete - we have to remove it
            # from children to preserve order in case
            if subNode.deletion
                [deletionOp] = subNode.getDiff()
                deleteContextName = @children.processNameForDelete(contextName)
                @childrenOperations.push(deletionOp.clonePrepended(deleteContextName))
                @children.remove(contextName)

            else if subNode.insertion
                subDiff = subNode.getDiff()
                if subDiff.length == 1 and @childrenOperations.length > 0
                    deleteContextName = @children.processNameForDelete(contextName)
                    insertOp = subDiff[0].clonePrepended(deleteContextName)
                    deleteOp = @childrenOperations[@childrenOperations.length - 1]
                    insertCtxNames = insertOp.getContextNames()
                    deleteCtxNames = deleteOp.getContextNames()
                    if (insertOp.type == OperationType.INSERT and
                            deleteOp.type == OperationType.DELETE and
                            _.isEqual(insertCtxNames, deleteCtxNames))
                        # deletion-insertion case - reducing to replace
                        subNode.upgradeInsertionToReplacement(deleteOp.oldValue)
                        @childrenOperations.pop()
            if subNode.isEmpty()
                # the subNode was reduced to empty reduction
                # (no-op), therefore we can delete it
                @children.remove(contextName)


        ###
        Here the reduction magick happens.
        ###
        addOperation: (op) ->
            contextNames = op.getContextNames()
            if contextNames.length == 0
                if op.type == OperationType.INSERT
                    @insertion = true
                    @newValue = deepCopy(op.newValue)
                else if op.type in [OperationType.REPLACE, OperationType.TEXT_REPLACE]
                    if not @insertion and not @replacement
                        @replacement = true
                        @oldValue = deepCopy(op.oldValue)
                        if not @children.isEmpty() or not _.isEmpty(@childrenOperations)
                            # reduce whole replacement & all suboperations
                            # to one replacement
                            childrenDiff = @getChildrenDiff()
                            for childOp in getInvertedDiff(childrenDiff)
                                @oldValue = childOp.apply(@oldValue)
                            @resetChildren()
                    @newValue = deepCopy(op.newValue)
                else if op.type == OperationType.DELETE
                    if @insertion
                        # insertion-deletion case - we can remove everything,
                        # this is equivalent to noop (diff of 0 size)
                        @insertion = false
                        @replacement = false
                        @deletion = false
                        @resetChildren()
                    else if @replacement
                        # we had replacement previously, therefore
                        # this.oldValue is already properly set
                        # (the oldValue of deletion is actually newValue
                        # of replacement)
                        @deletion = true
                        @replacement = false
                    else
                        @deletion = true
                        @oldValue = deepCopy(op.oldValue)
                        if not @children.isEmpty() or not _.isEmpty(@childrenOperations)
                            # case similar for the replacement:
                            # reduce whole deletion & all suboperations
                            # to one deletion
                            childrenDiff = @getChildrenDiff()
                            for childOp in getInvertedDiff(childrenDiff)
                                @oldValue = childOp.apply(@oldValue)
                            @resetChildren()

            else # if contextNames.length > 0
                if @insertion or @replacement
                    # whole value already added, apply the changes on it
                    # instead of forwarding operation to children
                    @newValue = op.apply(@newValue)
                else
                    @forwardToChild(op)

        ###
        resets the children operations & children structure
        ###
        resetChildren: ->
            @children.reset()
            @childrenOperations = []

        ###
        returns the diff from childrenOperations & children structure
        ###
        getChildrenDiff: ->
            result = @childrenOperations[..]
            for [name, node] in @children.getKeyValuePairs()
                if not node?
                    # there nodes in chilrden may be an array which
                    # has some undefined elements
                    continue
                diff = node.getDiff()
                for op in diff
                    result.push(op.clonePrepended(name))
            result

        getDiff: ->
            if @insertion
                op = Operation.fromJSON
                    type: OperationType.INSERT
                    context: ''
                    newValue: @newValue
                [op]
            else if @replacement
                if _.isEqual(@oldValue, @newValue)
                    # replacing the same value, which is an empty diff
                    []
                else
                    op = Operation.fromJSON
                        type: OperationType.REPLACE
                        context: ''
                        oldValue: @oldValue
                        newValue: @newValue
                    [op]
            else if @deletion
                op = Operation.fromJSON
                    type: OperationType.DELETE
                    context: ''
                    oldValue: @oldValue
                [op]
            else
                @getChildrenDiff()


    reduceDiff = (diff) ->
        node = new ReductionNode()
        for op in diff
            node.addOperation(op)
        node.getDiff()


    module.exports =
        reduceDiff: reduceDiff
