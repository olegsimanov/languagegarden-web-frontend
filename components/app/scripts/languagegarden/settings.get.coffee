query = window.location.search.replace('?', '')
paramStrings = query.split('&')

for s in paramStrings
    if s.indexOf('bg=') == 0
        @languagegarden.settings.backgroundColor = (parseInt(s.substr(3), 10))
        break

if 'debugControls=1' in paramStrings
    @languagegarden.settings.debug.debugControls = true

if 'debug=1' in paramStrings
    @languagegarden.settings.debug.enabled = true

if 'disableConfirm=1' in paramStrings
    @languagegarden.settings.debug.disableConfirm = true

if 'splitColor=1' in paramStrings
    @languagegarden.settings.splitColor = true

if 'splitColor=0' in paramStrings
    @languagegarden.settings.splitColor = false

if 'wrapInDiv=0' in paramStrings
    @languagegarden.settings.debug.wrapInDiv = false

if 'wrapInDiv=1' in paramStrings
    @languagegarden.settings.debug.wrapInDiv = true

if 'playPlant=1' in paramStrings
    @languagegarden.settings.playPlant = true

if 'showSearchLoader=1' in paramStrings
    @languagegarden.settings.showSearchLoader = true

if 'preloadTemplates=1' in paramStrings
    @languagegarden.settings.preloadTemplates = true

if 'logMetrics=1' in paramStrings
    @languagegarden.settings.logMetrics = true
