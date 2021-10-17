    'use strict'

    _                           = require('underscore')
    Backbone                    = require('backbone')
    {SubCollectionPrototype}    = require('./subcollection')
    {VisibilityType}            = require('./../constants')
    {getAttrsOpts}              = require('./../utils')
    {ICanForwardEvents}          = require('./../events')

    class BaseModel extends Backbone.Model.extend(ICanForwardEvents)

        setParentModel: (model) -> @parentModel = model
        getParentModel:         -> @parentModel

        getFastAttributeSetter: (attr) ->
            (value) =>
                @attributes[attr] = value
                @changed[attr] = value

        getFastAttributeLevel1Setter: (attr, level1) ->
            (value) =>
                @attributes[attr][level1] = value
                @changed[attr] = @attributes[attr]

        getFastAttributeLevel2Setter: (attr, level1, level2) ->
            (value) =>
                @attributes[attr][level1][level2] = value
                @changed[attr] = @attributes[attr]

        setDefaultValue: (attrName, value) -> @set(attrName, value) if not @has(attrName)

        deepClone: -> new @constructor(@toJSON())


    class BaseCollection extends Backbone.Collection

        modelFactoryFailureError = 'factory failure'

        setParentModel: (model)     -> @parentModel = model
        getParentModel:             -> @parentModel

        findFirstIndexByAttribute: (attrName) ->
            (value) =>
                for i in [0...@length]
                    model = @models[i]
                    if model.get(attrName) == value
                        return i
                return -1

        findFirstByAttribute: (attrName) ->
            findIndex = @findFirstIndexByAttribute(attrName)
            (value) =>
                index = findIndex(value)
                if index >= 0 then @models[index] else null

        findIndexByAttribute: (attrName) ->
            @findFirstIndexByAttribute(attrName)

        findByAttribute: (attrName) ->
            @findFirstByAttribute(attrName)

        _prepareModel: (attrs, options) ->
            if @modelFactory?
                if attrs instanceof Backbone.Model
                    attrs.collection ?= this
                    return attrs
                options = if options? then _.clone(options) else {}
                options.collection = this
                model = @modelFactory(attrs, options)
                if not model?
                   @trigger('invalid', this, modelFactoryFailureError, options)
                   false
                else if model.validationError
                   @trigger('invalid', this, model.validationError, options)
                   false
                else
                    model
            else
                super

        deepClone: -> new @constructor(@toJSON())

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


    class PlantChildModel extends BaseModel

        initialize: (options) ->
            super
            if not @has('visibilityType')
                @set('visibilityType', VisibilityType.DEFAULT)

        clear: (options) ->
            result = super
            @deletingInProgress = false
            @trigger('clear', this)
            result


    class PlantChildCollection extends BaseCollection
        objectIdPrefix: 'object'

        initialize: (options) ->
            super
            @findByObjectId         = @findByAttribute('objectId')
            @findIndexByObjectId    = @findIndexByAttribute('objectId')

        getExistingObjectIds: ->
            if @parentModel.isRewindedAtEnd?
                if @parentModel.isRewindedAtEnd()
                    @parentModel.getObjectIds()
                else
                    @parentModel.getHistoricalObjectIds()
            else
                @parentModel.getObjectIds()

        getUniqueObjectId: ->
            existingObjectIds = @getExistingObjectIds()

            testDict = {}
            for objectId in existingObjectIds
                testDict[objectId] = 1

            counter = 1
            while true
                newObjectId = "#{@objectIdPrefix}_#{counter}"
                if not testDict[newObjectId]?
                    break
                counter += 1
            newObjectId

        _prepareModel: (attrs, options) ->
            model = super

            if not model.has('objectId')
                model.set('objectId', @getUniqueObjectId(), silent: true)
            model


    class BaseModelWithSubCollections extends BaseModel.extend(SubCollectionPrototype)

        constructor: ->
            @createSubCollections()
            super

        initialize: ->
            super
            @initializeSubCollections()

        remove: ->
            @removeSubCollections()

        set: (key, val, options) =>
            [attrs, options] = getAttrsOpts(key, val, options)

            @preSet(attrs, options)
            result = super(attrs, options)
            @postSet(attrs, options)

            result

        preSet: (attrs, options) =>
            @subCollectionSet(attrs, silent: options?.silent or false)

        postSet: (attrs, options) =>

        toJSON: => @subCollectionsToJSON(super)

    module.exports =
        BaseModel:                          BaseModel
        BaseCollection:                     BaseCollection
        PlantChildModel:                    PlantChildModel
        PlantChildCollection:               PlantChildCollection
        BaseModelWithSubCollections:        BaseModelWithSubCollections
