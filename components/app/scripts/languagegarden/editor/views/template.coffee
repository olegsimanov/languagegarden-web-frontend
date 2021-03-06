    'use strict'

    _           = require('underscore')
    $           = require('jquery')


    {BaseView}  = require('./base')

    utils       = require('./../utils')
    settings    = require('./../../settings')

    class TemplateObject

        @templateFunction: null

        constructor: (templateFunction) -> @templateFunction = templateFunction

        render: (ctx={}) =>
            ctx = _.extend {
                utils:      utils
                settings:   settings
                '$':        $
                '_':        _
            }, ctx
            @templateFunction(ctx)


    templateWrapper         = (templateFunction) -> new TemplateObject(templateFunction)
    templateContext         = require.context('./../../../../templates/', true, /^.*\.ejs$/);
    createTemplateWrapper   = (name) -> templateWrapper(templateContext(name))

    class TemplateView extends BaseView

        containerView:          null
        containerEl:            null
        template:               null
        subviews:               null

        renderedTemplateResult: null
        renderChangedHTML:      false
        rendered:               false

        initialize: (options) ->
            super
            @setOption(options, 'containerView')
            @setOption(options, 'containerEl')
            @setOption(options, 'template')
            @setOption(options, 'subviews')

        invalidate: ->
            if @rendered
                @render()
            this

        isRendered:                             -> @rendered

        getRenderContext: (ctx={})          -> ctx = _.extend( { view: @ }, ctx )

        render: () ->
            @renderCore()
            @appendToContainerIfNeeded()
            this


        renderCore: ->
            @detachAllSubviews()
            @renderTemplate()
            @renderAllSubviews()
            @rendered = true

        renderTemplate: ->

            if not @template?
                return

            ctx         = @getRenderContext()
            result      = @template.render(ctx)

            if (@renderChangedHTML and not @subviews and result == @renderedTemplateResult)
                return

            @$el.html(result)
            @delegateEvents()
            @renderedTemplateResult = result

        renderAllSubviews: ->
            if @subviews
                @renderSubview(@subviews)

        renderSubview: (selector, view, append=false) ->

            if _.isObject selector
                selectors = selector
            else
                selectors = {}
                selectors[selector] = view

            _.each selectors, (view, selector) =>
                if append and not _.isArray view
                    view = [view]
                if _.isArray view
                    if not selector? or selector == ''
                        $el = @$el
                    else
                        $el = @$(selector)
                    for v in view
                        v.render()
                        $el.append(v.$el)
                else
                    view.setElement(@$(selector)).render()

        removeSubview: (subview) ->

            if _.isString(subview)
                attribute = subview
                subview = @[attribute]
                delete @[attribute]

            @stopListening(subview) if subview?
            subview?.remove()

        getSubViews: -> _.flatten(_.values(@subviews or {}))

        removeAllSubviews: ->
            for view in @getSubViews()
                @removeSubview(view)
            @subviews = null

        detachAllSubviews: ->
            for view in @getSubViews()
                view.$el.detach()
            return

    module.exports =
        createTemplateWrapper:  createTemplateWrapper
        TemplateView:           TemplateView
