    'use strict'

    _ = require('underscore')
    {
        PlantChildModel,
        PlantChildCollection
    }                   = require('./base')
    {deepCopy}          = require('./../utils')
    {MediumType}        = require('./../constants')

    {Point}             = require('./../math/points')


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

    class PlantMedia extends PlantChildCollection
        modelFactory:   PlantMedium.fromJSON
        objectIdPrefix: 'medium'

    module.exports =
        PlantMedium:    PlantMedium
        PlantMedia:     PlantMedia
