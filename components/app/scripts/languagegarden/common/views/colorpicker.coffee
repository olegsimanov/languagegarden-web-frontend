    'use strict'

    _ = require('underscore')
    $ = require('jquery')
    {BaseView} = require('./base')


    ###Creates a select with options from given colors.
    @param colors List of strings denoting color and the label, or object
    with fields: color (required), label (optional).
    @param initial Initial value to select, must be in colors.
    ###
    createColorSelectDom = (colors, initial) ->
        picker = $('<select>')

        for o in colors
            if _.isString(o)
                label = color = o
            else
                color = o.color
                label = o.label or o.color

            picker.append($('<option>').val(color).text(label))

        picker.val(initial) if initial?
        picker

    ###Creates simplecolorpicker at given el or $el.
    @param options, including:
    * colors List of strings or objects with .color and optional .label.
    * initial The initial value to set.
    * el or $el Selector/dom of container to put the picker in,
    * pickerOptions Fed directly to simplecolorpicker constructor.
    ###
    createColorPicker = (options) =>
        select = createColorSelectDom(options.colors, options.initial)

        $el = options.$el
        $el ?= $(options.el) if options.el?

        $el.html(select) if $el

        select.simplecolorpicker(options.pickerOptions)
        select


    ###Color picker wrapper view.###
    ColorSelectView = class extends BaseView

        picker: true
        delay: 0

        initialize: (options) =>
            @colors = @initializeColors(options.colors)
            @initial = options.initial

            @pickerOptions = options.pickerOptions or {}
            @pickerOptions['picker'] ?= @picker
            @pickerOptions['delay'] ?= @delay

        initializeColors: (colors) ->
            for c in colors
                if _.isString(c)
                    label: c
                    color: c
                else
                    color: c.color
                    label: c.label or c.color

        render: =>
            @$picker = createColorPicker
                colors: @colors
                initial: @initial
                $el: @$el
                pickerOptions:
                    @pickerOptions
            @


    module.exports =
        createColorPicker: createColorPicker
        ColorSelectView: ColorSelectView

