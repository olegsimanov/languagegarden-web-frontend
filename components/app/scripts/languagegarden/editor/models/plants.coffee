    'use strict'

    _ = require('underscore')
    $ = require('jquery')

    {PlantElements}                 = require('./elements')
    {PlantMedia}                    = require('./media')
    {BaseModelWithSubCollections}   = require('./base')

    {pathJoin}                      = require('./../utils')
    {MediumType}                    = require('./../constants')
    {Point}                         = require('./../math/points')

    settings                        = require('./../../settings')
    config                          = require('./../../config')

    DEFAULT_CANVAS_WIDTH = 1000
    DEFAULT_CANVAS_HEIGHT = 460

    class UnitState extends BaseModelWithSubCollections

        subCollectionConfig: [
            name: 'elements'
            collectionClass: PlantElements
        ,
            name: 'media'
            collectionClass: PlantMedia
        ]

        forwardedEventNames: ['childchange',].concat(BaseModelWithSubCollections::forwardedEventNames)

        initialize: (options) ->
            super
            @setDefaultAttributes()

        setDefaultAttributes: ->
            @setDefaultValue('bgColor', '#FFFFFF')
            if not (MediumType.TEXT_TO_CANVAS in @media.pluck('type'))
                @media.add
                    type: MediumType.TEXT_TO_CANVAS
                    textElements: []

        get: (attr) ->
            if attr in @getSubCollectionNames()
                @[attr].toJSON()
            else if attr == 'inPlantToTextMode'
                @media.any((medium) -> medium.get('inPlantToTextMode'))
            else
                super

        stopTrackingChanges:    -> @trigger('trackchanges', this, false)
        startTrackingChanges:   -> @trigger('trackchanges', this, true)

        addElement: (model, options)    -> @elements.add(model, options)
        removeElement: (model, options) -> @elements.remove(model, options)

        removeMedium: (model, options) -> @media.remove(model, options)

        onSubCollectionChange: (sender, ctx) ->
            super
            @trigger('childchange', sender, this, ctx)


    class UnitData extends BaseModelWithSubCollections
        subCollectionConfig: [
            name: 'initialState'
            modelClass: UnitState
        ]

        forwardedEventNames: [
            'childchange',
        ].concat(BaseModelWithSubCollections::forwardedEventNames)

        forwardedAttrsMap:
            'id': 'id'
            'description': 'description'
            'color_palette': 'colorPalette'
            'active': 'public'
        plantDataAttrName: 'data'

        initialize: (options) ->
            super
            @setDefaultAttributes()

        setDefaultAttributes: ->
            @setDefaultValue('description', '')
            @setDefaultValue('language', 'English')
            @setDefaultValue('colorPalette', 'default')
            @setDefaultValue('public', true)
            @setDefaultValue('version', '0.7')
            @setDefaultValue('canvasWidth', DEFAULT_CANVAS_WIDTH)
            @setDefaultValue('canvasHeight', DEFAULT_CANVAS_HEIGHT)
            @setDefaultValue('textDirection', 'ltr')

        get: (attr) ->
            if attr in @getSubCollectionNames()
                @[attr].toJSON()
            else
                super

        toJSON: (options) ->
            data = super
            if options?.unparse
                @unparse(data)
            else
                data

        parse: (response, options) ->
            data = JSON.parse(response[@plantDataAttrName])
            if data
                for name, forwardName of @forwardedAttrsMap
                    data?[forwardName] = response?[name]
            data

        unparse: (data) ->
            response = {}
            data = _.clone(data)
            for name, forwardName of @forwardedAttrsMap
                response[name] = data[forwardName]
            delete data[@idAttribute]
            response[@plantDataAttrName] = JSON.stringify(data)
            response

        url: ->
            id = @get(@idAttribute)
            urlRoot = _.result(this, 'urlRoot')

            if id?
                urlPrefix = pathJoin(urlRoot, encodeURIComponent(id))
            else
                urlPrefix = urlRoot
            url = pathJoin(urlPrefix, '/')
            url

        sync: (method, model, options) ->
            console.log("UnitData.sync() called")
            options.success({})

        deepClone: (constructor) ->
            constructor ?= @constructor
            modelCopy = new constructor(@toJSON())
            modelCopy

    class LessonData extends UnitData
        urlRoot: -> config.getUrlRoot(settings.apiResourceNames.lessons)
        forwardedAttrsMap: _.extend({}, UnitData::forwardedAttrsMap,
            'categories': 'categories'
            'levels': 'levels'
        )

        setDefaultAttributes: ->
            super
            @setDefaultValue('categories', [])
            @setDefaultValue('levels', [])

    module.exports =
        UnitState:      UnitState
        LessonData:     LessonData
