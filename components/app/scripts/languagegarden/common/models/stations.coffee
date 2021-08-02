    'use strict'

    {PlantChildModelWithSubCollections, PlantChildCollection} = require('./base')
    {ActivityLinks} = require('./activitylinks')


    class Station extends PlantChildModelWithSubCollections

        subCollectionConfig: [
            name: 'activityLinks'
            collectionClass: ActivityLinks
        ]

        onSubCollectionChange: (sender, ctx) ->
            @trigger('childchange', sender, this, ctx)


    class Stations extends PlantChildCollection
        model: Station
        objectIdPrefix: 'station'


    module.exports =
        Station: Station
        Stations: Stations
