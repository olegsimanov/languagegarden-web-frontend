    'use strict'

    _ = require('underscore')
    {template} = require('./../../../../common/templates')
    {
        CloseOnSelectSearchPanel
        SearchPanelItem
        EditSearchPanel
    } = require('./search')
    {MediaLibraryViewBase, MediaLibraryEditPanel} = require('./base')
    plantListModels = require('./../../../../common/models/plantlists')



    class PlantSearchPanelItem extends SearchPanelItem
        template: template('./editor/plants/library/search_item.ejs')

        onFileSelected: => @trigger('selected', @, @model)


    PlantSearchPanelPrototype =
        itemViewClass: PlantSearchPanelItem

        getPlantLink: (model) ->
            plantId = model.get('Id')
            "languagegarden://plant/#{plantId}/?groovy=1"


    class PlantLinkSearchPanel extends CloseOnSelectSearchPanel.extend(PlantSearchPanelPrototype)

        onItemSelected: (view, mediaMetaModel) =>
            @model.set
                'href': @getPlantLink(mediaMetaModel)
                'name': mediaMetaModel.get('Name')
                'originalName': mediaMetaModel.get('Name')
            @editor.model.addMedium(@model)
            @finishItemSelection()


    class PlantLinkEditSearchPanel extends EditSearchPanel.extend(PlantSearchPanelPrototype)

        onItemSelected: (view, mediaMetaModel) =>
            # sadly, we need to fire the change events each time...
            @setModelAttribute('href', @getPlantLink(mediaMetaModel))
            if @model.get('name') == @model.get('originalName')
                @setModelAttribute('name', mediaMetaModel.get('Name'))
            @setModelAttribute('originalName', mediaMetaModel.get('Name'))
            @finishItemSelection()


    class EditPlantLinkPanel extends MediaLibraryEditPanel
        template: template('./editor/plantlinks/library/edit.ejs')

        initialize: (options) ->
            super
            @listenTo(@parent, 'success:preview', @onSuccess)

        onSuccess: ->
            @parent.originalModel.set(@model.attributes)

        setupEditables: =>
            @setupEditable(
                'a#plant-link-edit-panel-input-name', 'text', 'name'
            )
            @setupEditable(
                'a#plant-link-edit-panel-input-href', 'text', 'href',
                {disabled: true}
            )

        isOKAllowed: -> true


    class ElementEditHRefSearchPanel extends PlantLinkEditSearchPanel


    class PlantLinkLibraryView extends MediaLibraryViewBase
        mediumMetaCollectionCls: plantListModels.PlantMetaCollection

        panels: [
            PlantLinkSearchPanel
        ]


    class PlantLinkLibraryEditView extends PlantLinkLibraryView

        panels: [
            {'panelName': 'preview', 'panelClass': EditPlantLinkPanel}
            {'panelName': 'searcg', 'panelClass': PlantLinkEditSearchPanel}
        ]


    class ElementEditHRefView extends MediaLibraryViewBase
        mediumMetaCollectionCls: plantListModels.PlantMetaCollection

        panels: [
            ElementEditHRefSearchPanel
        ]


    module.exports =
        PlantLinkLibraryView: PlantLinkLibraryView
        PlantLinkLibraryEditView: PlantLinkLibraryEditView
        ElementEditHRefView: ElementEditHRefView
