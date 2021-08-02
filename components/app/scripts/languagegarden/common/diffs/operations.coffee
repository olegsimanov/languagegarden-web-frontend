    'use strict'

    _ = require('underscore')
    {
        structuralEquals
        enumerate
        deepCopy
        toIndex
        insertIntoArray
        replaceInArray
        deleteFromArray
    } = require('./../utils')
    {stringDiffReversible, stringSplice} = require('./strings')


    DefaultOperationInterface =
        isArray: (value) -> _.isArray(value)

        insertIntoArray: (arr, index, newValue) ->
            insertIntoArray(arr, index, deepCopy(newValue))

        replaceInArray: (arr, index, newValue) ->
            replaceInArray(arr, index, deepCopy(newValue))

        deleteFromArray: (arr, index) ->
            deleteFromArray(arr, index)

        insertIntoDict: (dict, key, newValue) ->
            dict[key] = deepCopy(newValue)

        replaceInDict: (dict, key, newValue) ->
            dict[key] = deepCopy(newValue)

        deleteFromDict: (dict, key) ->
            delete dict[key]

        getParentObject: (rootValue, contextNames) ->
            if contextNames.length == 0
                return null

            value = rootValue
            for name in contextNames[0...(contextNames.length - 1)]
                if @isArray(value)
                    value = value[toIndex(name)]
                else
                    value = value[name]
            value

        insertInPlace: (valueToApply, newValue) ->
            deepCopy(newValue)

        replaceInPlace: (valueToApply, newValue) ->
            deepCopy(newValue)

        deleteInPlace: (valueToApply) ->
            undefined


    OperationType =
        TEXT_REPLACE: 'text_replace'
        REPLACE: 'replace'
        INSERT: 'insert'
        DELETE: 'delete'
        NOOP: ''


    class Operation
        @typeMap = {}
        type: null
        iface: DefaultOperationInterface
        attributeNames: []

        @fromJSON: (data) ->
            cls = @typeMap[data.type]
            return new cls(data)

        @register: (cls) ->
            @typeMap[cls::type] = cls
            return this

        constructor: (options = {})->
            @context = options.context
            for attrName in @attributeNames
                @[attrName] = deepCopy(options[attrName])

        toJSON: ->
            data = {}
            data.type = @type
            data.context = @context
            for attrName in @attributeNames
                data[attrName] = deepCopy(@[attrName])
            data

        getContextNames: ->
            (name for name in @context.split('.') when name != '')

        getLastContextName: ->
            contextNames = @getContextNames()
            if contextNames.length == 0
                return null
            contextNames[contextNames.length - 1]

        getFirstContextName: ->
            contextNames = @getContextNames()
            if contextNames.length == 0
                return null
            contextNames[0]

        clonePrepended: (contextName) ->
            opCopy = @clone()
            if @context != ''
                opCopy.context = "#{contextName}.#{@context}"
            else
                opCopy.context = "#{contextName}"
            opCopy

        clone: ->
            cls = Operation.typeMap[@type]
            newObj = new cls()
            newObj.context = @context
            for attrName in @attributeNames
                newObj[attrName] = @[attrName]
            newObj

        getWithShiftedIndex: (level, delta) ->
            ctxNames = @getContextNames()
            index = toIndex(ctxNames[level])
            if _.isNaN(index)
                # index is not a numeric, returning unchanged operation
                this
            else
                opCopy = @clone()
                ctxNames[level] = index + delta
                opCopy.context = ctxNames.join('.')
                opCopy

        getInterface: (options) ->
            if options?.iface?
                options.iface
            else
                @iface

        isNoOp: -> false

        toString: ->
            "#{@type} at #{@context}"


    class Insert extends Operation
        type: OperationType.INSERT
        attributeNames: ['newValue']

        getInverted: ->
            new Delete
                context: @context
                oldValue: @newValue

        apply: (value, options) ->
            iface = @getInterface(options)
            if not @context
                return iface.insertInPlace(value, @newValue)
            parentObject = iface.getParentObject(value, @getContextNames())
            key = @getLastContextName()
            if iface.isArray(parentObject)
                index = toIndex(key)
                iface.insertIntoArray(parentObject, index, @newValue)
            else
                iface.insertIntoDict(parentObject, key, @newValue)
            value

        toString: ->
            "#{super} value #{JSON.stringify(@newValue)}"


    class Delete extends Operation
        type: OperationType.DELETE
        attributeNames: ['oldValue']  # the old value is needed for reversing the operation

        getInverted: ->
            new Insert
                context: @context
                newValue: @oldValue

        apply: (value, options) ->
            iface = @getInterface(options)
            if not @context
                return iface.deleteInPlace(value, @oldValue)
            parentObject = iface.getParentObject(value, @getContextNames())
            key = @getLastContextName()
            if iface.isArray(parentObject)
                index = toIndex(key)
                iface.deleteFromArray(parentObject, index, @oldValue)
            else
                iface.deleteFromDict(parentObject, key, @oldValue)
            value

        toString: ->
            "#{super} value #{JSON.stringify(@oldValue)}"


    class Replace extends Operation
        type: OperationType.REPLACE
        attributeNames: ['oldValue', 'newValue']  # the old value is needed for reversing the operation

        getInverted: ->
            new Replace
                context: @context
                oldValue: @newValue
                newValue: @oldValue

        apply: (value, options) ->
            iface = @getInterface(options)
            if not @context
                return iface.replaceInPlace(value, @newValue, @oldValue)
            parentObject = iface.getParentObject(value, @getContextNames())
            key = @getLastContextName()
            if _.isArray(parentObject)
                index = toIndex(key)
                iface.replaceInArray(parentObject, index, @newValue, @oldValue)
            else
                iface.replaceInDict(parentObject, key, @newValue, @ )
            value

        toString: ->
            "#{super} value #{JSON.stringify(@oldValue)} to #{JSON.stringify(@newValue)}"


    class TextReplace extends Operation
        type: OperationType.TEXT_REPLACE

        attributeNames: [
            # first and last change of the operation
            'oldValue', 'newValue',
            # list of (index, insertedStr, replacedStr) tuples
            'changes',
        ]

        constructor: (options={}) ->
            super
            @changes ?= []

            # when creating a new instance, calculate initial change based on
            # oldValue/newValue
            @appendChange(@newValue, @oldValue) if @changes.length == 0

        getInverted: ->
            new TextReplace
                context: @context
                oldValue: @newValue
                newValue: @oldValue
                changes: @reversedChanges()

        reversedChanges: ->
            for change in @changes.slice(0).reverse()
                index: change.index
                inserted: change.replaced
                replaced: change.inserted

        appendChange: (newValue, oldValue=@newValue) ->
            diff = stringDiffReversible(oldValue, newValue)

            @changes.push
                index: diff[0]
                replaced: diff[1]
                inserted: diff[2]

            @newValue = newValue

        applyChange: (oldValue, change) ->
            stringSplice(
                oldValue,
                change.index, change.replaced.length, change.inserted)

        getStoredStates: ->
            states = []
            oldValue = @oldValue
            states.push(oldValue)
            for change in @changes
                states.push(oldValue = @applyChange(oldValue, change))
            states

        getReplaceOperations: ->
            oldValue = @oldValue
            operations = []
            for change in @changes
                newValue = @applyChange(oldValue, change)
                op = new Replace
                        context: @context or ''
                        oldValue: oldValue
                        newValue: newValue
                operations.push(op)
                oldValue = newValue
            operations


        apply: (value, options) ->
            iface = @getInterface(options)
            if not @context
                return iface.replaceInPlace(value, @newValue, @oldValue)
            parentObject = iface.getParentObject(value, @getContextNames())
            key = @getLastContextName()
            if _.isArray(parentObject)
                index = toIndex(key)
                iface.replaceInArray(parentObject, index, @newValue, @oldValue)
            else
                iface.replaceInDict(parentObject, key, @newValue, @ )
            value

        toString: ->
            "#{super} value #{JSON.stringify(@oldValue)} to
            #{JSON.stringify(@newValue)},
            diff at: #{@index}, inserted: #{@inserted}, removed: #{@removed}"


    class NoOp extends Operation
        type: OperationType.NOOP

        constructor: (options = {})->
            super
            @context ?= ''

        getInverted: -> this

        apply: (value, options) -> value

        isNoOp: -> true


    Operation
    .register(NoOp)
    .register(Insert)
    .register(Delete)
    .register(Replace)
    .register(TextReplace)


    module.exports =
        Operation: Operation
        OperationType: OperationType
        DefaultOperationInterface: DefaultOperationInterface
