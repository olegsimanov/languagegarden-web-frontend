    'use strict'

    _ = require('underscore')
    $ = require('jquery')
    {Point} = require('./points')


    class BBox

        constructor: (@leftTop, @rightBottom) ->

        getWidth: -> @rightBottom.x - @leftTop.x

        getHeight: -> @rightBottom.y - @leftTop.y

        getLeft: -> @leftTop.x

        getTop: -> @leftTop.y

        getRight: -> @rightBottom.x

        getBottom: -> @rightBottom.y

        getLeftTop: -> @leftTop.copy()

        getRightTop: -> new Point(@rightBottom.x, @leftTop.y)

        getLeftBottom: -> new Point(@leftTop.x, @rightBottom.y)

        getRightBottom: -> @rightBottom.copy()

        getCenterPoint: -> new Point(
                @getLeft() + @getWidth() / 2
                @getTop() + @getHeight() / 2
            )

        equals: (b) -> b? and @leftTop.equals(b.leftTop) and @rightBottom.equals(b.rightBottom)

        toString: -> "BBox(#{@getLeft()}, #{@getTop()}, #{@getWidth()}, #{@getHeight()})"

        copy: -> new BBox(@leftTop.copy(), @rightBottom.copy())

        getBoundaryPoints: ->
            [@getLeftTop(), @getRightTop(),
             @getLeftBottom(), @getRightBottom()]

        intersects: (bbox) ->
            (bbox.leftTop.x < @rightBottom.x and
             @leftTop.x < bbox.rightBottom.x and
             bbox.leftTop.y < @rightBottom.y and
             @leftTop.y < bbox.rightBottom.y)

        getTranslated: (vector) -> @copy().translate(vector)

        isEmpty: -> @getWidth() == 0 or @getHeight() == 0

        containsCoordinates: (x, y) ->
            @leftTop.x < x < @rightBottom.x and @leftTop.y < y < @rightBottom.y

        containsPoint: (point) -> @containsCoordinates(point.x, point.y)

        containsPoints: (points) -> _.all(points, @containsPoint, this)

        containsBBox: (bbox) ->
            @containsPoint(bbox.leftTop) && @containsPoint(bbox.rightBottom)

        nearestCoordinatesInside: (x, y, margin=1) =>
            x = @leftTop.x + margin if x < @leftTop.x + margin
            y = @leftTop.y + margin if y < @leftTop.y + margin
            x = @rightBottom.x - margin if @rightBottom.x < x - margin
            y = @rightBottom.y - margin if @rightBottom.y < y - margin
            [x, y]

        applyToPoints: (applicator) ->
            applicator(@leftTop)
            applicator(@rightBottom)
            this

        translate: (vector) -> @applyToPoints((p) -> p.addToSelf(vector))

        scale: (vector) -> @applyToPoints((p) -> p.vecMulSelf(vector))

        @newEmpty = => new this(new Point(), new Point())

        @fromSVGRect = (rect) => new this(new Point(rect.x, rect.y), new Point(rect.x + rect.width, rect.y + rect.height))

        @fromClientRect = (rect) => new this(new Point(rect.left, rect.top), new Point(rect.right, rect.bottom))

        @fromCoordinates = (x1, y1, x2, y2) => new this(new Point(x1, y1), new Point(x2, y2))

        @fromXYWH = (x, y, width, height) => new this(new Point(x, y), new Point(x + width, y + height))

        @fromCenterPoint = (centerPoint, devPoint) => new this(centerPoint.add(devPoint.neg()), centerPoint.add(devPoint))

        @fromPointList = (l) =>
            if l.length == 0
                @newEmpty()
            else
                xlist = []
                ylist = []
                for p in l
                    xlist.push(p.x)
                    ylist.push(p.y)
                @fromCoordinates(_.min(xlist), _.min(ylist),
                                 _.max(xlist), _.max(ylist))

        @fromBBoxList = (l) =>
            leftList = []
            topList = []
            rightList = []
            bottomList = []
            for bbox in l
                if bbox.isEmpty()
                    continue
                leftList.push(bbox.getLeft())
                topList.push(bbox.getTop())
                rightList.push(bbox.getRight())
                bottomList.push(bbox.getBottom())
            if leftList.length == 0
                @newEmpty()
            else
                @fromCoordinates(_.min(leftList), _.min(topList),
                                 _.max(rightList), _.max(bottomList))

        @fromHtmlDOM = (el, absolute=false) =>
            el = $(el) if _.isString(el)
            if absolute
                @fromXYWH(0, 0, el.width(), el.height())
            else
                @fromClientRect(el[0].getBoundingClientRect(el))

    module.exports =
        BBox: BBox
