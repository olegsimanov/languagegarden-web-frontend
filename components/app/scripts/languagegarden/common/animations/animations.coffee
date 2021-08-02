    'use strict'

    _ = require('underscore')
    {sum} = require('./../utils')
    {arrayInterpolator} = require('./../interpolations/base')
    {PropertySetupPrototype} = require('./../properties')


    class CoreAnimation

    _.extend(CoreAnimation.prototype, PropertySetupPrototype)

    class BaseAnimation extends CoreAnimation
        transitionsEnabled: true

        constructor: (options) ->
            @setPropertyFromOptions(options, 'debugInfo')
            @setPropertyFromOptions(options, 'update')
            @setPropertyFromOptions(options, 'transitionsEnabled')
            defaultTotalTime = if @transitionsEnabled then 1000 else 0
            @setPropertyFromOptions(options, 'totalTime',
                                    default: defaultTotalTime)
            @setPropertyFromOptions(options, 'endCallback', default: ->)
            @setPropertyFromOptions(options, 'startCallback', default: ->)
            @timeout = null
            @animFrameRequestID = null
            # this.t and this.startT are normalized (in range [0,1] - 0 is
            # the start of animation, 1 is the end of animation)
            @t = 0
            @startT = 0

        setupAnimFrame: ->
            @animFrameUpdate = =>
                @animFrameRequestID = requestAnimationFrame(@animFrameUpdate)
                time = new Date().getTime()
                @t = (time - @startTime) / @totalTime + @startT
                if @t <= 1.0
                    @frameCounter += 1
                    @update(@t)

        setup: ->
            @t = 0
            @startT = 0
            @frameCounter = 0
            @setupAnimFrame()
            @startCallback()

        tearDown: ->
            @endCallback()

        start: ->
            @setup()
            if @transitionsEnabled
                @play()
            else
                @tearDown()

        play: ->
            if not @transitionsEnabled
                return
            if @t < 1.0
                # this is needed to avoid flickering when an animation
                # based on the insert operation is performed (the fade-in)
                @update(@t)

            @startTime = new Date().getTime()
            @startT = @t
            clearTimeout(@timeout)
            cancelAnimationFrame(@animFrameRequestID)
            @animFrameRequestID = requestAnimationFrame(@animFrameUpdate)
            @timeout = setTimeout(@onTimeout, @totalTime)

        pause: ->
            clearTimeout(@timeout)
            cancelAnimationFrame(@animFrameRequestID)
            @timeout = null
            @animFrameRequestID = null

        rewind: -> @t = 0

        stop: ->
            @pause()
            @t = 0

        getFPS: (fraction=@t) ->
            if @transitionsEnabled
                secs = (fraction * @totalTime) / 1000
                @frameCounter / secs
            else
                # no transition - the FPS info is not available
                null

        getFinalFPS: -> @getFPS(1)

        bindOnEnd: (callback) ->
            oldCallback = @endCallback
            @endCallback = ->
                oldCallback()
                callback()

        runBefore: (animation, callback) ->
            oldCallback = @endCallback
            @endCallback = ->
                oldCallback()
                callback?()
                animation.start()

        onTimeout: =>
            @stop()
            @tearDown()
            return


    class Animation extends BaseAnimation
        constructor: (options) ->
            super
            @setPropertyFromOptions(options, 'appliedInterpolator')
            @setPropertyFromOptions(options, 'applicatorGetter')
            if not @update?
                appliedInterpolator = @appliedInterpolator
                applicator = options.applicator
                if applicator? and appliedInterpolator?
                    @update = (t) -> applicator(appliedInterpolator(t))

        setup: ->
            @startCallback()
            if not @update? and @appliedInterpolator? and @applicatorGetter?
                # applicator was not available at the construction time
                # but now we can get it via this.applicatorGetter
                appliedInterpolator = @appliedInterpolator
                applicator = @applicatorGetter()
                @update = (t) -> applicator(appliedInterpolator(t))
            if not @update?
                # fallback - update which does nothing
                @update = (t) ->
            @setupAnimFrame()


    class AggregateAnimation extends BaseAnimation

        constructor: (options) ->
            super
            @setPropertyFromOptions(options, 'animations', required: true)
            @transitionsEnabled = _.any(
                @animations, (anim) -> anim.transitionsEnabled)
            @totalTime = if @transitionsEnabled then 1000 else 0


    ###
    Executes given list of animations (options.animations - in constructor)
    In parallel, but with assumption to execute .setup(), .update(),
    .teardown() in proper order.
    ###
    class ParallelAnimation extends AggregateAnimation

        constructor: (options) ->
            super
            animationTimes = (anim.totalTime for anim in @animations)
            @totalTime = _.max(animationTimes)

        setup: ->
            super
            for anim in @animations
                anim.setup()
            return

        update: (t) ->
            for anim in @animations
                anim.update(t)
            return

        tearDown: ->
            for anim in @animations
                anim.tearDown()
            super

    ###
    Accepts a list of states to use. If not provided an interpolator will use
    array interpolator by default.
    ###
    class StateAnimation extends Animation

        constructor: (options) ->
            @states = options.states if options.states?

            if not options.appliedInterpolator?
                options.appliedInterpolator = arrayInterpolator(@states)

            super

            @step = options.step or 1 / @states.length
            @stepTime = 100


    ###
    Executes given list of animations (options.animations - in constructor)
    sequentially.
    ###
    class SerialAnimation extends AggregateAnimation

        constructor: (options) ->
            super
            animationTimes = (anim.totalTime for anim in @animations)
            @totalTime = sum(animationTimes)
            prevAnim = null
            for anim in @animations
                if not prevAnim?
                    prevAnim = anim
                    continue

                do =>
                    animation = anim
                    # animation chaining
                    prevAnim.runBefore(anim, =>
                        @currentAnimation = animation
                    )

                prevAnim = anim

            if @animations.length > 0
                lastAnim = @animations[@animations.length - 1]
                lastAnim.bindOnEnd(@onTimeout)

        play: ->
            if not @transitionsEnabled
                return
            @currentAnimation = @animations[0]
            @currentAnimation.start()

        pause: ->
            @currentAnimation?.stop()
            @currentAnimation = null


    module.exports =
        Animation: Animation
        ParallelAnimation: ParallelAnimation
        SerialAnimation: SerialAnimation
        StateAnimation: StateAnimation
