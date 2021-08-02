'use strict'

_ = require('underscore')
$ = require('jquery')
settings = require('./../settings')
utils = require('./utils')


class TemplateObject

    constructor: (@templateFunction) ->

    render: (ctx={}) =>
        ctx = _.extend {
            utils: utils
            settings: settings
            '$': $
            '_': _
        }, ctx
        @templateFunction(ctx)


templateWrapper = (templateFunction) ->
    new TemplateObject(templateFunction)


templateContext = require.context('./../../../templates/', true, /^.*\.ejs$/);


template = (name) ->
    templateWrapper(templateContext(name))


module.exports =
    template: template
    templateWrapper: templateWrapper
