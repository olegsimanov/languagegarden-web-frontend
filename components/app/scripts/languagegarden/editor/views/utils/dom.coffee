    'use strict'

    _                       = require('underscore')
    $                       = require('jquery')

    utils                   = require('./../../utils')
    settings                = require('../../../settings')

    {Point}                 = require('../../math/points')
    {BBox}                  = require('../../math/bboxes')
    {AffineTransformation}  = require('../../math/transformations')


    getOffsetRect = (node) ->
        box = node.getBoundingClientRect()
        doc = node.ownerDocument
        body = doc.body or {}
        docElem = doc.documentElement or {}
        clientLeft = docElem.clientLeft or body.clientLeft or 0
        clientTop = docElem.clientTop or body.clientTop or 0

        scrollLeft = window.pageXOffset or docElem.scrollLeft or body.scrollLeft
        scrollTop = window.pageYOffset or docElem.scrollTop or body.scrollTop

        left = box.left + scrollLeft - clientLeft
        top  = box.top  + scrollTop - clientTop

        x: left
        y: top
        width: box.width
        height: box.height

    getScaleFactor = (node) ->
        f = 1.0
        while node?
            $node = $(node)
            transformStr = ($node.css('-moz-transform') or
                            $node.css('-webkit-transform') or
                            $node.css('-o-transform') or
                            $node.css('-ms-transform') or
                            $node.css('transform'))

            t = AffineTransformation.fromCSSTransform(transformStr)
            f *= Math.max(t.a, t.d)
            node = node.parentElement

        f

    # pre-order DOM traverse
    filterDescendants = (node, predicate) ->
        result = []
        scanNode = (recNode) ->
            if predicate(recNode)
                result.push(recNode)
            for n in recNode.childNodes
                scanNode(n)
            return
        scanNode(node)
        result

    getIntersectingSVGElementsByName = (svgNode, tagName, x, y, width=1, height=1) ->
        so = getOffsetRect(svgNode)
        sr = svgNode.createSVGRect()
        sr.x = x - so.x
        sr.y = y - so.y
        sr.width = width
        sr.height = height
        try
            hits = svgNode.getIntersectionList(sr, null)
        catch error
            # in FF getIntersectionList is not implemented
            console.log(error)
            hits = []

        clickBBox = BBox.fromSVGRect(sr)
        predicate = (node) ->
            if node.tagName != tagName
                false
            else
                rect = node.getClientRects()[0]
                if rect?
                    nodeBBox = BBox.fromXYWH(rect.left, rect.top,
                                             rect.width, rect.height)
                    clickBBox.intersects(nodeBBox)
                else
                    false

        filterLists = (filterDescendants(h, predicate) for h in hits)
        _.flatten(filterLists)

    getSVGElementByNameAndCoords = (svgNode, tagName, x, y) ->
        target = document.elementFromPoint(x, y)
        if target.tagName == tagName
            return target

        hits = getIntersectingSVGElementsByName(svgNode, tagName, x, y)

        if hits.length
            hits[hits.length - 1]
        else
            null

    getSVGElementClasses = (node) ->
        attrValue = node.getAttribute('class')
        if attrValue?
            (cls for cls in attrValue.split(' ') when cls != '')
        else
            []

    setSVGElementClasses = (node, classNames) ->
        value = classNames.join(' ')
        node.setAttribute('class', value)

    addSVGElementClass = (node, className) ->
        classNames = getSVGElementClasses(node)
        if not (className in classNames)
            classNames.push(className)
            setSVGElementClasses(node, classNames)

    removeSVGElementClass = (node, className) ->
        classNames = getSVGElementClasses(node)
        if className in classNames
            classNames = (cls for cls in classNames when cls != className)
            setSVGElementClasses(node, classNames)

    toggleSVGElementClass = (node, className, flag) ->
        if flag
            addSVGElementClass(node, className)
        else
            removeSVGElementClass(node, className)

    getCurvedPathString = (startPoint, controlPoints, endPoint) ->
        stringList = []
        stringList.push('M')
        stringList.push("#{startPoint.x} #{startPoint.y}")
        stringList.push('Q')
        for cp in controlPoints
            stringList.push("#{cp.x} #{cp.y} ")
        stringList.push("#{endPoint.x} #{endPoint.y}")
        stringList.join('')

    getPolygonPathString = (startPoint, restOfPoints...) ->
        startString = "#{startPoint.x} #{startPoint.y}"
        restString = ("#{p.x} #{p.y}" for p in restOfPoints).join(' ')
        "M #{startString} L #{restString} Z"

    getQuadrilateralPathString = (a1, a2, a3, a4) ->
        "M #{a1.x} #{a1.y} L #{a2.x} #{a2.y} #{a3.x} #{a3.y} #{a4.x} #{a4.y} Z"

    getCaretPosition = (node) ->
        if node.selectionStart?
            node.selectionStart
        else if not document.selection?
            0
        else
            # for IE
            c = String.fromCharCode(1)
            sel = document.selection.createRange()
            dul = sel.duplicate()
            len = 0

            dul.moveToElementText(node)
            sel.text = c
            len = dul.text.indexOf(c)
            sel.moveStart('character', -1)
            sel.text = ""
            len

    setCaretPosition = (node, pos) ->
        if node.createTextRange?
            range = node.createTextRange()
            range.move('character', pos)
            range.select()
        else if node.selectionStart?
            node.focus()
            node.setSelectionRange(pos, pos)
        else
            node.focus()

    disableSelection = (node) ->
        node.setAttribute('unselectable', 'on')
        if typeof node.onselectstart != 'undefined'
            node.onselectstart = -> false

    retrieveId = (node) ->
        elemId = node.getAttribute('id')
        if not elemId?
            elemId = _.uniqueId("lg-#{node.tagName}-uniq-")
            node.setAttribute('id', elemId)
        elemId

    _preloadCore = (imageUrls, options) ->
        staticUrl = options?.staticUrl or ''
        imageUrls = [imageUrls] if _.isString(imageUrls)
        for imageUrl in imageUrls
            img = new Image()
            if options?.onload?
                img.onload = (e) -> options.onload(e, @src)
            if options?.onerror?
                img.onerror = (e) -> options.onerror(e, @src)
            img.src = "#{staticUrl}#{imageUrl}"

    preload = (imageUrls, options) =>
        if options?.delay?
            _.delay (-> _preloadCore(imageUrls, options)), options.delay
        else
            _preloadCore(imageUrls, options)

    selectAllContenteditableContent = (el) ->
        # http://stackoverflow.com/questions/3805852/
        # select-all-text-in-contenteditable-div-when-it-focus-click

        # The delay is required due to the native select event overriding
        # the selection in chrome and safari.
        _.delay ->
            if window.getSelection? && document.createRange?
                range = document.createRange()
                range.selectNodeContents(el)
                sel = window.getSelection()
                sel.removeAllRanges()
                sel.addRange(range)
            else if document.body.createTextRange?
                range = document.body.createTextRange()
                range.moveToElementText(el)
                range.select()

    getSelectedText = ->
        if window.getSelection
            text = window.getSelection().toString()
        else if document.getSelection
            text = document.getSelection().toString()
        else if document.selection
            text = document.selection.createRange().text
        text

    getSelectedHtml = ->
        html = ""
        if typeof window.getSelection != "undefined"
            sel = window.getSelection()
            if sel.rangeCount
                container = document.createElement("div")
                for i in [0...sel.rangeCount]
                    container.appendChild(sel.getRangeAt(i).cloneContents())
                html = container.innerHTML
        else if typeof document.selection != "undefined"
            if document.selection.type == "Text"
                html = document.selection.createRange().htmlText
        return html


    module.exports =

        getCurvedPathString:                getCurvedPathString
        getPolygonPathString:               getPolygonPathString
        getQuadrilateralPathString:         getQuadrilateralPathString

        getCaretPosition:                   getCaretPosition
        setCaretPosition:                   setCaretPosition

        disableSelection:                   disableSelection
        retrieveId:                         retrieveId
        getSVGElementByNameAndCoords:       getSVGElementByNameAndCoords
        getIntersectingSVGElementsByName:   getIntersectingSVGElementsByName

        addSVGElementClass:                 addSVGElementClass
        removeSVGElementClass:              removeSVGElementClass
        toggleSVGElementClass:              toggleSVGElementClass

        getOffsetRect:                      getOffsetRect
        getScaleFactor:                     getScaleFactor
        preload:                            preload
        selectAllContenteditableContent:    selectAllContenteditableContent
        getSelectedText:                    getSelectedText
        getSelectedHtml:                    getSelectedHtml
