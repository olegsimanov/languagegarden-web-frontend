    'use strict'

    {Action} = require('./base')


    class DeleteAction extends Action

        id:             'delete'
        fadeOutDelay:   250

        initialize: (options) ->
            super
            @fadeOutDelay = options?.fadeOutDelay or @fadeOutDelay

        perform: ->

            elementViews = @canvasView.getSelectedElementViews()
            mediaViews = @canvasView.getSelectedMediaViews()

            if elementViews.length == 0 and mediaViews.length == 1
                if mediaViews[0]?.isInEditMode
                    return

            for view in elementViews
                view.fadeoutOnRemove = true
                @model.removeElement(view.model)

            for view in mediaViews
                view.fadeoutOnRemove = true
                @model.removeMedium(view.model)
            true

        isAvailable: -> (@canvasView.getSelectedElements().length > 0 or @canvasView.getSelectedMedia().length > 0)


    module.exports =
        DeleteAction: DeleteAction

