apiBaseUrl = '/api/v2/'

publicDSN = null
if __SENTRY_PUBLIC_DSN__?
    publicDSN = __SENTRY_PUBLIC_DSN__

settings =
    debug:
        showCircles: true
        showPath: true
        showLinesInStretch: false
        checkCoordinateLog: false
        printLetterMetrics: false
        debugControls: false
        enabled: false
        wrapInDiv: true

    # Font size can be selected per word
    # It's probably the only working way to resize invidual letters
    # Min font size must be used to ensure the letters are draggable
    defaultFontSize: 50
    minFontSize: 30
    maxFontSize: 250

    minScale: 0.5
    maxScale: 5

    # this constant was chosen empirically and may depend on element font
    fontSizeToLetterHeightMultiplier: 1.11

    staticUrl: 'missing-static-url',

    hammerEvents: true
    splitColor: true

    apiResourceNames:
        'lessons': "lessons"

    sentry:
        publicDSN: publicDSN


module.exports = settings
