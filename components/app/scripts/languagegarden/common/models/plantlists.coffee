    'use strict'

    _ = require('underscore')
    settings = require('./../../settings')
    config = require('./../../config')
    {BaseModel} = require('./base')
    {PaginatedCollection} = require('./pagination')


    class PlantMeta extends BaseModel

        idAttribute: 'id'


    class PlantMetaCollection extends PaginatedCollection
        model: PlantMeta
        urlRoot: -> config.getUrlRoot(settings.apiResourceNames.lessons)

        parse: (response, options) ->
            if _.isString(response)
                # response was not parsed
                data = JSON.parse(response)
            else
                data = response

            if _.isObject(data) and not _.isArray(data)
                if data.objects? and _.isArray(data.objects)
                    # the plant list is wrapped in 'objects' attribute
                    data.objects
                else if data.results? and _.isArray(data.results)
                    # the plant list is wrapped in 'objects' attribute
                    data.results
                else
                    []
            else
                data


    module.exports =
        PlantMetaCollection: PlantMetaCollection
