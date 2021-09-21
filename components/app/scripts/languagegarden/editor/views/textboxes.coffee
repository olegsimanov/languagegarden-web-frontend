    'use strict'

    _ = require('underscore')
    {MediumType} = require('./../../common/constants')
    {TextBoxView} = require('./../../common/views/textboxes')
    {
        EditorTextToPlantView
        MarkableTextToPlantView
    } = require('./media/text_to_plant')
    {EditorPlantToTextNote} = require('./media/planttotext')
    {EditorInstructionsView} = require('./media/instructions')
    {EditorMode} = require('./../constants')


    class EditorTextBoxView extends TextBoxView

        initialize: (options) ->
            super
            @mode = EditorMode.MOVE

        ###
        Adding/Removing/Resetting media helpers
        ###

        getMediumViewClass: (model) ->
            switch model.get('type')
                when MediumType.TEXT_TO_PLANT
                    EditorTextToPlantView
                else
                    super

        selectionBBoxChange: ->

        toggleModeClass: (mode=@mode, flag=true) ->
            @$el.toggleClass("#{mode.replace(/\s/g,'-')}-mode", flag)

        setMode: (mode) ->
            oldMode = @mode
            if oldMode == mode
                return
            @toggleModeClass(@mode, false)
            @mode = mode
            @toggleModeClass(@mode, true)

        setDefaultMode: ->

        # plant-to-text note
        startPlantToTextMode: (plantToTextModel) ->
            @activePlantToTextObjectId = plantToTextModel.get('objectId')
            @setMode(EditorMode.PLANT_TO_TEXT)

        finishPlantToTextMode: ->
            delete @activePlantToTextObjectId
            @setDefaultMode()

        getActivePlantToTextView: ->
            if not @activePlantToTextObjectId?
                return null
            mediaViews = @getMediaViews()
            for view in mediaViews
                if view.model.get('objectId') == @activePlantToTextObjectId
                    return view
            return null

        unsetActivePlantToTextView: ->
            delete @activePlantToTextObjectId


    module.exports =
        EditorTextBoxView: EditorTextBoxView
