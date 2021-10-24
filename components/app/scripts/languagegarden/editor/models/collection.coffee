    'use strict'

    _                           = require('underscore')
    Backbone                    = require('backbone')
    {VisibilityType}            = require('./../constants')

    class BaseCollection extends Backbone.Collection

        setParentModel: (model)     -> @parentModel = model
        getParentModel:             -> @parentModel

        deepClone:                  -> new @constructor(@toJSON())

        set: (models, options) ->
            if not _.isArray(models)
                models = if models? then [models] else []

            result = super
            if not options?.silent and models.length > 0
                if options?.add
                    @trigger('addall', this)
                if options?.remove
                    @trigger('removeall', this)
            result

        remove: (models, options) ->
            if not _.isArray(models)
                models = if models? then [models] else []

            result = super
            if not options?.silent and models.length > 0
                @trigger('removeall', this)

            result

    module.exports =
        BaseCollection:                     BaseCollection
