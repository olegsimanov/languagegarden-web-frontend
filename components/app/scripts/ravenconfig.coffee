Raven = require('raven-js')
settings = require('./languagegarden/settings')


if settings?.sentry?.publicDSN?
    Raven.config(settings.sentry.publicDSN).install()
else
    console.warn('Raven.js is not configured!')
