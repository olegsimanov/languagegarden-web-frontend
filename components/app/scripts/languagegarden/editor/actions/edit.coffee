    'use strict'

    {Action} = require('./base')


    class StartUpdating extends Action
        id: 'start-updating'
        trackingChanges: false

        perform: ->
            selectedElement = @parentView.getSelectedElements()[0]
            @parentView.startUpdating(selectedElement)
            # false is important here. we do not want to create a snapshot
            # after performing this action
            false

        isAvailable: ->
            (@parentView.getSelectedElements().length == 1 and
             @parentView.getSelectedViews().length == 1)


    class EditElementHRef extends Action
        id: 'edit-element-href'

        perform: ->
            {
                ElementEditHRefView
            } = require('../views/mediamodals/medialibrary/plants')
            selectedElement = @parentView.getSelectedElements()[0]
            editHRefView = new ElementEditHRefView
                editor: @parentView
                model: selectedElement

            editHRefView.show()
            false

        isAvailable: ->
            (@parentView.getSelectedElements().length == 1 and
             @parentView.getSelectedViews().length == 1)


    module.exports =
        StartUpdating: StartUpdating
        EditElementHRef: EditElementHRef
