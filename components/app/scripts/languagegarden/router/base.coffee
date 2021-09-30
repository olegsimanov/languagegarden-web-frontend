    'use strict'

    _ = require('underscore')
    Backbone = require('backbone')
    $ = require('jquery')
    {ControllerType, controllerConfig, transitionConfig} = require('./config')
    settings = require('../settings')


    class Router extends Backbone.Router
        routes:
            '': 'showMainScreen'

        controllerConfig: controllerConfig
        transitionConfig: transitionConfig

        initialize: (options) ->
            super
            @bindControllerRoutes()
            @containerElement = options.containerElement
            @loaderEl = options.loaderElement or options.loaderEl
            if @loaderEl
                @$loaderEl = $(@loaderEl)
            @useURL = options.useURL
            @backURL = options.backURL or '/'
            @userId = options.userId or null
            @windowHandlersMap = 'beforeunload': @onWindowBeforeUnload
            $(window).on(@windowHandlersMap)

        bindControllerRoutes: ->
            for cfg in @controllerConfig
                cfgRouting = cfg.routing or []
                for routingCfg in cfgRouting
                    do =>
                        controllerType = cfg.type
                        originalHandler = routingCfg.handler
                        optionsFromArgs = routingCfg.optionsFromArgs or (-> {})
                        routeHandler = (args...) =>
                            @showLoader()
                            options = optionsFromArgs.apply(this, args)
                            boundHandler = => originalHandler.apply(this, args)
                            @afterControllerLoaded(controllerType,
                                                   boundHandler,
                                                   options)

                        routes = routingCfg.routes or []
                        for route in routes
                            @route(route, routeHandler)
            return

        getControllerConfig: (controllerType) ->
            _.filter(@controllerConfig, (cfg) -> cfg.type == controllerType)[0]

        getDefaultControllerConfig: ->
            _.filter(@controllerConfig, (cfg) ->
                cfg.type == ControllerType.DEFAULT)[0]

        navigateToController:(navInfo={}) ->
            if @useURL
                @backboneNavigateToController(navInfo)
            else
                @internalNavigateToController(navInfo)

        generateURL: (navInfo) ->
            for cfg in @controllerConfig
                navInfoTypes = cfg.navInfoTypes or []
                if navInfo.type in navInfoTypes
                    return cfg.urlGenerator(navInfo)

            defaultCfg = @getDefaultControllerConfig()
            defaultCfg.urlGenerator(navInfo)

        internalNavigateToController: (navInfo) ->
            trigger = navInfo.trigger
            trigger ?= true
            if trigger
                url = @generateURL(navInfo)
                Backbone.history.loadUrl(url)

        backboneNavigateToController: (navInfo) ->
            trigger = navInfo.trigger
            trigger ?= true
            url = @generateURL(navInfo)
            Backbone.history.navigate(url, trigger: trigger)

        demoteController: ->
            if @controller?
                @stopListening(@controller)
                @previousController = @controller
                @controller = null
            @controllerType = null

        destroyDemotedController: ->
            if @previousController?
                @previousController.remove()
                @previousController = null

        createController: (controllerType, controllerCls, controllerOptions) ->
            @controller = new controllerCls(controllerOptions)
            @listenTo(@controller, 'navigate', @onControllerNavigate)
            @listenTo(@controller, 'start:success', @onControllerStartSuccess)
            @controllerType = controllerType

        switchToController: (options={}) ->
            controllerCls = options.controllerCls
            controllerType = options.controllerType

            controllerOptionsExtractor = ->

            for cfg in @transitionConfig
                if (cfg.startType == @controllerType and
                        cfg.endType == controllerType and
                        cfg.endControllerOptions?)
                    controllerOptionsExtractor = cfg.endControllerOptions
                    break
                if (cfg.endType == @controllerType and
                        cfg.startType == controllerType and
                        cfg.startControllerOptions?)
                    controllerOptionsExtractor = cfg.startControllerOptions
                    break

            controllerOptions = controllerOptionsExtractor.call(this, options)
            controllerOptions = _.extend {}, (controllerOptions or {}),
                containerElement: @containerElement
                userId: @userId
                backURL: @backURL

            @demoteController()
            @createController(controllerType, controllerCls, controllerOptions)
            options.success?()

        afterControllerLoaded: (controllerType, callback, options={}) ->
            if @controllerType == controllerType
                callback()
                return
            config = @getControllerConfig(controllerType)
            config.requireDependency (controllerModule) =>
                controllerCls = controllerModule[config.controllerName]
                opts = _.extend {}, options,
                    controllerType: controllerType
                    controllerCls: controllerCls
                    success: callback
                @switchToController(opts)

        showMainScreen: ->
            cfg = @getDefaultControllerConfig()
            @navigateToController
                type: cfg.navInfoTypes[0]

        onControllerNavigate: (source, navInfo) ->
            @navigateToController(navInfo)

        onControllerStartSuccess: (source) ->
            if @controller != source
                return
            @destroyDemotedController()
            @hideLoader()

        onWindowBeforeUnload: (e) =>
            @showLoader()
            return

        hideLoader: ->
            if @$loaderEl
                @$loaderEl.stop(true, true).hide()
            return

        showLoader: ->
            if @$loaderEl
                @$loaderEl.fadeIn('normal')
            return


    module.exports =
        Router: Router
