    'use strict'

    _ = require('underscore')
    require('raphael.free_transform.custom')
    {
        disableSelection
        addSVGElementClass
        toggleSVGElementClass
    } = require('./../../../common/domutils')
    {Point} = require('./../../../math/points')
    {ImageView} = require('./../../../common/views/media/images')
    {CanvasLayers} = require('./../../../common/constants')
    editorViewsBase = require('./base')
    commonViewsBase = require('./../../../common/views/media/base')



    ExtendedImageView = ImageView
        .extend(editorViewsBase.SelectablePrototype)
        .extend(commonViewsBase.SVGStylablePrototype)
        .extend(editorViewsBase.EventDispatchingPrototype)
        .extend(editorViewsBase.EventBindingPrototype)
        .extend(commonViewsBase.VisibilityPrototype)


    class EditorImageView extends ExtendedImageView

        initialize: (options) =>
            super
            @editor = options.editor
            @listenTo(this, 'load:dimensions', @onLoadDimensions)
            @listenTo(@model, 'change:url', @resetImage)
            @listenTo(@model, 'change:centerPoint', @onCenterPointChange)

            @showHandles = false

        remove: =>
            @stopListening(this)
            @stopListening(@editor)
            @freeTransformObj?.unplug()
            @clickArea?.remove()
            super

        resetImage: =>
            # reset stored heigh, width and scale
            [@width, @height] = [0, 0]
            @model.set('scaleVector', new Point(1, 1))
            # remove active freeTransformObj wrapper if exists
            @freeTransformObj?.unplug()
            delete @freeTransformObj
            @render()

        isDebugMode: => @editor.debug

        appyClickAreaStyles: (area=@clickArea) =>
            transparentColor = 'rgba(0,0,0,0)'
            blackColor = '#000000'
            showBorders = @isDebugMode()
            if showBorders
                borderWidth = 1
                borderColor = blackColor
            else
                borderWidth = 0
                borderColor = transparentColor
            disableSelection(area.node)
            addSVGElementClass(area.node, 'image-medium-handle')
            area.attr
                'fill': transparentColor
                'stroke-width': borderWidth
                'stroke': borderColor


        createClickArea: =>
            [x, y, width, height] = @getXYWH()
            @clickArea = @paper.rect(x, y, width, height)
            disableSelection(@imageObj.node)
            # for some reason, using utils disableSelection is not enough
            # when applied on SVG image. therefore we use preventDefault
            # on click/drag using standard raphael event system
            @imageObj.click((e) -> e.preventDefault())
            @imageObj.drag(((dx,dy,x,y,e) -> e.preventDefault()),
                           ((x,y,e) -> e.preventDefault()))
            @appyClickAreaStyles()
            @bindClickAreaEvents()
            @clickArea

        updateClickArea: =>
            [x, y, width, height] = @getXYWH()
            @clickArea.attr
                x: x
                y: y
                width: width
                height: height

        onCenterPointChange: =>
            @applyTransform(@imageObj)
            @updateImageObj()

            if @clickArea?
                @updateClickArea()
                @applyTransform(@clickArea)

        render: =>
            super

            if @clickArea?
                @updateClickArea()
            else
                @createClickArea()

            @applyTransform(@clickArea)

            if @showHandles
                if @freeTransformObj?
                    @freeTransformObj.apply()
                    @freeTransformObj.updateHandles()
                else
                    options =
                        drag: false
                        preventRotateOnShiftPress: true
                        keepRatio: ['axisX', 'axisY', 'bboxCorners', 'bboxSides']
                        rotate: ['axisX', 'axisY']
                        scale: ['axisX', 'axisY', 'bboxCorners']
                    @freeTransformObj = @paper.freeTransform(
                        @clickArea, options, @onFreeTransformEvent)
            else if @freeTransformObj?
                @freeTransformObj?.unplug()
                # .unplug seems to remove all drag events from wrapped object
                # so we call undrag and apply preventdefault for drag again
                @clickArea.undrag()
                @clickArea.drag(((dx,dy,x,y,e) -> e.preventDefault()),
                               ((x,y,e) -> e.preventDefault()))
                @freeTransformObj = null

            @toFront()

            this

        updateShowControls: (@showHandles) => @render()

        getElementNode: => @imageObj.node

        select: (selected=true, options) =>
            super
            toggleSVGElementClass(@clickArea.node, 'selected', @selected)

        getClickableNode: -> @clickArea.node

        onLoadDimensions: =>
            if not @freeTransformObj?
                return
            ftAttrs = @freeTransformObj.attrs
            ftAttrs.size.x = @width
            ftAttrs.size.y = @height
            @freeTransformObj.updateHandles()

        onFreeTransformEvent: (ft, eventNames) =>
            attributes = {}
            ftAttrs = ft.attrs
            draggingEventNames = ['drag', 'rotate', 'scale']
            notDraggingEventNames = _.flatten(("#{a} #{b}" for a in draggingEventNames for b in ['begin', 'end']))
            eventNamePresent = (eventName) -> eventName in eventNames

            if _.any(draggingEventNames, eventNamePresent)
                # dragging in progress, update editor field
                @editor.setDragging(true)
                @toFront()
            else if _.any(notDraggingEventNames, eventNamePresent)
                # dragging started/ended, update editor field
                @editor.setDragging(false)

            if 'apply'
                # copy calculated transform to the image
                @imageObj.node.setAttribute(
                    'transform',
                    @clickArea.node.getAttribute('transform'))

            if 'drag end' in eventNames
                centerPoint = @model.get('centerPoint')
                attributes.centerPoint = centerPoint.add(ftAttrs.translate)
                ftAttrs.center.x += ftAttrs.translate.x
                ftAttrs.center.y += ftAttrs.translate.y
                ftAttrs.x += ftAttrs.translate.x
                ftAttrs.y += ftAttrs.translate.y
                ftAttrs.translate.x = 0
                ftAttrs.translate.y = 0

            if 'rotate end' in eventNames
                attributes.rotateAngle = ftAttrs.rotate
            if 'scale end' in eventNames
                attributes.scaleVector = Point.fromObject(ftAttrs.scale)

            if _.size(attributes)
                @model.set(attributes)
                @render()
                @editor.selectionBBoxChange()

        toFront: ->
            super
            if @clickArea?
                @parentView.putElementToFrontAtLayer(
                    @clickArea, CanvasLayers.IMAGE_AREAS)

        bindImageEvents: =>
        bindClickAreaEvents: => @bindClickableElementEvents()


    module.exports =
        EditorImageView: EditorImageView
