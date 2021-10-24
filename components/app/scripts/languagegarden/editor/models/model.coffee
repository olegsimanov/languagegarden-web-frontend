    'use strict'

    _                           = require('underscore')
    {BaseModel}                 = require('./base')
    {BaseCollection}            = require('./collection')
    {VisibilityType}            = require('./../constants')

    class PlantChildModel extends BaseModel

        initialize: (options) ->
            super
            if not @has('visibilityType')
                @set('visibilityType', VisibilityType.DEFAULT)

        clear: (options) ->
            result = super
            @trigger('clear', this)
            result

    class PlantChildCollection extends BaseCollection

        objectIdPrefix: 'object'


    module.exports =
        PlantChildModel:                    PlantChildModel
        PlantChildCollection:               PlantChildCollection
