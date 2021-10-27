    'use strict'

    Backbone    = require('backbone')
    settings    = require('./../../settings')


    class Settings extends Backbone.Model

        defaults:
            fontSize: settings.defaultFontSize

        @getSettings = (name) => new Settings(id: name)


    module.exports =
        Settings: Settings
