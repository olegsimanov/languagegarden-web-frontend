    'use strict'

    Backbone = require('backbone')
    settings = require('./../../settings')
    require('backbone.localStorage')
    {BaseModel} = require('./base')
    {TextSize} = require('./../constants')


    class Settings extends BaseModel

        defaults:
            fontSize: settings.defaultFontSize
            textSize: TextSize.DEFAULT

        constructor: ->
            super
            @localStorage = new Backbone.LocalStorage("settings")

        @getSettings = (name) =>
            settings = new Settings(id: name)
            # on error we use the defaults
            # settings are only saved once modified
            settings.fetch(async: false)
            settings

    module.exports =
        Settings: Settings
