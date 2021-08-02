    'use strict'

    {PlantChildModel, PlantChildCollection} = require('./base')


    class ActivityLink extends PlantChildModel


    class ActivityLinks extends PlantChildCollection
        model: ActivityLink
        objectIdPrefix: 'activityLink'

        getExistingObjectIds: ->
            @parentModel.collection.getExistingObjectIds()


    module.exports =
        ActivityLink: ActivityLink
        ActivityLinks: ActivityLinks
