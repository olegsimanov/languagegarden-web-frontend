    'use strict'

    _ = require('underscore')
    $ = require('jquery')
    require('jquery.cookie')
    settings = require('./../../settings')
    config = require('./../../config')
    {Point} = require('./../../math/points')
    {pathJoin} = require('./../utils')
    {PlantElements} = require('./elements')
    {PlantMedia} = require('./media')
    {BaseModelWithSubCollections} = require('./base')
    {MediumType} = require('./../constants')
    {UnitDataCache} = require('../datacache')
#    require('backbone.localStorage')

#    Backbone.sync = (method, model, options) ->
#        console.log('calling: (' + method + ', ' + model + ', ' + options)
#        syncDfd = Backbone.$.Deferred()
#        syncDfd.resolve()

    # This is based on IPad I resolution
    SIDEBAR_WIDTH = 120
    DEFAULT_CANVAS_WIDTH = 1004 - SIDEBAR_WIDTH
    DEFAULT_CANVAS_HEIGHT = 462


    wrapError = (model, options) ->
        error = options.error
        options.error = (resp) ->
            error?(model, resp, options)
            model.trigger('error', model, resp, options)


    class UnitState extends BaseModelWithSubCollections
        subCollectionConfig: [
            name: 'elements'
            collectionClass: PlantElements
        ,
            name: 'media'
            collectionClass: PlantMedia
        ]

        # add childchange to support nesting in stations collection
        forwardedEventNames: [
            'childchange',
        ].concat(BaseModelWithSubCollections::forwardedEventNames)

        initialize: (options) ->
            super
            @setDefaultAttributes()

        setDefaultAttributes: ->
            @setDefaultValue('bgColor', '#FFFFFF')
            if not (MediumType.TEXT_TO_PLANT in @media.pluck('type'))
                @media.add
                    type: MediumType.TEXT_TO_PLANT
                    textElements: []

        get: (attr) ->
            if attr in @getSubCollectionNames()
                @[attr].toJSON()
            else if attr == 'inPlantToTextMode'
                @media.any((medium) -> medium.get('inPlantToTextMode'))
            else
                super

        stopTrackingChanges: -> @trigger('trackchanges', this, false)

        startTrackingChanges: -> @trigger('trackchanges', this, true)

        addElement: (model, options) -> @elements.add(model, options)

        removeElement: (model, options) -> @elements.remove(model, options)

        addMedium: (model, options) -> @media.add(model, options)

        removeMedium: (model, options) -> @media.remove(model, options)

        onSubCollectionChange: (sender, ctx) ->
            super
            @trigger('childchange', sender, this, ctx)


    class UnitData extends BaseModelWithSubCollections
        subCollectionConfig: [
            name: 'initialState'
            modelClass: UnitState
        ]

        # add childchange to support nesting in stations collection
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

        validate: (attrs, options) ->
            if not (attrs.textDirection in ['ltr', 'rtl'])
                return 'invalid textDirection'
            return

        get: (attr) ->
            if attr in @getSubCollectionNames()
                @[attr].toJSON()
            else
                super

        toJSON: (options) ->
            data = super
            if options?.unparse
                # we are passing unparse option in the sync
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

        getCachePayload: (id) -> null

        sync: (method, model, options) ->
            options ?= {}
            if method == 'read' and options.success? and @has('id')
                # special case for fetching lesson/activity - trying to find
                # the payload in cache
                result = @getCachePayload(@get('id'))
                if result?
                    # success callback was constructed in Backbone.Model::fetch
                    # so we use it to update the model
                    setTimeout((-> options.success(result)), 0)
                    # TODO: mock XHR object which is returned by sync
                    return

            options.unparse = true

#            if method != 'read'
#                originalBeforeSend = options.beforeSend
#                options.beforeSend = (xhr) ->
#                    csrftoken = $.cookie('csrftoken')
#                    xhr.setRequestHeader('X-CSRFToken', csrftoken);
#                    originalBeforeSend?(xhr)

            super

        deepClone: (constructor) ->
            constructor ?= @constructor
            modelCopy = new constructor(@toJSON())
            modelCopy

    class LessonData extends UnitData
#        localStorage: new Backbone.LocalStorage("LessonData")
        urlRoot: -> config.getUrlRoot(settings.apiResourceNames.lessons)
        forwardedAttrsMap: _.extend({}, UnitData::forwardedAttrsMap,
            'categories': 'categories'
            'levels': 'levels'
        )

        setDefaultAttributes: ->
            super
            @setDefaultValue('categories', [])
            @setDefaultValue('levels', [])

        getCachePayload: (id) ->
            cache = UnitDataCache.getInstance()
            cache.getLessonPayload(id)

    module.exports =
        UnitState: UnitState
        LessonData: LessonData
        SIDEBAR_WIDTH: SIDEBAR_WIDTH