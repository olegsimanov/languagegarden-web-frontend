'use strict'

path = require('path')
_ = require('underscore')
webpack = require("webpack")
webpackConfig = require("./webpack.config.js")
webpackInstanceConfig = require("./webpack-instance-config.js")

module.exports = (grunt) ->
    require("matchdep").filterAll("grunt-*").forEach(grunt.loadNpmTasks)
    grunt.initConfig
        aws: grunt.file.readJSON('aws-keys.json'),

        webpack:
            options: webpackConfig,
            dist:
                plugins: webpackConfig.plugins.concat(
                    new webpack.DefinePlugin
                        "process.env":
                            # This has effect on the react lib size
                            "NODE_ENV": JSON.stringify("production")
                    new webpack.optimize.DedupePlugin()
                    new webpack.optimize.UglifyJsPlugin()
                ),
                output: _.extend({}, webpackConfig.output, {
                    path: path.join(__dirname, 'dist')
                })
            build:
                devtool: "sourcemap"
                debug: true
        "webpack-dev-server":
            options:
                webpack: webpackConfig,
                publicPath: "/" + webpackConfig.output.publicPath
                contentBase: __dirname + '/app'
            start:
                keepAlive: true
                webpack:
                    devtool: "eval"
                    debug: true
        watch:
            app:
                files: ["app/**/*", "web_modules/**/*"]
                tasks: ["webpack:build-dev"]
                options:
                    spawn: false

        aws_s3:
            options:
                accessKeyId: '<%= aws.accessKeyId %>'
                secretAccessKey: '<%= aws.secretAccessKey %>'
                bucket: webpackInstanceConfig.s3?.componentsBucket
            deploy:
                options:
                    differential: true

                files: [
                    expand: true
                    cwd: 'dist/'
                    src: ['**']
                    dest: ''
                ]

    # The development server (the recommended option for development)
    grunt.registerTask("default", ["webpack-dev-server:start"]);

    # Build and watch cycle (another option for development)
    # Advantage: No server required, can run app from filesystem
    # Disadvantage: Requests are not blocked until bundle is available,
    # can serve an old app on too fast refresh
    grunt.registerTask('serve', ['webpack:build', 'watch:app']);

    grunt.registerTask('build-dev', ['webpack:build']);

    # Production build
    grunt.registerTask("build", ['webpack:dist']);

    # Production deploy
    grunt.registerTask('deploy', ['webpack:dist', 'aws_s3:deploy']);
