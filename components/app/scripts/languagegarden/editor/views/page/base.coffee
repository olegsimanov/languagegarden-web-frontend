    'use strict'

    _ = require('underscore')
    $ = require('jquery')
    {AffineTransformation} = require('./../../../math/transformations')
    {SIDEBAR_WIDTH} = require('./../../models/plants')
    {RenderableView} = require('./../renderable')
    {getOffsetRect} = require('./../../domutils')
    {template} = require('./../../templates')

    class PageView extends RenderableView

        className: 'page-wrapper'
        shouldAppendToContainer: true
        template: template('./common/page/main.ejs')

        initialize: (options) ->
            super
            $(window).on('resize', @updateContainerTransform)

        remove: ->
            $(window).off('resize', @updateContainerTransform)
            @removeAllSubviews()
            super

        render: ->
            @renderCore()
            @$pageContainer = @$('.page-container')
            @appendToContainerIfNeeded()
            # we need to add the transform after the element is appended
            # to the container - if we do that before, then for some reason
            # the style is lost on chrome. WTF google?
            @updateContainerTransform()

        getElementDimensions: ->
            if (@$el.parent().length == 0 and
                    @$el.css('width') == '100%' and
                    @$el.css('height') == '100%' and
                    (containerEl = @getContainerEl())?)
                # the element is not yet embedded into the DOM, so we use the
                # container element instead
                $containerEl = $(containerEl)
                [$containerEl.width(), $containerEl.height()]
            else
                [@$el.width(), @$el.height()]

        recalculateContainerTransform: ->
            ATF = AffineTransformation
            @canvasContainerShiftX = 10 + SIDEBAR_WIDTH
            @canvasContainerShiftY = 10
            containerWidth = @$pageContainer.width()
            containerHeight = @$pageContainer.height()
            for cssPropName in ['padding-left', 'padding-right']
                containerWidth += parseInt(@$pageContainer.css(cssPropName), 10)
            for cssPropName in ['padding-top', 'padding-bottom']
                containerHeight += parseInt(@$pageContainer.css(cssPropName), 10)
            [elWidth, elHeight] = @getElementDimensions()
            scale = _.min([elWidth / containerWidth, elHeight / containerHeight])
            tf = ATF.newIdentity()
            tf = ATF.mul(tf, ATF.fromTranslationVector(
                x: - containerWidth / 2
                y: - containerHeight / 2
            ))
            tf = ATF.mul(tf, ATF.fromScale(scale))
            tf = ATF.mul(tf, ATF.fromTranslationVector(
                x: elWidth / (2 * scale)
                y: elHeight / (2 * scale)
            ))
            @containerTransform = tf
            @containerTransformString = tf.toCSSTransform()

            @containerScale = scale
            # this is different than .e and .f entries of @containerTransform
            if elWidth / elHeight < containerWidth / containerHeight
                @containerShiftX = 0
                @containerShiftY = (elHeight - containerHeight * scale) / 2
            else
                @containerShiftX = (elWidth - containerWidth * scale) / 2
                @containerShiftY = 0
            @containerShift =
                for suf in ['Transform', 'Scale', 'ShiftX', 'ShiftY']
                    @trigger("change:pageContainer#{suf}", this, @["container#{suf}"])

        updateContainerTransform: =>
            if not @isRendered()
                # the view was not yet rendered, so this.$pageContainer
                # is not available.
                return
            @recalculateContainerTransform()
            if (@containerScale == 1.0 and @containerShiftX == 0 and
                    @containerShiftY == 0)
                transformStr = 'none'
            else
                transformStr = @containerTransformString
            @$pageContainer.css
                '-moz-transform': transformStr
                '-webkit-transform': transformStr
                '-o-transform': transformStr
                '-ms-transform': transformStr
                'transform': transformStr

        getPageScale: -> @containerScale

        transformToPageCoords: (x, y) ->
            r = getOffsetRect(@el)
            scale = 1.0 / @containerScale
            x -= r.x + @containerShiftX
            y -= r.y + @containerShiftY
            [x * scale, y * scale]

        transformToPageCoordOffsets: (dx, dy) ->
            scale = 1.0 / @containerScale
            [dx * scale, dy * scale]

        transformToPageBBox: (bbox) ->
            r = getOffsetRect(@el)
            scale = 1.0 / @containerScale
            bbox
                .getTranslated
                    x: - r.x - @containerShiftX
                    y: - r.y - @containerShiftY
                .scale
                    x: scale
                    y: scale

        transformPageToContainerCoords: (x, y) ->
            scale = @containerScale
            [x * scale + @containerShiftX, y * scale + @containerShiftY]


        transformToCanvasCoords: (x, y) ->
            [x, y] = @transformToPageCoords(x, y)
            [x - @canvasContainerShiftX, y - @canvasContainerShiftY]

        transformToCanvasCoordOffsets: (dx, dy) ->
            @transformToPageCoordOffsets(dx, dy)

        transformToCanvasBBox: (bbox) ->
            @transformToPageBBox(bbox).translate
                x: -@canvasContainerShiftX
                y: -@canvasContainerShiftY

        transformCanvasToContainerCoords: (x, y) ->
            @transformPageToContainerCoords(x + @canvasContainerShiftX,
                y + @canvasContainerShiftY)

    EditorPageView = class extends PageView

        initialize: (options) ->
            super
            @canvasView = options.canvasView
            @setupEventForwarding(@canvasView, 'navigate')

        remove: ->
            @stopListening(@canvasView)
            delete @canvasView
            super


    module.exports =
        EditorPageView: EditorPageView
