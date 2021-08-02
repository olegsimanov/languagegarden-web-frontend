    'use strict'

    {UnitAction} = require('./../../common/actions/base')


    class EditorAction extends UnitAction
        trackingChanges: true

        onPerformStart: ->
            super
            if @trackingChanges
                @model.stopTrackingChanges()

        onPerformEnd: ->
            if @trackingChanges
                @model.startTrackingChanges()
            super


    class ToolbarStateAction extends EditorAction
        state: null

        perform: -> @controller.setToolbarState(@state)

        isAvailable: -> true


    module.exports =
        Action: EditorAction
        EditorAction: EditorAction
        ToolbarStateAction: ToolbarStateAction
