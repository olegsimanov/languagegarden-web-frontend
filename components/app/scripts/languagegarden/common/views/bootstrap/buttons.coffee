    'use strict'

    {BaseView} = require('./../base')


    class BootstrapButtonView extends BaseView

        tagName: 'a'
        className: 'btn'

        attributes:
            href: '#'

        events:
            'click': 'onClick'

        initialize: (options) ->
            @text = options.text if options.text?
            @onClick = options.onClick if options.onClick?
            @active = false
            @listenTo(@, 'change:active', @render)

        remove: =>
            @stopListening(@)
            super

        onClick: =>

        render: =>
            @$el.toggleClass('active', @active)
            @$el.html(@text)
            @

        show: =>
            @delegateEvents()
            @$el.show()

        hide: => @$el.hide()

        setActive: (value) =>
            if value != @active
                @active = value
                @trigger('change:active', @)

    module.exports =
        BootstrapButtonView: BootstrapButtonView
