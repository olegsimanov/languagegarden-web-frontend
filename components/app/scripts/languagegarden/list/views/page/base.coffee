    'use strict'

    {PageView} = require('./../../../common/views/page/base')
    {template} = require('./../../../common/templates')


    ListPageView = class extends PageView
        events:
            'click .go-to-prev-page': 'onGoToPrevPageClick'
            'click .go-to-next-page': 'onGoToNextPageClick'
            'click .create-new-plant': 'onCreateNewPlant'
        template: template('./common/page/list.ejs')

        onGoToPrevPageClick: (e) =>
            e.preventDefault()
            @navigate
                type: 'list-plants'
                pageNumber: @getControllerPageNumber() - 1

        onGoToNextPageClick: (e) =>
            e.preventDefault()
            @navigate
                type: 'list-plants'
                pageNumber: @getControllerPageNumber() + 1

        onCreateNewPlant: (e) =>
            e.preventDefault()
            @navigate
                type: 'nav-plant'

        getControllerPageNumber: -> (@controller.collection.page or 0) + 1

        navigate: (navInfo) ->
            @controller.trigger('navigate', this, navInfo)


    module.exports =
        ListPageView: ListPageView
