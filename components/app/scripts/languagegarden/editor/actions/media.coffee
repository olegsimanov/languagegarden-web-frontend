    'use strict'

    _ = require('underscore')
    {Point} = require('./../../math/points')
    {PlantMedium} = require('./../../common/models/media')
    {Action} = require('./base')
    {MediumType, PlacementType} = require('./../../common/constants')

    mediaModals = require('./../views/mediamodals/medialibrary/media')
    plantsModals = require('./../views/mediamodals/medialibrary/plants')


    class MediumAction extends Action
        mediumType: null

        getMediaCollection: -> @model.media


    class AddMedium extends MediumAction

        initialize: =>
            super
            @point = new Point()

        setPoint: (point) =>
            @point = point

        getModalViewClass: =>

        getModelExtendedOptions: => {}

        perform: =>
            # circular dependency
            viewClass = @getModalViewClass()
            options =
                type: @mediumType
                centerPoint: @point
            options = _.extend(options, @getModelExtendedOptions())
            medium = PlantMedium.fromJSON(options)

            addMediumView = new viewClass
                canvasView: @canvasView
                timeline: @timeline
                model: medium
                insertCollection: @getMediaCollection()

            addMediumView.show()
            false

        isAvailable: => true

    class EditMedium extends MediumAction
        saveAfterSuccess: false

        getModalViewClass: =>

        getMediumToEdit: =>
            @canvasView.enterEditMedium or @canvasView.getSelectedMedia()[0]

        perform: =>
            # circular dependency
            viewClass = @getModalViewClass()
            medium = @getMediumToEdit()
            editMediumView = new viewClass
                canvasView: @canvasView
                timeline: @timeline
                model: medium
                saveAfterSuccess: @saveAfterSuccess

            @canvasView.enterEditMedium = null

            editMediumView.show()
            false

        isAvailable: =>
            selectedMedia = @canvasView.getSelectedMedia()
            numOfMediaSelections = selectedMedia.length
            numOfSelections = @canvasView.getSelectedViews().length

            if numOfMediaSelections == 1 and numOfSelections == 1
                selectedMedia[0].get('type') == @mediumType
            else
                false


    class AddOrEditHiddenMedium extends MediumAction

        initializeListeners: ->
            mediaCollection = @getMediaCollection()
            @listenTo(mediaCollection, 'addall', @triggerToggledChange)
            @listenTo(mediaCollection, 'change', @triggerToggledChange)

        getModalViewClass: ->

        getEditModalViewClass: -> @getModalViewClass()

        getAddModalViewClass: -> @getModalViewClass()

        getModelExtendedOptions: -> {}

        getMediumToEdit: ->
            media = _.filter(
                _.pluck(@canvasView.getMediaViews(@mediumType), 'model'),
                (m) -> m.get('placementType') == PlacementType.HIDDEN,
            )
            if media.length > 0
                media[media.length - 1]
            else
                null

        perform: =>
            medium = @getMediumToEdit()

            if medium?
                # circular dependency
                viewClass = @getEditModalViewClass()

            else
                # circular dependency
                viewClass = @getAddModalViewClass()
                options =
                    type: @mediumType
                    centerPoint: [0, 0]
                    placementType: PlacementType.HIDDEN
                options = _.extend(options, @getModelExtendedOptions())
                medium = PlantMedium.fromJSON(options)

            mediumView = new viewClass
                controller: @controller
                editor: @canvasView
                canvasView: @canvasView
                timeline: @timeline
                model: medium
                insertCollection: @getMediaCollection()

            mediumView.show()
            false

        isToggled: -> @getMediumToEdit()?

        isAvailable: => true


    class SoundAction extends Action
        trackingChanges: false

        isOneSoundSelected: =>
            selectedMedia = @canvasView.getSelectedMedia()
            numOfMediaSelections = selectedMedia.length
            numOfSelections = @canvasView.getSelectedViews().length

            if numOfMediaSelections == 1 and numOfSelections == 1
                selectedMedia[0].get('type') == MediumType.SOUND
            else
                false

        getPlayer: => @canvasView.getSelectedMediaViews()[0].getPlayer()


    class AddNoteBase extends Action
        id: 'action-id-missing'
        mediumType: null
        text: ''

        setPoint: (point) =>
            @point = point

        perform: =>
            @canvasView.model.addMedium
                text: @text
                type: @mediumType
                centerPoint: @point
                textSize: @canvasView.settings.get('textSize')
            true

        isAvailable: => true


    class AddImage extends AddMedium
        id: 'add-image'
        mediumType: MediumType.IMAGE

        getModalViewClass: => mediaModals.ImageMediaLibraryView

        getModelExtendedOptions: =>
            url: ''


    class AddSound extends AddMedium
        id: 'add-sound'
        mediumType: MediumType.SOUND

        getModalViewClass: => mediaModals.SoundMediaLibraryView

        getModelExtendedOptions: =>
            url: ''
            urls: []


    class AddPlantLink extends AddMedium
        id: 'add-plant-link'
        mediumType: MediumType.PLANT_LINK

        getModalViewClass: => plantsModals.PlantLinkLibraryView

        getModelExtendedOptions: =>
            name: 'Unnamed Link'
            href: ''


    class AddText extends Action
        id: 'add-text'

        setPoint: (point) =>
            @point = point

        perform: =>
            @canvasView.model.addMedium
                text: ''
                type: MediumType.TEXT
                centerPoint: @point
            true

        isAvailable: => true


    class AddNote extends AddNoteBase
        id: 'add-note'
        mediumType: MediumType.DICTIONARY_NOTE


    class AddTextToPlantNote extends AddNoteBase
        id: 'add-text-to-plant-note'
        mediumType: MediumType.TEXT_TO_PLANT_NOTE


    class AddPlantToTextNote extends AddNoteBase
        id: 'add-plant-to-text-note'
        mediumType: MediumType.PLANT_TO_TEXT_NOTE


    class EditImage extends EditMedium
        id: 'edit-image'
        mediumType: MediumType.IMAGE

        getModalViewClass: => mediaModals.ImageMediaLibraryView


    class EditTitleImage extends EditImage
        id: 'edit-title-image'
        saveAfterSuccess: true
        trackingChanges: false

        getMediumToEdit: -> @dataModel.titleImage

        isAvailable: -> true


    class EditSound extends EditMedium
        id: 'edit-sound'
        mediumType: MediumType.SOUND

        getModalViewClass: => mediaModals.SoundMediaLibraryView


    class EditPlantLink extends EditMedium
        id: 'edit-plant-link'
        mediumType: MediumType.PLANT_LINK

        getModalViewClass: => plantsModals.PlantLinkLibraryEditView


    class AddOrEditHiddenImage extends AddOrEditHiddenMedium
        id: 'add-or-edit-image'
        mediumType: MediumType.IMAGE

        getModalViewClass: => mediaModals.ImageMediaLibraryView


    class AddOrEditHiddenSound extends AddOrEditHiddenMedium
        id: 'add-or-edit-sound'
        mediumType: MediumType.SOUND

        getModalViewClass: => mediaModals.SoundMediaLibraryView


    class PlaySound extends SoundAction

        id: 'play-sound'

        perform: => @getPlayer().play()

        isAvailable: =>
            if not @isOneSoundSelected()
                false
            else
                @getPlayer().isPaused()


    class PauseSound extends SoundAction

        id: 'pause-sound'

        perform: => @getPlayer().pause()

        isAvailable: =>
            if not @isOneSoundSelected()
                false
            else
                @getPlayer().isPlaying()


    class StopSound extends SoundAction

        id: 'stop-sound'

        perform: => @getPlayer().stop()

        isAvailable: =>
            if not @isOneSoundSelected()
                false
            else
                true


    module.exports =
        AddImage: AddImage
        AddSound: AddSound
        AddPlantLink: AddPlantLink
        AddText: AddText
        AddNote: AddNote
        AddTextToPlantNote: AddTextToPlantNote
        AddPlantToTextNote: AddPlantToTextNote
        EditImage: EditImage
        EditTitleImage: EditTitleImage
        EditSound: EditSound
        EditPlantLink: EditPlantLink
        AddOrEditHiddenImage: AddOrEditHiddenImage
        AddOrEditHiddenSound: AddOrEditHiddenSound
        PlaySound: PlaySound
        PauseSound: PauseSound
        StopSound: StopSound
