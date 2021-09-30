    'use strict'

    _ = require('underscore')


    SubCollectionPrototype =

        subCollectionConfig: [
        #     name: 'modelAttribute'
        #     collectionClass: CollectionClass
        # ,
        ]

        getSubCollectionNames: -> @_subCollectionNames
        getSubCollections: ->  @_subCollections

        ###Initialize all subcollections according to subCollectionConfig.
        Collections are required on first this.set call, thus thus method must
        be called earlier.
        ###
        createSubCollections: ->
            for subColCfg in @subCollectionConfig
                if not @[subColCfg.name]?
                    constructor = (subColCfg.collectionConstructor or
                                   subColCfg.modelConstructor)
                    if not constructor
                        cls = subColCfg.collectionClass or subColCfg.modelClass
                        constructor = (data, options) -> new cls(data, options)
                    subCollection = constructor()
                    subCollection.setParentModel(this)
                    @[subColCfg.name] = subCollection

            @_subCollectionNames ?= _.pluck(@subCollectionConfig, 'name')
            @_subCollections ?= (@[name] for name in @getSubCollectionNames())

        removeSubCollections: ->
            for subCollection in @getSubCollections()
                @stopListening(subCollection)
                subCollection.setParentModel(null)
            delete @_subCollections
            delete @_subCollectionNames

        ###Additional collection setup, requires collections to already exist
        on the model.
        ###
        initializeSubCollections: ->
            for subCollection in @getSubCollections()
                @initializeSubCollection(subCollection)

        forwardedEventNames: ['addall', 'removeall', 'reset', 'change']

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

        ###Returns dictionary of subcollection's toJSON results.
        @param data If provided, will be used instead of an empty object.

        ###
        subCollectionsToJSON: (data={}) ->
            for subCollectionName in @getSubCollectionNames()
                data[subCollectionName] = @[subCollectionName].toJSON()
            data

        ###Retrieves objectIds of any model in subcollections.
        Searches for getObjectIds methods on inspected nested objects which are
        used as an override.
        ###
        getObjectIds: ->
            objectIds = []
            for subCollection in @getSubCollections()
                # try in the collection
                if subCollection.getObjectIds?
                    objIds = subCollection.getObjectIds()
                    objectIds.push(objIds) if objIds?
                else
                    for model in subCollection.models
                        # try in the model
                        if model.getObjectIds?
                            objIds = model.getObjectIds?()
                            objectIds.push(objIds) if objIds?
                        else
                            # access model attribute directly
                            objId = model.get('objectId')
                            objectIds.push(objId) if objId?
            _.flatten(objectIds)

        ###Call from your set method to allow settings of collection items.###
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

        clearSubCollections: (options={}) ->
            for subCollection in @getSubCollections()
                subCollection?.reset([], options)

    module.exports =
        SubCollectionPrototype: SubCollectionPrototype
