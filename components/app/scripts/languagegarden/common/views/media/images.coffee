    'use strict'

    {addSVGElementClass, disableSelection} = require('./../../domutils')
    {Point} = require('./../../../math/points')
    {BBox} = require('./../../../math/bboxes')
    {SvgMediumView} = require('./base')
    {CanvasLayers} = require('./../../constants')


    class ImageView extends SvgMediumView

        initialize: (options) =>
            super
            @imageObj = null
            @width = 0
            @height = 0

        onModelBind: ->
            @listenTo(@model, 'change:url', @onModelUrlChange)

        remove: =>
            @removeOnloadImage(loaded: false)
            @imageObj?.remove()
            super

        removeOnloadImage: (options) ->
            if @onLoadImage?
                @onLoadImage.onload = null
                # the remove is not always defined in the Image prototype
                # (for instance, in Opera)
                if options?.loaded
                    @onLoadImage.remove?()
                delete @onLoadImage

        getBBox: =>
            if @imageObj?
                BBox.fromSVGRect(@imageObj.getBBox())
            else
                BBox.newEmpty()

        intersects: (bbox) => @getBBox().intersects(bbox)

        loadImageDimesions: (callback) =>
            if @width > 0 and @height > 0
                return
            url = @model.get('url')
            @onLoadImage = image = new Image()
            image.onload = =>
                @width = image.width
                @height = image.height
                @removeOnloadImage(loaded: true)
                @trigger('load:dimensions')
                callback()
            image.src = url
            if image.width? and image.width > 0 and image.height? and image.height > 0
                # sometimes we do not have to wait for the image dimensions
                @width = image.width
                @height = image.height

        updateImageObj: =>
            [x, y, width, height] = @getXYWH()
            @imageObj.attr
                x: x
                y: y
                width: width
                height: height
            url = @model.get('url')
            @imageObj.attr(src: url) if @imageObj.attr('src') != url
            @imageObj

        createImageObj: =>
            [x, y, width, height] = @getXYWH()
            url = @model.get('url')
            @imageObj = @paper.image(url, x, y, width, height)
            addSVGElementClass(@imageObj.node, 'medium')
            disableSelection(@imageObj.node)
            # for some reason, using utils disableSelection is not enough
            # when applied on SVG image. therefore we use preventDefault
            # on click/drag using standard raphael event system
            @imageObj.click((e) -> e.preventDefault())
            @imageObj.drag(((dx,dy,x,y,e) -> e.preventDefault()),
                           ((x,y,e) -> e.preventDefault()))
            @toFront()
            @bindImageEvents()
            @imageObj

        getXYWH: =>
            center = @model.get('centerPoint')
            width = if @width > 0 then @width else 64
            height = if @height > 0 then @height else 64
            x = center.x - width / 2.0
            y = center.y - height / 2.0
            [x, y, width, height]

        getScaleVector: ->
            scaleVector = @model.get('scaleVector')
            maxDevVector = @model.get('maxDeviationVector')
            if maxDevVector?
                [x, y, width, height] = @getXYWH()
                scaleVector = @model.get('scaleVector')
                scaledDevX = scaleVector.x * width * 0.5
                scaledDevY = scaleVector.y * height * 0.5
                if scaledDevX > maxDevVector.x or scaledDevY > maxDevVector.y
                    if scaledDevX * maxDevVector.y > scaledDevY * maxDevVector.x
                        factor = maxDevVector.x / scaledDevX
                    else
                        factor = maxDevVector.y / scaledDevY
                    scaleVector.mul(factor)
                else
                    scaleVector
            else
                scaleVector

        applyTransform: (obj, scale, rotate, center) =>
            scale ?= @getScaleVector()
            rotate ?= @model.get('rotateAngle')
            center ?= @model.get('centerPoint')
            obj.transform [
                'R', rotate, center.x, center.y,
                'S', scale.x, scale.y, center.x, center.y]

        render: =>
            @loadImageDimesions(@render)

            if @imageObj?
                @updateImageObj()
            else
                @createImageObj()

            @updateVisibility()
            @applyTransform(@imageObj)

            this

        toFront: ->
            if not @imageObj?
                return
            @parentView.putElementToFrontAtLayer(@imageObj, CanvasLayers.IMAGES)

        setCoreOpacity: (opacity) -> @imageObj?.attr('opacity', opacity)

        bindImageEvents: =>

        onModelUrlChange: ->
            @width = @height = 0
            @removeOnloadImage(loaded: false)


    module.exports =
        ImageView: ImageView
