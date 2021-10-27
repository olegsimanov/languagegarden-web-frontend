    'use strict'

    _                           = require('underscore')
    Backbone                    = require('backbone')
    {getAttrsOpts}              = require('./../utils')
    {ICanForwardEvents}         = require('./../events')


    class BaseModel extends Backbone.Model.extend(ICanForwardEvents)

        setParentModel: (model)             -> @parentModel = model
        getParentModel:                     -> @parentModel

        setDefaultValue: (attrName, value)  -> @set(attrName, value) if not @has(attrName)

        deepClone:                          -> new @constructor(@toJSON())


    class BaseModelWithSubCollections extends BaseModel

        @subCollectionConfig:    []
        @_subCollections:       undefined
        @_subCollectionNames:   undefined

        @forwardedEventNames:   ['addall', 'removeall', 'reset', 'change']

        getSubCollections:      -> @_subCollections
        getSubCollectionNames:  -> @_subCollectionNames

        constructor: ->
            @createSubCollections()
            super

        createSubCollections: ->
            for subColCfg in @subCollectionConfig
                if not @[subColCfg.name]?
                    constructor = (subColCfg.collectionConstructor or subColCfg.modelConstructor)
                    if not constructor
                        cls         = subColCfg.collectionClass or subColCfg.modelClass
                        constructor = (data, options) -> new cls(data, options)
                    subCollection = constructor()
                    subCollection.setParentModel(this)
                    @[subColCfg.name] = subCollection

            @_subCollectionNames    ?= _.pluck(@subCollectionConfig, 'name')
            @_subCollections        ?= (@[name] for name in @getSubCollectionNames())



        initialize: ->
            super
            @initializeSubCollections()

        initializeSubCollections: ->
            for subCollection in @getSubCollections()
                @initializeSubCollection(subCollection)

        initializeSubCollection: (subCollection) ->
            for eventName in @forwardedEventNames
                @listenTo(subCollection, eventName, @onSubCollectionChange)

        onSubCollectionChange: (arg1, arg2)->
            for i in [0...@subCollectionConfig.length]
                if @_subCollections[i] in [arg1 ,arg2]
                    cfg = @subCollectionConfig[i]
                    @trigger("change:#{cfg.name}", this, @get(cfg.name))
                    break
            # TODO: add change event?
            return



        remove: -> @removeSubCollections()

        removeSubCollections: ->
            for subCollection in @getSubCollections()
                @stopListening(subCollection)
                subCollection.setParentModel(null)
            delete @_subCollections
            delete @_subCollectionNames




        toJSON: => @subCollectionsToJSON(super)

        subCollectionsToJSON: (data={}) ->
            for subCollectionName in @getSubCollectionNames()
                data[subCollectionName] = @[subCollectionName].toJSON()
            data




        set: (key, val, options) =>
            [attrs, options] = getAttrsOpts(key, val, options)

            @preSet(attrs, options)
            result = super(attrs, options)
            @postSet(attrs, options)

            result

        preSet: (attrs, options) => @subCollectionSet(attrs, silent: options?.silent or false)

        subCollectionSet: (attrs, options) ->
            for subCollectionName in @getSubCollectionNames()
                if attrs[subCollectionName]?
                    #TODO: use less hackish way to update sub model/collection
                    if @[subCollectionName].reset?
                        @[subCollectionName].reset(
                            attrs[subCollectionName], options
                        )
                    else
                        @[subCollectionName].set(
                            attrs[subCollectionName], options
                        )
                    delete attrs[subCollectionName]


        postSet: (attrs, options) =>



    module.exports =
        BaseModel:                          BaseModel
        BaseModelWithSubCollections:        BaseModelWithSubCollections
