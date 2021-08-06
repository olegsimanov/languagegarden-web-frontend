    'use strict'

    _ = require('underscore')
    Backbone = require('backbone')
    {VisibilityType} = require('./../constants')
    {extend, extendAll} = require('./../extend')
    {SubCollectionPrototype} = require('./subcollection')
    {getAttrsOpts} = require('./../utils')
    {EventForwardingPrototype} = require('./../events')


    class BaseModel extends Backbone.Model.extend(EventForwardingPrototype)

        setParentModel: (model) -> @parentModel = model

        getParentModel: -> @parentModel

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

        setDefaultValue: (attrName, value) ->
            @set(attrName, value) if not @has(attrName)

        deepClone: -> new @constructor(@toJSON())

        @extend: extend

        @extendAll: extendAll


    class BaseCollection extends Backbone.Collection

        modelFactoryFailureError = 'factory failure'

        setParentModel: (model) -> @parentModel = model

        getParentModel: -> @parentModel

        ###
        Partial function. for given attribute name returns function which
        finds the index of first model in collection which satisfies the
        condition model.get(attrName) == value. in other case, this generated
        function returns -1.
        ###
        findFirstIndexByAttribute: (attrName) ->
            (value) =>
                for i in [0...@length]
                    model = @models[i]
                    if model.get(attrName) == value
                        return i
                return -1

        ###
        Partial function. for given attribute name returns function which
        finds the first model in collection which satisfies the condition
        model.get(attrName) == value. In other case, this generated
        function returns null.
        ###
        findFirstByAttribute: (attrName) ->
            findIndex = @findFirstIndexByAttribute(attrName)
            (value) =>
                index = findIndex(value)
                if index >= 0 then @models[index] else null

        ###
        Partial function. for given attribute name returns function which
        finds the index of some model in collection which satisfies the
        condition model.get(attrName) == value. in other case, this generated
        function returns -1.
        ###
        findIndexByAttribute: (attrName) ->
            @findFirstIndexByAttribute(attrName)

        ###
        Partial function. for given attribute name returns function which
        finds some model in collection which satisfies the condition
        model.get(attrName) == value.In other case, this generated
        function returns null.
        ###
        findByAttribute: (attrName) ->
            @findFirstByAttribute(attrName)

        ###
        WARNING: overriding semi-documented Backbone.Collection method
        ###
        _prepareModel: (attrs, options) ->
            if @modelFactory?
                if attrs instanceof Backbone.Model
                    # do not overwrite model collection
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
                # use the default model preparation
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

        @extend: extend

        @extendAll: extendAll


    class PlantChildModel extends BaseModel

        initialize: (options) ->
            super
            @deletingInProgress = false
            if not @has('visibilityType')
                @set('visibilityType', VisibilityType.DEFAULT)

        setDeletingInProgress: -> @deletingInProgress = true

        isDeletingInProgress: -> @deletingInProgress

        clear: (options) ->
            result = super
            @deletingInProgress = false
            @trigger('clear', this)
            result


    class PlantChildCollection extends BaseCollection
        objectIdPrefix: 'object'

        initialize: (options) ->
            super
            @findByObjectId = @findByAttribute('objectId')
            @findIndexByObjectId = @findIndexByAttribute('objectId')

        getExistingObjectIds: ->
            if @parentModel.isRewindedAtEnd?
                if @parentModel.isRewindedAtEnd()
                    # using the standard method of getting objects is
                    # sufficient here
                    @parentModel.getObjectIds()
                else
                    # we need ALL objects, not only in given time point but
                    # also from the future (to avoid collision)
                    @parentModel.getHistoricalObjectIds()
            else
                @parentModel.getObjectIds()

        getUniqueObjectId: ->
            existingObjectIds = @getExistingObjectIds()

            # using object lookup instead of iterating on whole array
            testDict = {}
            for objectId in existingObjectIds
                testDict[objectId] = 1

            # not the most intelligent way, but should be sufficient when the
            # number of plant elements/ media will be small
            counter = 1
            while true
                newObjectId = "#{@objectIdPrefix}_#{counter}"
                if not testDict[newObjectId]?
                    break
                counter += 1
            newObjectId

        ###
        WARNING: overriding semi-documented Backbone.Collection method
        ###
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


    class PlantChildModelWithSubCollections extends BaseModelWithSubCollections

        initialize: (options) ->
            super
            @deletingInProgress = false
            if not @has('visibilityType')
                @set('visibilityType', VisibilityType.DEFAULT)

        setDeletingInProgress: -> @deletingInProgress = true

        isDeletingInProgress: -> @deletingInProgress

        clear: (options) ->
            result = super
            @deletingInProgress = false
            @trigger('clear', this)
            result


    module.exports =
        BaseModel: BaseModel
        BaseCollection: BaseCollection
        PlantChildModel: PlantChildModel
        PlantChildCollection: PlantChildCollection
        BaseModelWithSubCollections: BaseModelWithSubCollections
        PlantChildModelWithSubCollections: PlantChildModelWithSubCollections
