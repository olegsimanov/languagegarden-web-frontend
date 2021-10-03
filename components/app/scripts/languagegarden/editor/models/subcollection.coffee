    'use strict'

    _ = require('underscore')


    SubCollectionPrototype =

        subCollectionConfig: []

        getSubCollectionNames: -> @_subCollectionNames
        getSubCollections: ->  @_subCollections

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

        subCollectionsToJSON: (data={}) ->
            for subCollectionName in @getSubCollectionNames()
                data[subCollectionName] = @[subCollectionName].toJSON()
            data

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
