    'use strict'

    _ = require('underscore')
    {
        interpolateNumber
        stepInterpolateValue
        immediateStepInterpolateValue
        arrayInterpolator
        exponentialInterpolateValue
    } = require('./../interpolations/base')
    {interpolateCoord} = require('./../interpolations/points')
    {interpolateColor} = require('./../interpolations/colors')
    {interpolateDegree} = require('./../interpolations/angles')
    {OperationType} = require('./../diffs/operations')
    {splitDiff, getDiff} = require('./../diffs/utils')
    {
        markedOpacityMap
        visibilityOpacityMap
    } = require('./../constants')
    {lcm} = require('./../../math/numtheory')
    {PropertySetupPrototype} = require('./../properties')
    {Animation, ParallelAnimation, StateAnimation} = require('./animations')
    {getLabelsAppliedInterpolator} = require('./../interpolations/labels')


    ###
    Returns application getter (a function, which evaluation is an
    1-parameter function, which applies given value magically
    "somewhere" - usually it is a model attribute) whenever it is possible.
    In other case, it returns null.
    ###
    getViewApplicatorGetter = (attrName, operation, viewSelector, options={}) ->

        if attrName == 'marked'
            return ->
                view = viewSelector()
                (value) ->
                    view.setAnimOpacity(value)


        if operation.type != OperationType.REPLACE
            return null

        contextNames = operation.getContextNames()
        lastContextName = operation.getLastContextName()
        if lastContextName in ['x', 'y']

            if contextNames.length == 1
                # model attribute is a point
                ->
                    view = viewSelector()
                    model = view.model
                    model.getFastAttributeLevel1Setter(attrName,
                                                       lastContextName)

            else if contextNames.length == 2
                index = parseInt(contextNames[0], 10)
                if not _.isNaN(index)
                    # model attribute is a point array
                    ->
                        view = viewSelector()
                        model = view.model
                        model.getFastAttributeLevel2Setter(attrName, index,
                                                           lastContextName)
                else
                    null

            else
                null

        else if attrName == 'lettersAttributes'
            if contextNames.length == 2 and lastContextName == 'labels'
                index = parseInt(contextNames[0], 10)
                if not _.isNaN(index)
                    ->
                        view = viewSelector()
                        model = view.model
                        (value) ->
                            attrValue = model.get(attrName)
                            attrValue[index][lastContextName] = value
                            model.set(attrName, attrValue)
                else
                    null
            else
                null

        else if attrName == 'visibilityType'
            ->
                view = viewSelector()
                (value) ->
                    view.setAnimOpacity(value)

        else if attrName == 'fontSize'
            ->
                view = viewSelector()
                model = view.model
                model.getFastAttributeSetter('fontSize')

        else if operation.context == ''
            ->
                view = viewSelector()
                model = view.model
                (value) ->
                    model.set(attrName, value)
        else
            null


    ###
    Returns applied interpolator (1-argument function which for given t
    returns interpolated value) whenever it is possible. In other case,
    it returns null.
    ###
    getViewAppliedInterpolator = (attrName, operation, viewSelector, options={}) ->

        if attrName == 'marked'
            oldValue = operation.oldValue
            oldValue ?= true
            newValue = operation.newValue
            newValue ?= true
            return exponentialInterpolateValue(
                markedOpacityMap[oldValue],
                markedOpacityMap[newValue]
            )

        if operation.type != OperationType.REPLACE
            return null

        if options.forceStep
            return null

        if attrName == 'text'
            return immediateStepInterpolateValue(
                operation.oldValue, operation.newValue)

        if attrName == 'visibilityType'
            return exponentialInterpolateValue(
                visibilityOpacityMap[operation.oldValue],
                visibilityOpacityMap[operation.newValue]
            )

        contextNames = operation.getContextNames()
        lastContextName = operation.getLastContextName()

        if (attrName == 'lettersAttributes' and
            contextNames.length == 2 and
            lastContextName == 'labels' and
            not _.isNaN(parseInt(contextNames[0], 10)) and
            options.helpers?.colorPalette?)
                # we need the color palette to translate the label names
                # to the real colors to use them in interpolator
                colorPalette = options.helpers?.colorPalette
                appliedInter = getLabelsAppliedInterpolator(operation.oldValue,
                                                            operation.newValue,
                                                            colorPalette)
                if appliedInter?
                    return appliedInter

        isValid = (value) ->
            _.isNumber(value) and not _.isNaN(value) and _.isFinite(value)

        if not (isValid(operation.oldValue) and isValid(operation.newValue))
            return null

        if contextNames.length in [1, 2] and lastContextName in ['x', 'y']
            interpolateCoord(operation.oldValue, operation.newValue)
        else if attrName == 'fontSize' and operation.context == ''
            # we must use the same type for interpolating the fontSize
            # as used for interpolating the x,y coordinates
            interpolateCoord(operation.oldValue, operation.newValue)
        else if attrName == 'rotateAngle' and operation.context == ''
            interpolateDegree(operation.oldValue, operation.newValue)
        else if operation.context == ''
            interpolateNumber(operation.oldValue, operation.newValue)
        else
            null

    ###
    Returns a callback which applies specified operation on model obtained
    via modelSelector function
    ###
    getModelChangeCallback = (attrName, operation, modelSelector, options={}) ->
        if attrName == ''
            switch operation.type
                when OperationType.DELETE
                    ->
                        modelSelector().clear()
                when OperationType.INSERT
                    ->
                        modelSelector().set(operation.newValue)
                when OperationType.REPLACE
                    ->
                        model = modelSelector()
                        model.clear(silent: true)
                        model.set(operation.newValue)
                else
                    ->
                        model = modelSelector()
                        value = model.toJSON()
                        value = operation.apply(value)
                        if value?
                            model.clear(silent: true)
                            model.set(value)
                        else
                            model.clear()
        else
            operationApplyHelper = ->
                model = modelSelector()
                value = model.get(attrName)
                if _.isFunction(value?.toJSON)
                    value = value.toJSON()
                value = operation.apply(value)
                model.set(attrName, value)

            if operation.type == OperationType.DELETE
                if operation.context != ''
                    operationApplyHelper
                else
                    ->
                        modelSelector().unset(attrName)
            else
                operationApplyHelper


    ###
    Returns a callback which applies specified operation on model obtained
    using the viewSelector function.
    ###
    getViewChangeCallback = (attrName, operation, viewSelector, options={}) ->
        modelSelector = ->
            viewSelector().model
        getModelChangeCallback(attrName, operation, modelSelector, options)


    getAnimationEndCallback = (attrName, operation, viewSelector, options) ->
        if (attrName == 'text' or
                attrName in ['textElements', 'noteTextContent'] or
                (attrName == 'lettersAttributes' and
                 operation.type != OperationType.REPLACE))
            # the text changes and lettersAttributes insertions/deletions were
            # already applied in getAnimationStartCallback
            null
        else
            getViewChangeCallback(attrName, operation, viewSelector, options)

    getAnimationStartCallback = (attrName, operation, viewSelector, options) ->
        changeCallback = getViewChangeCallback(attrName, operation, viewSelector, options)
        elementAttrNames = [
            'startPoint', 'endPoint', 'controlPoints',
            'fontSize', 'lettersAttributes',
        ]
        if attrName  == 'text'
            # we change the state before the animation starts, additonally
            # setting proper the textDirty flag
            # TODO: remove textDirty flag in ElementView
            ->
                viewSelector().textDirty = true
                changeCallback()
        else if (attrName == 'lettersAttributes' and
                 operation.type != OperationType.REPLACE)
            # because the text changed at the beginning, we also need to do
            # the same with lettersAttributes insertions/deletions, in order to
            # have the view/model in coherent state.
            changeCallback
        else if (attrName in ['textElements', 'noteTextContent'])
            changeCallback
        else if (attrName in elementAttrNames and
                operation.type == OperationType.REPLACE and options?.forceStep)
            # we set the element points & font size on start when the
            # element text has changed (options.forceStep indicates this)
            changeCallback
        else
            null

    getAnimations = (diff, viewSelector, options={}) ->
        callRender = options.callRender or false
        forceStep = options.forceStep or false
        diffHandlerMap = options.diffHandlerMap or {}
        animations = []
        dirty = false
        attrsChanges = splitDiff(diff)
        for [attrName, attrDiff] in attrsChanges
            handler = diffHandlerMap[attrName] or diffHandlerMap['*']
            handlerAnimations = handler?(attrName, attrDiff, viewSelector, options)
            if handlerAnimations?
                # custom handling
                animations.push(handlerAnimations...)
            else
                # generate fallback animations
                dirty = true
                for operation in attrDiff
                    applicatorGetter = getViewApplicatorGetter(attrName, operation, viewSelector)
                    opts =
                        forceStep: forceStep
                        helpers: options.helpers
                    appliedInterpolator = getViewAppliedInterpolator(attrName, operation, viewSelector, opts)
                    startCallback = getAnimationStartCallback(attrName, operation, viewSelector, opts)
                    endCallback = getAnimationEndCallback(attrName, operation, viewSelector, opts)
                    if applicatorGetter? and appliedInterpolator?
                        anim = new Animation
                            applicatorGetter: applicatorGetter
                            appliedInterpolator: appliedInterpolator
                            startCallback: startCallback
                            endCallback: endCallback
                            debugInfo:
                                operation: operation
                    else
                        # no application getter and applied interpolator
                        # available - we do not know how to animate, therefore
                        # we generate only an "degenerated" animation, which
                        # leaves the view/model in proper state.
                        anim = new Animation
                            transitionsEnabled: false
                            startCallback: startCallback
                            endCallback: endCallback
                            debugInfo:
                                operation: operation
                    animations.push(anim)
        if dirty and callRender
            # adds special animation which causes the view to be redrawn.
            # this is useful, because the result of getAnimations is usually
            # grouped in a ParallelAnimation object, so .setup(), .update()
            # and .teardown() of this animation will be executed at the end of
            # ParallelAnimation .setup(), .update() etc.
            anim = new Animation
                transitionsEnabled: _.any(animations, (anim) -> anim.transitionsEnabled)
                startCallback: (t) -> viewSelector().render()
                update: (t) -> viewSelector().render()
                endCallback: -> viewSelector().render()
                debugInfo:
                    text: 'render animation'
            animations.push(anim)
        animations


    getTextAnimation = (op, viewSelector, options={}) ->

        applicatorGetter = ->
            attrName = op.getLastContextName()
            (value) ->
                viewSelector().model.set(attrName, value)
                viewSelector().render()

        new StateAnimation
            states: op.getStoredStates()
            applicatorGetter: applicatorGetter
            startCallback: (t) -> viewSelector().render()
            endCallback: -> viewSelector().render()
            debugInfo:
                operation: op


    module.exports =
        getViewChangeCallback: getViewChangeCallback
        getAnimations: getAnimations
        getTextAnimation: getTextAnimation
