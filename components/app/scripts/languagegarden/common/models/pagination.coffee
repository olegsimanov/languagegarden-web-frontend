    'use strict'

    _ = require('underscore')
    $ = require('jquery')
    {getValue} = require('./../utils')
    {BaseCollection} = require('./base')


    class PaginatedCollection extends BaseCollection

        page: 0
        limit: 20
        query: ''

        initialize: (items, options) =>
            @setPaginatedArgs(options)
            super

        setPaginatedArgs: (options) =>
            @page = options.page if options?.page?
            @limit = options.limit if options?.limit?
            @query = options.query if options?.query? and options.query
            if options?.filters?
                @filters = options.filters

        url: =>
            params =
                page: this.page + 1
                page_size: this.limit
            params.q = @query if @query
            _.extend(params, @filters or {})
            getValue(this.urlRoot) + '?' + $.param(params, true)

        fetch: (options={}) =>

            @setPaginatedArgs(options)

            @trigger('reset:begin')

            success = options?.success

            options.success = (resp) =>
                @trigger('reset:success')
                success.call(@, resp) if success?

            error = options?.error

            options.error = (resp) =>
                @trigger('reset:error')
                error.call(@, resp) if error?

            super(options)

        parse: (result) ->
            if _.isArray(result)
                return result

            if _.has(result, 'results')
                return result.results

            if _.has(result, 'objects')
                return result.objects

            console.error('unrecoginized data')
            return null

        hasPrev: => @page > 0
        hasNext: => @length == @limit

        nextPage: =>
            if @hasNext()
                @page += 1
                @fetch()

        prevPage: =>
            if @hasPrev()
                @page -= 1
                @fetch()

        search: (query) =>
            @query = query
            @page = 0
            @fetch()

        ##Index of the first item on the page.###
        firstPageItemIndex: =>
            if @length == 0 then 0 else @page * @limit

        ##Index of the last item on the page.###
        lastPageItemIndex: =>
            if @length == 0 then 0 else @page * @limit + @length - 1


    module.exports =
        PaginatedCollection: PaginatedCollection
