    'use strict'

    __raphael = require('raphael')
    _ = require('underscore')
    $ = require('jquery')
    {Point} = require('./../math/points')
    {wrapLetterWithZWJ} = require('./utils')
    {disableSelection} = require('./domutils')
    {Path} = require('./../math/bezier')
    settings = require('./../settings')
    {EventObject} = require('./events')


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
        paper = Raphael($measuringDiv.get(0), '100%', '100%')


    removeMeasuringPaper = (paper) ->
        if not paper?
            return
        paper.clear()
        $parent = $(paper.canvas).parent()
        $parent.remove()


    class LetterMetrics extends EventObject

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
            @consistencyTimeout = setTimeout(@onConsistencyTimeout,
                                             @consistencyIntervalTime)

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
            # omit translation information
            mat = Raphael.matrix(m.a, m.b, m.c, m.d, 0, 0)
            (new Point(mat.x(0.0, 1.0), mat.y(0.0, 1.0))).getNorm()

        _getLength: (pseudoLetter, size) ->
            # pseudoLetter can be one-letter string, but may also
            # contain additional zero-width joiners.
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
                        # choose the nearest size in cache
                        bestSizeKey = @cache.letterLengthMaxSize[letter]
                        return letterCache[bestSizeKey] * size / bestSizeKey

            # approximated length could not be calculated - fallback
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

        ###
        For given text returns the length for prefixes for given text.
        For instance, for text 'test' it will return the lengths of
        't', 'te', 'tes', 'test'.
        If empty is true then it will return the lengths of
        '', 't', 'te', 'tes', 'test'.
        ###
        getPrefixesLengths: (text, size, empty=false) ->
            prefixLen = 0
            prefixLengths = []
            if empty
                prefixLengths.push(0)
            for i in [0...text.length]
                prefixLen += @getLength(text.charAt(i), size)
                prefixLengths.push(prefixLen)
            prefixLengths

        getApproxTextLength: (text, size) -> @getTextLength(text, size)

        _getHeight: (letter, size) ->
            size * settings.fontSizeToLetterHeightMultiplier

        getHeight: (letter, size) -> @_getHeight(letter, size)

        getApproxHeight: (letter, size) -> @_getHeight(letter, size)

        ### Calculates min/max scale for given font size to remain in limits.

        TODO: perhaps use settings directly?
        TODO2: Add _.memoize
        ###
        getScaleBoundsForFontWidth: (fontSize, minW, maxW, largestLetter='W') =>
            baseSize = @getTextLength(largestLetter, fontSize)
            [minW / baseSize, maxW / baseSize]

        ###
        Checks the consistency of the cache. Sometimes the cache is filled
        too early, and this methods detects that and invalidates the cache
        if necessary.
        ###
        checkCacheConsistency: ->
            letterKeys = _.keys(@cache.letterLength)
            if letterKeys.length == 0
                # Cache is empty, nothing to do there
                return

            letter = letterKeys[0]
            maxSize = @cache.letterLengthMaxSize[letter]
            # cached letter/size found, proceeding...
            cachedMetric = @cache.letterLength[letter][maxSize]
            currentMetric = @_getLength(letter, maxSize)

            if cachedMetric == currentMetric
                # The metric is consistent, nothing to do there
                return
            @invalidateCache()

        onConsistencyTimeout: =>
            @checkCacheConsistency()
            # We are using 'exponential-constant' intervals instead of constant
            # time intervals.
            if @consistencyIntervalTime < 1800000
                # If the interval time is less than half a hour,
                # we double it. In other case it stays the same
                @consistencyIntervalTime *= 2
            @consistencyTimeout = setTimeout(@onConsistencyTimeout,
                                             @consistencyIntervalTime)


    module.exports =
        LetterMetrics: LetterMetrics
