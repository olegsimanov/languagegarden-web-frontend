    'use strict'

    _ = require('underscore')
    settings = require('./../../settings')
    utils = require('.')
    domutils = require('./../domutils')


    {template} = domutils
    {pathJoin} = utils
    {staticUrl, isMobile} = settings

    ejs_templates =
        editor:
            always: [
                'ejs/common/page/main.ejs'
                'ejs/editor/colorpicker/main.ejs'
            ],
            desktop: [
                'ejs/editor/images/main.ejs'
                'ejs/editor/images/panels/url.ejs'
                'ejs/editor/media/library/edit.ejs'
                'ejs/editor/media/library/main.ejs'
                'ejs/editor/media/library/modal.ejs'
                'ejs/editor/media/library/search.ejs'
                'ejs/editor/media/library/search_item.ejs'
                'ejs/editor/media/library/upload.ejs'
                'ejs/editor/media/panels/upload.ejs'
                'ejs/editor/media/uploader.ejs'
                'ejs/editor/plantlinks/library/edit.ejs'
                'ejs/editor/plants/library/search_item.ejs'
                'ejs/editor/settings/main.ejs'
                'ejs/editor/settings/modal.ejs'
                'ejs/editor/settings/panels/color_palette.ejs'
                'ejs/editor/settings/panels/color_palette_row.ejs'
                'ejs/editor/settings/panels/font.ejs'
                'ejs/editor/settings/panels/notes.ejs'
                'ejs/editor/settings/panels/plant_details.ejs'
                'ejs/editor/sounds/panels/urls.ejs'
            ],
            mobile: []

        player:
            always: [
                'ejs/common/page/main.ejs'
            ],
            desktop: [],
            mobile: [],

        plant_list:
            always: [
                'ejs/common/page/list.ejs'
                'ejs/list/grouped_plant.ejs'
            ],
            desktop: [],
            mobile: [],

        demo:
            always: [
                'ejs/common/page/main.ejs'
                'ejs/common/page/demo/welcome.ejs'
                'ejs/common/page/deom/summary.ejs'
            ],
            desktop: [],
            mobile: [],

    ###Wrap original template.fetchTemplate adding _prefetchTemplateCache.###
    wrapFetchTemplate = ->
        # if already wrapped - exit
        if template._prefetchTemplateCache?
            return
        orig = template.fetchTemplate
        template._prefetchTemplateCache = {}
        template.fetchTemplate = (templateUrl) ->
            # check if the template was already preloaded, if so return it
            tmpl = template._prefetchTemplateCache[templateUrl]
            if tmpl?
                tmpl
            else
                # fallback
                orig(templateUrl)

    preloadTemplatePack = (module, onFinish) ->
        kind = if isMobile then 'mobile' else 'desktop'
        paths = ejs_templates[module]['always'].concat(
            ejs_templates[module][kind]
        )
        preloadTemplates(paths, onFinish)

    preloadTemplates = (paths, onFinish) ->
        #TODO: remove this function after we implement inline templates
        onFinish()


    module.exports =
        ejs_templates: ejs_templates
        preloadTemplatePack: preloadTemplatePack
