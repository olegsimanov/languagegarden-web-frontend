    'use strict'

    settings = require('./../../settings')
    {BaseModel} = require('./base')


    class Settings extends BaseModel

        defaults:
            fontSize: settings.defaultFontSize

        @getSettings = (name) => new Settings(id: name)


    module.exports =
        Settings: Settings
