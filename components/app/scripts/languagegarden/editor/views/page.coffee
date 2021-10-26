    'use strict'

    _                       = require('underscore')
    $                       = require('jquery')

    {getOffsetRect}         = require('./utils/dom')
    {
        TemplateView
        createTemplateWrapper
    }                       = require('./template')

    {AffineTransformation}  = require('./../math/transformations')





    class PageView extends TemplateView

        className:                  'page-wrapper'
        template:                   createTemplateWrapper('./common/page/main.ejs')
        shouldAppendToContainer:    true

        initialize: (options) ->
            super(options)
            $(window).on('resize', @updateContainerTransform)

        ########################################################################################################
        #                                      public API                                                     #
        ########################################################################################################

        render: ->
            @renderCore()
            @$pageContainer = @$('.page-container')                 # if you place this before 'renderCore' the rendering will break (try it out!)
            @appendToContainerIfNeeded()
            @updateContainerTransform()

        getPageScale: -> @containerScale

        transformToCanvasCoords: (x, y) ->
            [x, y] = @transformToPageCoords(x, y)
            [x - @canvasContainerShiftX, y - @canvasContainerShiftY]

        transformToCanvasCoordOffsets: (dx, dy) -> @transformToPageCoordOffsets(dx, dy)

        transformToCanvasBBox: (bbox) ->
            @transformToPageBBox(bbox).translate
                x: -@canvasContainerShiftX
                y: -@canvasContainerShiftY

        transformCanvasToContainerCoords: (x, y) -> @transformPageToContainerCoords(x + @canvasContainerShiftX, y + @canvasContainerShiftY)


        ########################################################################################################
        #                                      private API helper methods                                      #
        ########################################################################################################

        updateContainerTransform: =>
            if not @isRendered()
                return                                      # the view was not yet rendered, so this.$pageContainer is not available.
            @recalculateContainerTransform()

            if (@containerScale == 1.0 and @containerShiftX == 0 and @containerShiftY == 0)
                transformStr = 'none'
            else
                transformStr = @containerTransformString

            @$pageContainer.css({
                '-moz-transform':       transformStr,
                '-webkit-transform':    transformStr,
                '-o-transform':         transformStr,
                '-ms-transform':        transformStr,
                'transform':            transformStr
            })

        recalculateContainerTransform: =>
            @canvasContainerShiftX      = 10
            @canvasContainerShiftY      = 10
            containerWidth              = @$pageContainer.width()
            containerHeight             = @$pageContainer.height()

            for cssPropName in ['padding-left', 'padding-right']
                containerWidth += parseInt(@$pageContainer.css(cssPropName), 10)
            for cssPropName in ['padding-top', 'padding-bottom']
                containerHeight += parseInt(@$pageContainer.css(cssPropName), 10)

            [elWidth, elHeight] = @getElementDimensions()
            scale = _.min([elWidth / containerWidth, elHeight / containerHeight])

            ATF = AffineTransformation
            tf  = ATF.newIdentity()
            tf  = ATF.mul(tf, ATF.fromTranslationVector(
                x: - containerWidth / 2
                y: - containerHeight / 2
            ))
            tf  = ATF.mul(tf, ATF.fromScale(scale))
            tf  = ATF.mul(tf, ATF.fromTranslationVector(
                x: elWidth / (2 * scale)
                y: elHeight / (2 * scale)
            ))
            @containerTransformString = tf.toCSSTransform()

            @containerScale = scale

            # this is different than .e and .f entries of @containerTransform
            if elWidth / elHeight < containerWidth / containerHeight
                @containerShiftX = 0
                @containerShiftY = (elHeight - containerHeight * scale) / 2
            else
                @containerShiftX = (elWidth - containerWidth * scale) / 2
                @containerShiftY = 0

        getElementDimensions: =>
            if (@$el.parent().length == 0 and @$el.css('width') == '100%' and @$el.css('height') == '100%' and (containerEl = @getContainerEl())?)
                $containerEl = $(containerEl)
                [$containerEl.width(), $containerEl.height()]
            else
                [@$el.width(), @$el.height()]



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


    module.exports =
        PageView: PageView
