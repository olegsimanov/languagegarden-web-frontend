    'use strict'

    {Action} = require('./base')


    class StartUpdating extends Action

        id:                 'start-updating'
        trackingChanges:    false

        perform: ->
            selectedElement = @parentView.getSelectedElements()[0]
            @parentView.startUpdating(selectedElement)
            false

        isAvailable: -> (@parentView.getSelectedElements().length == 1 and @parentView.getSelectedViews().length == 1)



    module.exports =
        StartUpdating: StartUpdating
