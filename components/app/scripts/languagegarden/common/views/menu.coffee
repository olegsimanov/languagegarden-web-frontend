    'use strict'

    _ = require('underscore')
    $ = require('jquery')
    {enumerate} = require('./../utils')
    {template} = require('./../templates')
    {RenderableView} = require('./renderable')
    {ModalView} = require('./modal')


    ###Base menu class that provides @panels handling.###
    class Menu extends ModalView

        modalTemplate: template('./editor/settings/modal.ejs')

        panelContentSelector: '.panel-content'
        defaultPanelIndex: 0
        defaultPanelName: null

        # list of panel classes or objects with panelClass and panelName keys
        # for named panels
        panels: null

        initialize: (options) =>

            args =
                template: @modalTemplate.render
                cancelText: 'Close'

            options.modalOptions = _.extend args, options.modalOptions or {}

            super
            @setPropertyFromOptions(options, 'canvasView', required: true)
            @setPropertyFromOptions(options, 'timeline', required: true)

            @initializePanels(options)
            @initializeNav(options)

        initializePanels: (options) =>
            @panels = options.panels or @panels
            @panelData = {}
            @panelDataOrdered = []
            for [i, panelData] in enumerate @panels

                if panelData.panelClass? and _.isString(panelData.panelName)
                    {panelClass, panelName} = panelData
                else
                    panelClass = panelData

                panelView = new panelClass(parent: @)

                panelData =
                    view: panelView
                    index: i

                @panelData[panelView.cid] = panelData
                @panelDataOrdered.push(panelData)

                if panelName
                    panelData['panelName'] = panelName
                    @panelDataByName ?= {}
                    @panelDataByName[panelName] = panelData

        initializeNav: (options) =>

        remove: =>
            for own cid, data of @panelData
                delete data.$el
            delete @panelData
            delete @panelDataByName
            delete @panelDataOrdered
            delete @timeline
            delete @canvasView
            super

        render: =>
            super
            @delegateEvents()
            @$panelContent = @$(@panelContentSelector)
            @renderNav()
            @


        renderNav: =>
        getNavItems: =>
        setActivePanel: (panel) =>
            if @currentPanel != panel
                oldPanel = @currentPanel
                @currentPanel = panel
                @trigger('change:panel', panel, oldPanel)

        setActivePanelByName: (name) => @setActivePanel(@getPanelByName(name))
        setActivePanelByIndex: (i) => @setActivePanel(@getPanelByIndex(i))

        getPanelByName: (name) => @panelDataByName[name]
        getPanelByIndex: (i) => @panelDataOrdered[i]

        getViewPanelData: (view) => _.find @panelData, (pd) => pd.view == view

        openDefaultPanel: =>
            if @defaultPanelName?
                @setActivePanelByName(@defaultPanelName)
            else if @defaultPanelIndex?
                @setActivePanelByIndex(@defaultPanelIndex)


    ###A simple menu requiring navigation already available in the template.###
    class SimpleNavMenu extends Menu

        navItemSelector: '.nav-item'

        initialize: (options) =>
            @navItemSelector = options.navItemSelector or @navItemSelector
            super
            @events ?= {}
            @events["click #{@navItemSelector}"] = 'onNavClick'

        setActivePanel: (panel=@currentPanel) =>
            super
            _.each @$navItems, (i) =>
                if i.attr('id') == panel.view.cid
                    i.parent().addClass('active')
                else
                    i.parent().removeClass('active')
            panel.view.show()

        renderNav: =>
            @$navItems = _.map @getNavItems(), $
            initialCid = (
                @currentPanel or @panelDataOrdered[@defaultPanelIndex]
            ).view.cid
            initialNav = _.find @$navItems, (e) => e.attr('id') == initialCid
            initialNav.click()

        getNavItems: => @$el.find(@navItemSelector)

        onNavClick: (e) =>
            e.preventDefault()
            @currentPanel?.view.hide()
            cid = $(e.target).attr('id')

            # reset cached $els so that they do not prevent adding
            if @$panelContent.children().length == 0
                for own c, data of @panelData
                    delete data.$el if data.$el

            panelData = @panelData[cid]

            if not panelData.$el?
                panelData.$el = panelData.view.render().$el
                @$panelContent.append(panelData.$el)

            @setActivePanel(panelData)


    ### Panel of a menu. ###
    class Panel extends RenderableView

        title: 'Panel'
        menuName: 'Panel'

        initialize: (options) =>
            super
            @parent = options.parent
            @title = options?.title or @title
            @menuName = options?.menuName or @menuName or @title

            @panelCssClass = @menuName.toLowerCase().replace(' ', '-')
            @panelNavClass = "#{@panelCssClass}-nav"
            @panelDivClass = "#{@panelCssClass}-panel"
            @isShown = false

        render: =>
            super
            @isShown = true
            @

        remove: =>
            delete @parent
            super

        hide: =>
            @isShown = false
            @$el.hide()

        show: =>
            @isShown = true
            @$el.show()

    module.exports =
        Menu: Menu
        SimpleNavMenu: SimpleNavMenu
        Panel: Panel
