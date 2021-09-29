preloadAll = (settings, preload) ->
      core_images = [

            # tooltip
            ## modes
            'img/3/LG_icon_move.png'
            'img/3/LG_icon_move_2.png'
            'img/3/LG_icon_rotate.png'
            'img/3/LG_icon_rotate_2.png'
            'img/3/LG_icon_scale.png'
            'img/3/LG_icon_scale_2.png'
            'img/3/LG_icon_stretch.png'
            'img/3/LG_icon_stretch_2.png'

            # buttons
            'img/3/lg_undo1.png'
            'img/3/lg_undo2.png'
            'img/3/lg_undo3.png'
            'img/3/lg_redo1.png'
            'img/3/lg_redo2.png'
            'img/3/lg_redo3.png'

      ]

      desktop_images = [

            # menu slider
            'lib/jquery-ui-1.10.1.custom/css/smoothness/images/ui-bg_flat_75_ffffff_40x100.png'
            'lib/jquery-ui-1.10.1.custom/css/smoothness/images/ui-bg_glass_75_e6e6e6_1x400.png'
            'lib/jquery-ui-1.10.1.custom/css/smoothness/images/ui-bg_glass_75_dadada_1x400.png'
            'lib/jquery-ui-1.10.1.custom/css/smoothness/images/ui-bg_glass_65_ffffff_1x400.png'

            # palette editor
            'img/glyphicons-halflings.png'
            'img/glyphicons-halflings-white.png'
            'lib/bootstrap-editable/img/clear.png'
            'lib/bootstrap-editable/img/loading.gif'
      ]

      images = core_images

      if not settings.isMobile
            images.concat(desktop_images)

      preload images,
            staticUrl: settings.staticUrl
            delay: 200

$ ->
      modular.require
            dependencies: [
                  'languagegarden.settings'
                  ['languagegarden.common.domutils', ['preload']]
            ]
            callback: preloadAll
