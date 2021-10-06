    'use strict'

    require('raphael')
    _ = require('underscore')
    $ = require('jquery')

    {disableSelection}      = require('./../domutils')
    {Point}                 = require('./../../math/points')
    {Path}                  = require('./../../math/bezier')
    {wrapLetterWithZWJ}     = require('./../../utils')
    {EventsAwareClass}      = require('./../../events')
    settings                = require('./../../../settings')

    createMeasuringPaper = ->
        $measuringDiv = $('<div>')
        .addClass('metrics-measuring-div')
        .css
            'left': 0
            'top': 0
            'right': 0
            'bottom': 0
            'position': 'absolute'
            'overflow': 'hidden'
            'z-index': -1000
        .appendTo(document.body)
        Raphael($measuringDiv.get(0), '100%', '100%')


    removeMeasuringPaper = (paper) ->
        if not paper?
            return
        paper.clear()
        $parent = $(paper.canvas).parent()
        $parent.remove()


    class LetterMetrics extends EventsAwareClass

        constructor: (options={}) ->
            @paper = options.paper
            @paperAutoCreated = false
            if not @paper
                @paper = createMeasuringPaper()
                @paperAutoCreated = true
            # Creating helper element to signal the browser that we use
            # the webfont.
            @_getLength('A', 20)
            @setCacheFlag(true)
            @setFastMode(false)
            @invalidateCache(silent: true)
            @consistencyIntervalTime = 500
            @consistencyTimeout = setTimeout(@onConsistencyTimeout, @consistencyIntervalTime)

        remove: ->
            if @paperAutoCreated
                removeMeasuringPaper(@paper)
            @paper = null
            clearTimeout(@consistencyTimeout)

        setCacheFlag: (useCache=true) =>
            @useCache = useCache
            this

        setFastMode: (fastMode) ->
            @fastMode = fastMode
            if fastMode
                @getLength = @getApproxLength
            else
                @getLength = @getExactLength
            this

        createTextHelperObj: (text, size, transform) =>
            obj = @paper.text(0, 0, text)
            disableSelection(obj.node)
            obj.node.removeAttribute('font')
            obj.node.style['font-family'] = ''
            obj.attr
                'font-size': size
                'fill': 'rgba(0,0,0,0)'
            obj.transform(transform.toTransformString()) if transform?
            obj

        removeTextHelperObj: (obj) ->
            obj.remove()

        invalidateCache: (options) ->
            @cache =
                letterLength: {}
                letterHeight: {}
                letterLengthMinSize: {}
                letterLengthMaxSize: {}

            silent = options?.silent
            silent ?= false
            if not silent
                @trigger('cache:invalidate', this)

        getScaleFactor: (m) =>
            mat = Raphael.matrix(m.a, m.b, m.c, m.d, 0, 0)
            (new Point(mat.x(0.0, 1.0), mat.y(0.0, 1.0))).getNorm()

        _getLength: (pseudoLetter, size) ->
            obj = @createTextHelperObj(pseudoLetter, size)
            try
                node = obj.node
                len = node.getSubStringLength(0, pseudoLetter.length)
                rectWidth = node.getClientRects()[0]?.width or 0
                if rectWidth > 0 and Math.abs(rectWidth - len) > size * 0.25
                    # there may be some mismatch for the arabic letters
                    # so we use the rect width in some cases instead
                    len = rectWidth
            catch e
                len = null
            @removeTextHelperObj(obj)
            len

        getExactLength: (letter, size) ->
            sizeKey = size
            @cache.letterLength[letter] ?= {}
            letterCache = @cache.letterLength[letter]
            if not @useCache
                len = @_getLength(letter, size)
            else if not letterCache[sizeKey]?
                minSize = @cache.letterLengthMinSize
                maxSize = @cache.letterLengthMaxSize
                len = @_getLength(letter, size)
                if _.size(letterCache) > 256
                    k =_.keys(letterCache)[0]
                    delete letterCache[k]
                if len?
                    letterCache[sizeKey] = len
                    if not minSize[letter]? or minSize[letter] > size
                        minSize[letter] = size
                    if not maxSize[letter]? or maxSize[letter] < size
                        maxSize[letter] = size
                else
                    len = size
            else
                len = letterCache[sizeKey]
            len

        getApproxLength: (letter, size) ->
            if @useCache
                letterCache = @cache.letterLength[letter]
                if letterCache?
                    if letterCache[size]?
                        return letterCache[size]
                    else
                        bestSizeKey = @cache.letterLengthMaxSize[letter]
                        return letterCache[bestSizeKey] * size / bestSizeKey

            @getExactLength(letter, size)

        getTextLength: (text, size) ->
            opts = {}
            l = 0
            for i in [0...text.length]
                opts.previousLetter = text[i - 1]
                opts.nextLetter = text[i + 1]
                wrappedLetter = wrapLetterWithZWJ(text[i], opts)
                l += @getLength(wrappedLetter, size)
            l

        _getHeight: (letter, size) ->
            size * settings.fontSizeToLetterHeightMultiplier

        getHeight: (letter, size) -> @_getHeight(letter, size)

        checkCacheConsistency: ->
            letterKeys = _.keys(@cache.letterLength)
            if letterKeys.length == 0
                return

            letter = letterKeys[0]
            maxSize = @cache.letterLengthMaxSize[letter]
            cachedMetric = @cache.letterLength[letter][maxSize]
            currentMetric = @_getLength(letter, maxSize)

            if cachedMetric == currentMetric
                return
            @invalidateCache()

        onConsistencyTimeout: =>
            @checkCacheConsistency()
            if @consistencyIntervalTime < 1800000
                @consistencyIntervalTime *= 2
            @consistencyTimeout = setTimeout(@onConsistencyTimeout, @consistencyIntervalTime)


    module.exports =
        LetterMetrics: LetterMetrics
