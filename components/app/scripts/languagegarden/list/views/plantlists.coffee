    'use strict'

    _ = require('underscore')
    $ = require('jquery')
    {PlantMetaCollection} = require('./../../common/models/plantlists')
    {BaseView} = require('./../../common/views/base')
    {template} = require('./../../common/templates')
    {stringifyToASCIIJSON} = require('./../../common/utils')

    req = require.context('./../../../../templates/', true, /^.*\.ejs$/);


    class PlantListView extends BaseView
        itemTemplate: template('./list/plant_or_activity.ejs')
        typeMap:
            'play-plant': 'play-plant'
            'nav-plant': 'nav-plant'
            'edit-plant': 'edit-plant'
            'play-activity-passive': 'play-activity-passive'

        initialize: (options) ->
            super
            @listenTo(@collection, 'reset:success', @onChange)

        remove: ->
            @$el.empty()
            @stopListening(@collection)
            super

        onChange: -> @render()

        render: ->
            super
            @updateList()

        updateList: ->
            plantList = _.filter(@collection.models, (elem) -> elem.id > 0)
            $container = @$el
            that = this

            if plantList.length > 0
                $container.empty()
                $ul = $('<ul>').appendTo($container)
                for elem in plantList
                    data = _.extend({}, elem.toJSON())
                    if data.data?
                        # convert to ASCII JSON
                        plantData = JSON.parse(data.data)
                        data.data = stringifyToASCIIJSON(plantData)
                    $li = $('<li>').appendTo($ul)
                    $li.html(@itemTemplate.render(data))
                    $li.find('a.nav-controller').click (e) ->
                        e.preventDefault()
                        $a = $(this)
                        navType = $a.attr('data-nav-type')
                        navInfo =
                            type: that.typeMap[navType]
                            plantId: $a.attr('data-nav-plant-id')
                            activityId: $a.attr('data-nav-activity-id')
                        that.trigger('navigate', that, navInfo)

            else
                $container.empty().text('No saved plant found!')


    module.exports =
        PlantListView: PlantListView
