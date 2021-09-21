    'use strict'

    _ = require('underscore')
    {BaseModel, BaseCollection} = require('./base')
    {Operation, OperationType} = require('./../diffs/operations')


    class UnitChange extends BaseModel

        initialize: (options) =>
            super(options)
            setDefaultValue = (name, value) =>
                @set(name, value) if not @get(name)?
            setDefaultValue('operations', [])
            setDefaultValue('keyFrame', false)

        set: (key, val, options) ->
            # normalize input
            if typeof key == 'object'
                attrs = _.clone(key) or {}
                options = val
            else
                attrs = {}
                attrs[key] = val

            # apply operation wrappers
            for name in ['operations']
                if attrs[name]?
                    attrs[name] = (Operation.fromJSON(opData) for opData in attrs[name])

            if attrs.station
                attrs.keyFrame = false

            if attrs.keyFrame
                attrs.station = false

            super(attrs, options)

        toJSON: =>
            data = super()

            # dumping Operation objects to ordinary object
            for name in ['operations']
                data[name] = (op.toJSON() for op in data[name])

            data

    class UnitChanges extends BaseCollection
        model: UnitChange

        getDiffsSlice: (beginIndex=0, endIndex) ->
            changesSlice = @slice(beginIndex, endIndex)
            (change.get('operations') for change in changesSlice)


    module.exports =
        UnitChange: UnitChange
        UnitChanges: UnitChanges
        PlantChange: UnitChange
        PlantChanges: UnitChanges
