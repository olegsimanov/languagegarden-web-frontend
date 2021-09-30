    'use strict'

    {MediumType} = require('./../constants')
    {Action} = require('./base')


    class StartUpdating extends Action

        id: 'start-text-updating'

        perform: =>
            textView = @canvasView.getSelectedMediaViews()[0]
            if textView.model.get('type') == MediumType.TEXT
                @canvasView.startTextEditing(textView)

            # false is important here. we do not want to create a snapshot
            # after performing this action
            false

        isAvailable: =>
            media = @canvasView.getSelectedMedia()
            if media.length == 1 and @canvasView.getSelectedElements().length == 0
                if media[0]?.get('type') == MediumType.TEXT
                    true
            false

    module.exports =
        StartUpdating: StartUpdating
