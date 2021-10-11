    'use strict'

    Hammer              = require('hammerjs')
    _                   = require('underscore')
    jQuery              = require('jquery')
    $                   = require('jquery')

    {HtmlMediumView}    = require('./base')
    {PlacementType}     = require('../../constants')
    {
        isWord,
        isWordOrEmpty,
        chopIntoWords
    }                   = require('./../../utils')
    {BBox}              = require('./../../math/bboxes')


    class TextToCanvasView extends HtmlMediumView

        className:              'text-to-canvas-box'
        spanHTML:               '<span class="element">'
        pHTML:                  '<p class="line">'
        spanSelector:           'span.element'
        pSelector:              'p.line'
        spanDraggedOutClass:    'dragged-out'
        spanMarkedClass:        'marked'

        initialize: (options) ->
            super
            @setEditableMode(true)

        isSelected: -> false

        select: ->

        getPlacementType: -> PlacementType.UNDERSOIL

        setEditableMode: (enabled=true) ->
            eventHandlerDict =
                'input': @onInput
                'keyup': @onKeyUp
                'keypress': @onKeyPress
                'blur': @onBlur

            if enabled
                @$el.attr('tabindex', 0)
                @$el.attr('contenteditable', 'true')
                @setSelectableMode(true)

                if not @elHammer?
                    pan = new Hammer.Pan(threshold: 0)
                    @elHammer = Hammer(@el)
                    @elHammer.add(pan)

                @elHammer
                    .on('panstart', @onDragStart)
                    .on('pan', @onDragMove)
                    .on('panend', @onDragEnd)

                @$el.on(eventHandlerDict)
            else
                @$el.removeAttr('tabindex')
                @$el.removeAttr('contenteditable')
                @setSelectableMode(false)
                if @elHammer
                    @elHammer.off('panstart', @onDragStart)
                    @elHammer.off('pan', @onDragMove)
                    @elHammer.off('panend', @onDragEnd)
                @$el.off(eventHandlerDict)

        setSelectableMode: (enabled=true) ->
            unselectable = if enabled then 'off' else 'on'
            @$el.attr('unselectable', unselectable)
            @$el.find('p').attr('unselectable', unselectable)
            @$el.find('span').attr('unselectable', unselectable)

        getCaretPosition: ->
            sel = window.getSelection()
            if sel.rangeCount == 0
                return null
            range = sel.getRangeAt(0)

            if range.endContainer == @el
                range.endOffset
            else
                nodeFound = false
                caretPos = 0
                for pNode in @$el.find(@pSelector)

                    if range.endContainer == pNode
                        caretPos += range.endOffset
                        nodeFound = true
                        break

                    for spanNode in $(pNode).find(@spanSelector)
                        if range.endContainer == spanNode or range.endContainer == spanNode.childNodes[0]
                            caretPos += range.endOffset
                            nodeFound = true
                            break
                        caretPos += $(spanNode).text().length
                    if nodeFound
                        break
                    caretPos += 1
                caretPos

        getSpanInfoByCaretPosition: (caretPos) ->
            textElementIndex = 0
            for pNode in @$el.find(@pSelector)
                for spanNode in $(pNode).find(@spanSelector)
                    spanTextLen = $(spanNode).text().length
                    if caretPos > spanTextLen
                        caretPos -= spanTextLen
                    else
                        return {
                            node: spanNode
                            innerCaretPos: caretPos
                            textElementIndex: textElementIndex
                        }
                    textElementIndex += 1
                caretPos -= 1
            null

        getNearestWordSpanInfo: (spanInfo) ->
            if not spanInfo?
                return null

            $spanNode = $(spanInfo.node)
            if isWord($spanNode.text())
                spanInfo
            else
                if spanInfo.innerCaretPos == 0
                    $nearestSpanNode = $spanNode.prev()
                    indexDelta = -1
                else
                    $nearestSpanNode = $spanNode.next()
                    indexDelta = 1
                if $nearestSpanNode.length == 1
                    if isWord($nearestSpanNode.text())
                        node: $nearestSpanNode.get(0)
                        innerCaretPos: 0
                        textElementIndex: spanInfo.textElementIndex + indexDelta
                    else
                        null
                else
                    null

        setCaretPosition: (caretPos) ->
            spanInfo = @getSpanInfoByCaretPosition(caretPos)

            sel = window.getSelection()
            if spanInfo?
                spanNode = spanInfo.node
                caretPos = spanInfo.innerCaretPos
                sel.removeAllRanges()
                range = document.createRange()
                if spanNode.childNodes.length == 0
                    range.setStart(spanNode, caretPos)
                    range.setEnd(spanNode, caretPos)
                else
                    spanTextNode = spanNode.childNodes[0]
                    range.setStart(spanTextNode, caretPos)
                    range.setEnd(spanTextNode, caretPos)
                sel.addRange(range)

        getLineDataList: (textData) ->
            lines = []
            lineData = []
            for elemData in textData
                if elemData.text == '\n'
                    lines.push(lineData)
                    lineData = []
                else
                    lineData.push(elemData)
            lines.push(lineData)
            lines

        normalizeNodes: (modifiedByInput=false, keepFocus=true)->
            @$el.contents().filter(-> @nodeType == 3).wrap(@spanHTML)
            for pNode in @$el.find(@pSelector)
                $(pNode).contents().filter(-> @nodeType == 3).wrap(@spanHTML)

            @$el.find(@spanSelector).filter(-> not $(this).parent().hasClass('line')).wrap(@pHTML)

            caretPos = @getCaretPosition()

            for brNode in @$el.find('br')
                $(brNode).remove()

            for spanNode in @$el.find(@spanSelector)
                $span = $(spanNode)
                $spanPrev = $span.prev()
                if $spanPrev.length > 0
                    prevSpanText = $spanPrev.text()
                    spanText = $span.text()
                    if isWordOrEmpty(prevSpanText) and isWordOrEmpty(spanText)
                        $span
                            .removeClass(@spanDraggedOutClass)
                            .text(prevSpanText + spanText)
                        $spanPrev.remove()

            for spanNode in @$el.find(@spanSelector)
                $span = $(spanNode)
                spanDraggedOut = $span.hasClass(@spanDraggedOutClass)
                textSplits = chopIntoWords($span.text())

                cnt = 0
                for textSplit in textSplits
                    if isWord(textSplit)
                        cnt += 1

                preserveDraggedOut = cnt == 1

                if textSplits.length > 1
                    for textSplit in textSplits[...-1]
                        $newSpan = $(@spanHTML)
                        $newSpan.text(textSplit).insertBefore($span)
                        if preserveDraggedOut and isWord(textSplit)
                            $newSpan.toggleClass(@spanDraggedOutClass,
                                spanDraggedOut)
                    lastTextSplit = textSplits[textSplits.length - 1]
                    if not preserveDraggedOut or not isWord(lastTextSplit)
                        $span.removeClass(@spanDraggedOutClass)
                    $span.text(lastTextSplit)

            for pNode in @$el.find(@pSelector)
                $pNode = $(pNode)
                if $pNode.find(@spanSelector).length == 0
                    $pNode.remove()

            @setCaretPosition(caretPos) if keepFocus

            if modifiedByInput and not @isDragging()
                spanInfo = @getSpanInfoByCaretPosition(caretPos)
                if spanInfo?
                    $(spanInfo.node).removeClass(@spanDraggedOutClass)

        getViewTextData: ->
            textData = []
            for pNode in @$el.find(@pSelector)
                $pNode = $(pNode)
                for spanNode in $pNode.find(@spanSelector)
                    $spanNode = $(spanNode)
                    text = $spanNode.text()

                    if text.length == 0
                        continue
                    textData.push
                        text: text
                        draggedOut: $spanNode.hasClass(@spanDraggedOutClass)
                        marked: $spanNode.hasClass(@spanMarkedClass)
                if $pNode.next(@pSelector).length > 0
                    textData.push
                        text: '\n'
                        draggedOut: false
                        marked: false
            textData

        updateViewTextData: (textData) ->
            @$el.empty()
            lines = @getLineDataList(textData)
            for lineData in lines
                $p = $(@pHTML)
                if lineData.length == 0
                    $(@spanHTML).text('').appendTo($p)
                else
                    for elemData in lineData
                        $(@spanHTML)
                            .text(elemData.text)
                            .toggleClass(@spanDraggedOutClass, elemData.draggedOut)
                            .toggleClass(@spanMarkedClass, elemData.marked or false)
                            .appendTo($p)
                $p.appendTo(@$el)

        setModelContent: (keepFocus=true) ->
            @normalizeNodes(false, keepFocus)
            textData = @getViewTextData()
            @model.set('textElements', textData)

        updateFromModel: ->
            textData = @model.get('textElements') or []
            @updateViewTextData(textData)

        getAllowedBBox: (fontSize, helperWidth, helperHeight) ->
            [canvasWidth, canvasHeight] = @parentView.getCanvasSetupDimensions()
            [offsetX, offsetY] = @getOffsetCoords(fontSize,
                helperWidth, helperHeight)
            BBox.fromCoordinates(offsetX,
                offsetY,
                canvasWidth - (helperWidth - offsetX),
                canvasHeight - (helperHeight - offsetY))

        getOffsetCoords: (fontSize, helperWidth, helperHeight) ->
            [0, 4 * helperHeight / 5 - fontSize / 5]

        getWordFontSize: -> @parentView.settings.get('fontSize')

        getWordColor: ->
            @parentView.colorPalette?.get('newWordColor') or '#000000'

        areDragCoordsAllowed: (x, y) ->
            @_dragInfo.allowedBBox.containsCoordinates(x, y)

        getCanvasDragCoords: (event) ->
            if event.center?.x?
                x = event.center.x
                y = event.center.y
            else if event.pageX?
                x = event.pageX
                y = event.pageY
            else if event.x?
                x = event.x
                y = event.y
            else
                x = 0
                y = 0

            [x, y] = @parentView.transformToCanvasCoords(x, y)

        isDragging: -> @_dragInfo?

        onInput: (e) =>
            @normalizeNodes(true)

        onKeyUp: (e) =>
            code = if e.keyCode then e.keyCode else e.which
            if code >= 35 and code <= 40
                @keyPressed = false
            @normalizeNodes(@keyPressed)
            @keyPressed = false

        onKeyPress: (e) =>
            @normalizeNodes(false)
            @keyPressed = true

        onBlur: (e) =>
            @setModelContent(false)

        onDragStart: (e) =>
            e.preventDefault()
            e.srcEvent.stopPropagation()
            if @_dragInfo?
                return
            @setModelContent()
            @parentView.model.stopTrackingChanges()

            [x, y] = @getCanvasDragCoords(e)

            caretPos = @getCaretPosition()
            spanInfo = @getSpanInfoByCaretPosition(caretPos)
            wordSpanInfo = @getNearestWordSpanInfo(spanInfo)
            if wordSpanInfo?
                text = $(wordSpanInfo.node).text()
            else
                text = ''
            color = @getWordColor()
            fontSize = @getWordFontSize()
            $helper = $('<div class="text-to-canvas-helper">')
                .text(text)
                .css
                    'font-size': fontSize
                    'color': color
                    'opacity': 0.0
                .appendTo(@parentView.parentView.$pageContainer)
            helperWidth = $helper.width() or 0
            helperHeight = $helper.height() or 0
            $helper.css('opacity', '')
            [offsetX, offsetY] = @getOffsetCoords(fontSize,
                helperWidth, helperHeight)

            dragInfo =
                wordSpanInfo: wordSpanInfo
                text: text
                color: color
                caretPos: caretPos
                allowedBBox: @getAllowedBBox(fontSize, helperWidth, helperHeight)
                fontSize: fontSize
                helperMetrics:
                    width: helperWidth
                    height: helperHeight
                    offsetX: offsetX
                    offsetY: offsetY
                canvasOffset:
                    x: @parentView.parentView.canvasContainerShiftX
                    y: @parentView.parentView.canvasContainerShiftY
                jQueryHelper: $helper

            @_dragInfo = dragInfo
            @setSelectableMode(false)

        onDragMove: (e) =>
            e.preventDefault()
            e.srcEvent.stopPropagation()
            dragInfo = @_dragInfo

            [x, y] = @getCanvasDragCoords(e)

            dragInfo.jQueryHelper.css
                'left': x - dragInfo.helperMetrics.offsetX + dragInfo.canvasOffset.x
                'top': y - dragInfo.helperMetrics.offsetY + dragInfo.canvasOffset.y
            dragInfo.jQueryHelper.toggleClass('out-of-bounds', not @areDragCoordsAllowed(x, y))

        onDragEnd: (e) =>
            e.preventDefault()
            e.srcEvent.stopPropagation()
            dragInfo = @_dragInfo
            @setSelectableMode(true)
            @setCaretPosition(dragInfo.caretPos)

            [x, y] = @getCanvasDragCoords(e)
            $helper = dragInfo.jQueryHelper
            if dragInfo.text.length > 0 and @areDragCoordsAllowed(x, y)
                @parentView.addCanvasElement
                    text: dragInfo.text
                    startPoint: [x, y]
                $(dragInfo.wordSpanInfo.node).addClass(@spanDraggedOutClass)
                @setModelContent()
                $helper.remove()
            else
                $helper.fadeOut('slow', -> $helper.remove())

            @parentView.model.startTrackingChanges()
            delete @_dragInfo

        render: ->
            super
            @updateFromModel()
            this

    module.exports =
        TextToCanvasView:      TextToCanvasView
