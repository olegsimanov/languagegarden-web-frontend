    'use strict'

    settings = require('./../../settings')
    {BaseModel} = require('./base')
    {TextSize} = require('./../../common/constants')


    class Settings extends BaseModel

        defaults:
            fontSize: settings.defaultFontSize
            textSize: TextSize.DEFAULT

        constructor: ->
            super

        @getSettings = (name) =>
            settings = new Settings(id: name)
            # on error we use the defaults
            # settings are only saved once modified
#            settings.fetch(async: false)
            settings

    module.exports =
        Settings: Settings
