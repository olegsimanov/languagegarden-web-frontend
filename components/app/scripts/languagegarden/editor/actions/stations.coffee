    'use strict'

    {Action} = require('./base')


    class StationAction extends Action
        trackingChanges: false

        initialize: (options) ->
            super

        remove: ->
            super


    class DeleteStation extends StationAction
        id: 'delete-station'

        perform: ->
            @timeline.deleteCurrentStation()
            @timeline.saveModel()

        isAvailable: -> @model.stations.length > 0


    class DeleteLastStation extends DeleteStation
        id: 'delete-last-station'

        isAvailable: -> super and @timeline.isRewindedAtEnd()


    module.exports =
        DeleteStation: DeleteStation
        DeleteLastStation: DeleteLastStation
