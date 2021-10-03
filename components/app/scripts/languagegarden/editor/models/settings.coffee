    'use strict'

    settings = require('./../../settings')
    {BaseModel} = require('./base')
    {TextSize} = require('./../constants')


    class Settings extends BaseModel

        defaults:
            fontSize: settings.defaultFontSize
            textSize: TextSize.DEFAULT

        constructor: ->
            super

        @getSettings = (name) =>
            settings = new Settings(id: name)
            settings

    module.exports =
        Settings: Settings
