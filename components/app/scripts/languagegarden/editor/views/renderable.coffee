    'use strict'

    _ = require('underscore')
    $ = require('jquery')
    {template} = require('./../../common/domutils')
    {BaseView} = require('./base')


    RenderSubviewMixin =

        ###Renders view(s) at a given selector.

        Params:
            @selector string  Selector for view's element in parent.
                      object  Multiple selector-view pairs can be specified this
                way. View can be a list of views to append.
            @view class or a list  View(s) to put at/append to selector.
                Unused if @selector was specified as an object.
            @append boolean  Whether to replace or append to the selector.

        If a list of views is given they will all be appended to the selector
        instead of just using setElement.
        ###
        renderSubview: (selector, view, append=false) ->
            if _.isObject selector
                selectors = selector
            else
                selectors = {}
                selectors[selector] = view

            _.each selectors, (view, selector) =>
                # rendering an array of views under the same selector
                # useful when subviews are table rows or list items
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

        ###Removes a subview - stopListening and calls remove.

        If the subview was given as a string attribute name, this.attribute will
        be deleted.
        ###
        removeSubview: (subview) ->

            if _.isString(subview)
                attribute = subview
                subview = @[attribute]
                delete @[attribute]

            @stopListening(subview) if subview?
            subview?.remove()

        getSubViews: -> _.flatten(_.values(@subviews or {}))

        ###Removes all views in the @subviews object.###
        removeAllSubviews: ->
            for view in @getSubViews()
                @removeSubview(view)
            @subviews = null

        ###
        Detaches all subviews from the DOM, but does not remove them.
        ###
        detachAllSubviews: ->
            for view in @getSubViews()
                view.$el.detach()
            return


    RenderableViewBase = BaseView
        .extend(RenderSubviewMixin)

    ###A base view for view that requires one of the following:
    * ejs template
    * subview rendering
    * attaching to parent view after rendering

    ###
    class RenderableView extends RenderableViewBase
        template: null
        containerView: null
        containerEl: null
        renderedTemplateResult: null
        renderChangedHTML: false

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
        RenderableView: RenderableView
        RenderSubviewMixin: RenderSubviewMixin
