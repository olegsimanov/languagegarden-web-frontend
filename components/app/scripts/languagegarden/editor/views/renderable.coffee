    'use strict'

    _           = require('underscore')
    $           = require('jquery')
    {BaseView}  = require('./base')
    {template}  = require('./domutils')


    RenderSubviewMixin =

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


    class RenderableView extends BaseView.extend(RenderSubviewMixin)

        template:               null
        containerView:          null
        containerEl:            null
        renderedTemplateResult: null
        renderChangedHTML:      false

        initialize: (options) ->
            super
            @setOption(options, 'containerView')
            @setOption(options, 'containerEl')
            @setOption(options, 'template')
            @setOption(options, 'subviews')
            @rendered = false

        isRendered: -> @rendered

        getRenderContext: (ctx={}) ->
            ctx = _.extend {
                view: @
            }, ctx

        renderAllSubviews: ->
            if @subviews
                @renderSubview(@subviews)

        renderTemplate: ->
            if not @template?
                return
            ctx = @getRenderContext(ctx)
            result = @template.render(ctx)
            if (@renderChangedHTML and
                    not @subviews and
                    result == @renderedTemplateResult)
                return
            @$el.html(result)
            @delegateEvents()
            @renderedTemplateResult = result

        renderCore: ->
            @detachAllSubviews()
            @renderTemplate()
            @renderAllSubviews()
            @rendered = true

        render: (ctx={}) ->
            @renderCore()
            @appendToContainerIfNeeded()
            this

        invalidate: ->
            if @rendered
                @render()
            this


    module.exports =
        RenderableView:     RenderableView
