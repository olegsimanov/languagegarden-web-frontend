'use strict'

{RenderableView} = require('./renderable')
{template} = require('./../templates')


class DropDown extends RenderableView
    tagName: 'span'
    template: template('./common/dropdown.ejs')
    events:
        'change select': 'onSelectChange'

    initialize: (options) ->
        super
        @setPropertyFromOptions(options, 'value')

    getRenderOptions: -> []

    getRenderContext: ->
        opts = @getRenderOptions()
        for opt in opts
            if opt.value == @value
                opt.selected = 'selected'
        ctx = super
        ctx.options = opts
        ctx

    onSelectChange: ->
        @value = @$('select').val()
        @trigger('change:value', this, @value)
        @trigger('change', this)


module.exports =
    DropDown: DropDown
