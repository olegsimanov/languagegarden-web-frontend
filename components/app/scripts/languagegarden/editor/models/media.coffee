    'use strict'

    _ = require('underscore')

    {BaseModel}         = require('./base')
    {BaseCollection}    = require('./collection')
    {VisibilityType}    = require('./../constants')
    {deepCopy}          = require('./../utils')
    {Point}             = require('./../math/points')


    class PlantMediumModel extends BaseModel

        initialize: (options) ->
            super
            if not @has('visibilityType')
                @set('visibilityType', VisibilityType.DEFAULT)
            @setDefaultValue('centerPoint', new Point(0,0))
            @setDefaultValue('scaleVector', new Point(1,1))
            @setDefaultValue('maxDeviationVector', null)
            @setDefaultValue('rotateAngle', 0)

        set: (key, val, options) ->
            if typeof key == 'object'
                attrs = _.clone(key) or {}
                options = val
            else
                attrs = {}
                attrs[key] = val

            for name in ['centerPoint', 'scaleVector', 'maxDeviationVector']
                if attrs[name]?
                    attrs[name] = Point.fromValue(attrs[name])

            for name in ['textElements', 'noteTextContent']
                if attrs[name]?
                    attrs[name] = deepCopy(attrs[name])

            super(attrs, options)

        toJSON: =>
            data = super

            for name in ['centerPoint', 'scaleVector']
                data[name] = data[name].toJSON()

            for name in ['textElements', 'noteTextContent']
                if data[name]?
                    data[name] = deepCopy(data[name])

            data

        clear: (options) ->
            result = super
            @trigger('clear', this)
            result

    module.exports =
        PlantMediumModel:           PlantMediumModel
