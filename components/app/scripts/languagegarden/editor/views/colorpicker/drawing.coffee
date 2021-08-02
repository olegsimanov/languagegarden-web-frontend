    'use strict'

    {BBox} = require('./../../../math/bboxes')
    {TSpanMultiColorGradient} = require('./../../../common/svggradient')


    applyGradientOverElement = (element, tool, editor, paper) ->
        paper ?= editor.paper
        bbox = BBox.fromSVGRect(element.getBBox())

        gradient = new TSpanMultiColorGradient
            paper: paper
            multiColor: {color: c} for c in tool.getColors()

        options =
            x1: bbox.getLeft()
            y1: bbox.getTop()
            x2: bbox.getLeft()
            y2: bbox.getBottom()
        gradient.update(options)
        gradient.applyOnElement(element)
        gradient

    applyGradientColor = (path, tool, editor, paper) =>
        oldGradient = path.multiColorGradientFill
        newGradient = applyGradientOverElement(path, tool, editor)
        path.multiColorGradientFill = newGradient
        path

    applySimpleColor = (path, tool) ->
        path.attr(fill: tool.get('color'))
        path

    contributeToPie = (pie, tool, editor) ->
        switch tool.type
            when 'color' then applySimpleColor(pie, tool)
            when 'splitcolor' then applyGradientColor(pie, tool, editor)

    contributeToPreview = (preview, tool, editor) ->
        switch tool.type
            when 'color' then applySimpleColor(preview, tool)
            when 'splitcolor' then applyGradientColor(preview, tool, editor)


    module.exports =
        applyGradientColor: applyGradientColor
        contributeToPie: contributeToPie
        contributeToPreview: contributeToPreview
