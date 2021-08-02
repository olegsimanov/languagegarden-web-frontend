    'use strict'

    _ = require('underscore')
    $ = require('jquery')
    require('jquery.browser')
    swfobject = require('swfobject')
    swfUrl = require('file!../../../mp3player/player_mp3_js.swf')
    settings = require('./../settings')
    {pathJoin} = require('./utils')
    {EventObject} = require('./events')
    {buildPropertySupportPrototype} = require('./properties')


    ModelSupportPrototype = buildPropertySupportPrototype('model')

    typeSpecs = [
        extensions: ['ogg']
        urlName: 'urlOGG'
        type: 'audio/ogg'
        codecs: 'vorbis'
    ,
        extensions: ['oga']
        type: 'audio/ogg'
    ,
        extensions: ['mp3']
        urlName: 'urlMP3'
        type: 'audio/mp3'
    ]


    getUrlDict = (model) =>
        result = {}

        for url in (model.get('urls') or []).concat([model.get('url')])
            if url? and url.length > 4
                urlSuffix = url.substr(url.length - 4)
                for spec in typeSpecs
                    for specExt in spec.extensions
                        if urlSuffix == ".#{specExt}"
                            result[spec.type] = url
        # support for deprecated url attributes, should be removed
        # in the future
        for spec in typeSpecs
            url = model.get(spec.urlName)
            if url?
                result[spec.type] = url

        result


    class AbstractAdapter extends EventObject

        getUrlDict: => getUrlDict(@model)

        isRewinded: => @getProgressTime() == 0

        onPlaybackChange: =>
            @trigger('playbackchange', this)

        onProgressChange: =>
            @trigger('progresschange', this)
            if not @isRewinded() and @getProgressTime() == @getTotalTime()
                @stop()


    class DummyAdapter extends AbstractAdapter

        @isMimeTypeSupported: (mimeType) -> false

        isPlaying: -> false

        isPaused: -> true

        play: ->

        stop: ->

        pause: ->

        getProgressTime: -> 0

        getTotalTime: -> 0

        setProgressTime: (time) ->


    class HTML5Adapter extends AbstractAdapter

        @isMimeTypeSupported: (mimeType) ->
            try
                audio = document.createElement('audio')
            catch
                # IE9 claims to support HTML5 audio, however the line
                # above may fail on IE9. WTF?
                return false
            if not audio.canPlayType
                false
            else
                canPlayType = audio.canPlayType(mimeType)
                if $.browser.mozilla
                    # 'maybe' may not be enough for given mimetype support, see bug:
                    # https://bugzilla.mozilla.org/show_bug.cgi?id=919572
                    not (canPlayType in [null, '', 'no', 'maybe'])
                else
                    # in other cases (for instance, iPad Safari)
                    # 'maybe' should be enough
                    not (canPlayType in [null, '', 'no'])


        initialize: (options) ->
            @model = options.model
            @parentEl = options.parentEl or document.body
            @audioNode = @createAudioNode()
            $(@parentEl).append(@audioNode)
            $(@audioNode)
            .on('pause', @onPlaybackChange)
            .on('play', @onPlaybackChange)
            .on('ended', @onPlaybackChange)
            .on('timeupdate', @onProgressChange)

        remove: =>
            $(@audioNode).off().remove()

        createAudioNode: =>
            urlDict = @getUrlDict()

            $audio = $('<audio>')
            for spec in typeSpecs
                url = urlDict[spec.type]
                if url?
                    $source = $('<source>')
                    $source.attr('src', url)

                    for attrName in ['type', 'codecs']
                        if spec[attrName]?
                            $source.attr(attrName, spec[attrName])
                $audio.append($source)
            $audio.get(0)

        isPlaying: => not @audioNode.paused

        isPaused: => @audioNode.paused

        play: => @audioNode.play()

        stop: =>
            @audioNode.pause()
            @audioNode.currentTime = 0

        pause: => @audioNode.pause()

        getProgressTime: => @audioNode.currentTime

        getTotalTime: => @audioNode.duration

        setProgressTime: (time) =>
            @audioNode.currentTime = time

    class FlashAdapterState
        @STOPPED = 'stopped'
        @PAUSED = 'paused'
        @STARTED_PLAYING ='started-playing'
        @PLAYING ='playing'


    class FlashAdapter extends AbstractAdapter

        @isMimeTypeSupported: (mimeType) -> mimeType == 'audio/mp3'

        interval: 1000

        initialize: (options) ->
            @model = options.model
            @parentEl = options.parentEl or document.body
            @listener =
                position: 0
                duration: 0
                isPlaying: false

                onInit: =>
                    # remove the interval-based consistency checking
                    clearInterval(@checkInterval)
                onUpdate: =>
                    @listener.position = parseInt(@listener.position, 10)
                    @listener.duration = parseInt(@listener.duration, 10)
                    if isNaN(@listener.position) then @listener.position = 0
                    if isNaN(@listener.duration) then @listener.duration = 0
                    @listener.isPlaying = @listener.isPlaying == 'true'
                    @checkConsistency()
                    @onPlaybackChange()
                    @onProgressChange()

            @listenerName = _.uniqueId('lglistener')
            # setting the listener as global object to be accessible from
            # swf file
            window[@listenerName] = @listener
            @swfNode = @createSwfNode()
            @state = FlashAdapterState.STOPPED
            @wasPlayed = false
            @checkInterval = setInterval(@intervalHandler, @interval)
            $(@parentEl).append(@swfNode)

        remove: =>
            clearInterval(@checkInterval)
            $(@swfNode).off().remove()

        getUrlDict: => getUrlDict(@model)

        createSwfNode: =>
            url = @getUrlDict()['audio/mp3']
            params =
                allowscriptaccess: 'always'

            flashVars =
                mp3: url
                listener: @listenerName
                interval: @interval
                enabled: 'true'

            elementId = _.uniqueId('swfcontainer')
            $container = $('<div>')
            $container.attr('id', elementId)
            .appendTo(@parentEl)
            swfobject.embedSWF(swfUrl, elementId, 1, 1, "8.0", null, flashVars, params)
            # swfobject replaces the container in place, therefore we can
            # retrieve the swf object by container id
            swfNode = document.getElementById(elementId)
            $swfNode = $(swfNode)
            $swfNode.attr('type', 'application/x-shockwave-flash')
            $swfNode.attr('data', swfUrl)
            $swfNode.detach()
            swfNode

        callSwfMethod: (method, param) =>
            param = param or ''
            @swfNode.SetVariable("method:#{method}", param)

        isPlaying: => @listener.isPlaying

        isPaused: => not @listener.isPlaying

        play: =>
            @callSwfMethod('play')
            @state = FlashAdapterState.STARTED_PLAYING

        stop: =>
            @callSwfMethod('stop')
            @state = FlashAdapterState.STOPPED

        pause: =>
            @callSwfMethod('pause')
            @state = FlashAdapterState.PAUSED

        getProgressTime: => @listener.position

        getTotalTime: => @listener.duration

        setProgressTime: (time) =>  @callSwfMethod('setPosition', time)

        intervalHandler: =>
            @checkConsistency()

        checkConsistency: ->
            switch @state
                when FlashAdapterState.STARTED_PLAYING
                    if @wasPlayed
                        # The player is re-playing so we can immediately
                        # change the state (MP3 is already loaded).
                        @state = FlashAdapterState.PLAYING
                    else
                        if @listener.isPlaying
                            @state = FlashAdapterState.PLAYING
                            @wasPlayed = true
                        else
                            # Flash player is not actually playing, so repeat
                            # the 'play' method.
                            @callSwfMethod('play')
                            if $.browser.msie and $.browser.versionNumber <= 9
                                # HACK: On IE9 the Init() handler of the flash
                                # listener will not be called for some reason.
                                # therefore we work it around by setting the
                                # state manually.
                                @state = FlashAdapterState.PLAYING
                                @wasPlayed = true
                when FlashAdapterState.PLAYING
                    if not @listener.isPlaying
                        # Flash player stopped playing - keep the state
                        # consistent.
                        @state = FlashAdapterState.STOPPED


    class SoundPlayer extends EventObject.extend(ModelSupportPrototype)
        adapterClasses: [
            HTML5Adapter,
            FlashAdapter,
        ]

        initialize: (options) ->
            if options?.bus?
                @bus = options.bus
            @adapter = new DummyAdapter()
            opts =
                initialize: true
                force: true
                initializeOptions: options
            @setModel(options?.model, opts)

        onModelBind: (options) ->
            opts = _.extend({}, (options?.initializeOptions or {}), model: @model)
            @adapter = @createAdapter(opts)
            @listenTo(@adapter, 'playbackchange', @onPlaybackChange)
            @listenTo(@adapter, 'progresschange', @onProgressChange)

        onModelUnbind: ->
            @stopListening(@adapter)
            @adapter.remove()
            @adapter = new DummyAdapter()

        remove: =>
            @setModel(null)

        isClassSupporting: (cls, model) =>
            urlDict = getUrlDict(model)
            types = _.keys(urlDict)
            _.any(types, (t) -> cls.isMimeTypeSupported(t))

        createAdapter: (options) =>
            for cls in @adapterClasses
                if @isClassSupporting(cls, options.model)
                    return new cls(options)
            # use HTML5Adapter as fallback class
            new HTML5Adapter(options)

        isRewinded: => @adapter.isRewinded()

        isPlaying: => @adapter.isPlaying()

        isPaused: => @adapter.isPaused()

        play: => @adapter.play()

        stop: => @adapter.stop()

        pause: => @adapter.pause()

        onPlaybackChange: =>
            @trigger('playbackchange', this)
            @bus?.trigger('playbackchange', this)

        onProgressChange: =>
            @trigger('progresschange', this)
            @bus?.trigger('progresschange', this)

        getProgressTime: => @adapter.getProgressTime()

        getTotalTime: => @adapter.getTotalTime()

        setProgressTime: (time) => @adapter.setProgressTime(time)

        getAnnotations: -> {}


    module.exports =
        SoundPlayer: SoundPlayer
