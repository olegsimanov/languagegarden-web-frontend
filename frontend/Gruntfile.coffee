'use strict'

path = require('path')
proxySnippet = require('grunt-connect-proxy/lib/utils').proxyRequest;
rewriteRulesSnippet = require('grunt-connect-rewrite/lib/utils').rewriteRequest;
mountFolder = (connect, dir) -> connect.static(require('path').resolve(dir))

try gruntConfig = require('./GruntConfig.coffee')

module.exports = (grunt) ->
  require('load-grunt-tasks')(grunt);
  require('time-grunt')(grunt);
  grunt.initConfig
    yeoman:
      app: require('./bower.json').appPath || 'app'
      dist: 'dist'
      tmp: '.tmp'

    watch:
      coffee:
        files: ['<%= yeoman.app %>/scripts/**/*.coffee']
        tasks: ['newer:coffee:dist']
      #coffeeTest:
      #  files: ['test/spec/{,*/}*.{coffee,litcoffee,coffee.md}']
      #  tasks: ['newer:coffee:test', 'karma']
      livereload:
        options:
          livereload: '<%= connect.options.livereload %>'
        files: [
          '<%= yeoman.app %>/{,*/}*.html',
          '<%= yeoman.tmp %>/css/{,*/}*.css',
          '<%= yeoman.tmp %>/scripts/{,*/}*.js',
          '<%= yeoman.app %>/img/{,*/}*.{png,jpg,jpeg,gif,webp,svg}',
        ]
      less:
        tasks: ['less:dist']
        files: ['<%= yeoman.app %>/less/**/*.less']
      wiredep:
        files: 'bower.json'
        tasks: 'wiredep'

    connect:
      options:
        port: 9000
        hostname: gruntConfig?.connect?.host or '0.0.0.0'
        livereload: 35729
      proxies: [
        context: ['/admin', '/api', '/static', '/api-auth', '/api-docs', '/player'],
        host: gruntConfig?.connect?.proxy_host or '127.0.0.1',
        port: gruntConfig?.connect?.proxy_port or 8000
      ]
      rules: [
        from: '^\/(?!(bower_components|views|css|img|other-js|scripts|lib|fonts)).*',
        to: '/'
      ]
      livereload:
        options:
          open: false
          base: [
            '<%= yeoman.tmp %>',
            '<%= yeoman.app %>'
          ]
          middleware: (connect) ->
            [
              proxySnippet,
              rewriteRulesSnippet,
              mountFolder(connect, '.tmp'),
              mountFolder(connect, 'app'),
            ]
      #test:
      #  options:
      #    port: 9001
      #    base: [
      #      '<%= yeoman.tmp %>',
      #      'test',
      #      '<%= yeoman.app %>'
      #    ]
      #    middleware: (connect) ->
      #      [
      #        proxySnippet,
      #        rewriteRulesSnippet,
      #        mountFolder(connect, '.tmp'),
      #        mountFolder(connect, 'app'),
      #      ]
      dist:
        options:
          base: '<%= yeoman.dist %>'
          open: false
          middleware: (connect) ->
            [
              proxySnippet
              rewriteRulesSnippet
              mountFolder(connect, 'dist')
            ]

    clean:
      dist:
        files: [
          dot: true
          src: [
            '<%= yeoman.tmp %>',
            '<%= yeoman.dist %>/*',
            '!<%= yeoman.dist %>/.git*'
          ]
        ]
      server: '<%= yeoman.tmp %>'

    coffee:
      options:
        sourceMap: true
        sourceRoot: ''
      dist:
        files: [
          expand: true
          cwd: '<%= yeoman.app %>/scripts'
          src: '**/*.coffee'
          dest: '<%= yeoman.tmp %>/scripts'
          ext: '.js'
        ]
      #test:
      #  files: [
      #    expand: true
      #    cwd: 'test/e2e'
      #    src: '{,*/}*.coffee'
      #    dest: '<%= yeoman.tmp %>/e2e'
      #    ext: '.js'
      #  ]

    less:
      dist:
        expand: true
        cwd: '<%= yeoman.app %>/less'
        src: '*.less'
        dest: '<%= yeoman.tmp %>/css'
        ext: '.css'

    cssmin:
      minify:
        expand: true
        cwd: '<%= yeoman.dist %>/css'
        src: '*.css'
        dest: '<%= yeoman.dist %>/css'
        ext: '.css'

    rev:
      dist:
        files:
          src: [
            '<%= yeoman.dist %>/scripts/**/*.js',
            '<%= yeoman.dist %>/css/**/*.css',
            '<%= yeoman.dist %>/bower_components/**/*.{png,jpg,jpeg,gif,webp,svg,woff}',
            '<%= yeoman.dist %>/img/{,*/}*.{png,jpg,jpeg,gif,webp}',
            '<%= yeoman.dist %>/views/**/*.html'
          ]

    useminPrepare:
      html: ['<%= yeoman.app %>/index.html', '<%= yeoman.app %>/views/layout/*.html']
      options:
        dest: '<%= yeoman.dist %>'

    usemin:
      html: ['<%= yeoman.dist %>/**/*.html']
      css: ['<%= yeoman.dist %>/css/**/*.css', '<%= yeoman.dist %>/index.html']
      js: ['<%= yeoman.dist %>/scripts/**/*.js']
      angular: ['<%= yeoman.dist %>/**/*.html']
      options:
        assetsDirs: ['<%= yeoman.dist %>/**',]
        patterns:
            js: [[/\"\/(views.+?\.html)\"/g, 'Replacing template']]
            angular: [[/(views.*\.html)/g, 'Replacing template']]

    htmlmin:
      dist:
        options:
          collapseWhitespace: true
          collapseBooleanAttributes: true
          removeCommentsFromCDATA: true
          removeOptionalTags: true
        files: [
          expand: true,
          cwd: '<%= yeoman.dist %>'
          src: ['*.html', 'views/**/*.html']
          dest: '<%= yeoman.dist %>'
        ]

    ngmin:
      dist:
        files: [
          expand: true
          cwd: '<%= yeoman.tmp %>/concat/scripts'
          src: '*.js'
          dest: '<%= yeoman.tmp %>/concat/scripts'
        ]

    uglify:
      options:
        mangle: false

    copy:
      dist:
        files: [
          expand: true
          dot: true
          cwd: '<%= yeoman.app %>'
          dest: '<%= yeoman.dist %>'
          src: [
            '*.{ico,png,txt}',
            '*.html',
            'views/**/*.html',
            'other-js/bootstrap-filestyle.js',
            'img/{,*/}*.{png,jpg,jpeg,gif,webp,svg,eot,ttf,woff}'
          ]
        ,
          # Copy Bootstrap Fonts
          expand: true
          cwd: '<%= yeoman.app %>/lib/bootstrap.custom-build/fonts'
          dest: '<%= yeoman.dist %>/fonts'
          src: '*'
        ,
          expand: true
          cwd: '<%= yeoman.tmp %>/img'
          dest: '<%= yeoman.dist %>/img'
          src: ['generated/*']
        ,
          expand: true
          cwd: '<%= yeoman.tmp %>/css'
          dest: '<%= yeoman.dist %>/css'
          src: '*.css'
        ]

    concurrent:
      options:
        spawn: false
      server: [
        'coffee:dist',
      ]
      #test: [
      #  'coffee',
      #]
      dist: [
        'coffee',
      ]

    wiredep:
      target:
        src: ['<%= yeoman.app %>/index.html']
        fileTypes:
          html:
            replace:
              js: '<script src="/{{filePath}}"></script>'


  grunt.registerTask 'serve', (target) ->
    if target is 'dist'
      return grunt.task.run [
        'build',
        'configureProxies',
        'configureRewriteRules',
        'connect:dist:keepalive'
      ]

    grunt.task.run [
      'clean:server',
      'wiredep',
      'less',
      'components-build-dev',
      'concurrent:server',
      'configureProxies',
      'configureRewriteRules',
      'connect:livereload',
      'watch'
    ]

  #grunt.registerTask 'test', [
  #  'configureProxies',
  #  'configureRewriteRules',
  #  'connect:test',
  #]

  grunt.registerTask 'build', [
    'clean:dist',
    'wiredep',
    'less',
    'components-build',
    'useminPrepare',
    'concurrent:dist',
    'concat',
    'ngmin',
    'copy:dist',
    'cssmin',
    'uglify',
    'rev',
    'usemin',
    'htmlmin'
  ]

  for _taskName in ['build-dev', 'build']
    do ->
      taskName = _taskName
      grunt.registerTask "components-#{taskName}", ->
        done = @async()
        grunt.util.spawn
          grunt: true
          args: [taskName]
          opts:
            cwd: path.join(__dirname, '..', 'components')
        , ((err, result, code) -> done())
