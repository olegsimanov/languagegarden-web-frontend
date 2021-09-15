(function () {
    'use strict';

    var webpackConfig = require('./webpack-instance-config');

    var webpack = require('webpack');
    var path = require('path');
    var ExtractTextPlugin = require('extract-text-webpack-plugin');

    var srcScriptsDir = path.join(__dirname, 'app', 'scripts');
    var targetDir = path.join(__dirname, 'build');
    var bowerComponentsDir = path.join(__dirname, 'bower_components');

    var buildType;
    var developmentVersion;
    var sentryPublicDSN = null;

    buildType = process.env.BUILD_TYPE || 'development';
    developmentVersion = buildType === 'development';
    if (webpackConfig.sentry && webpackConfig.sentry.publicDSN) {
        sentryPublicDSN = webpackConfig.sentry.publicDSN;
    }

    if (!developmentVersion) {
        targetDir = path.join(__dirname, 'dist');
    }

    module.exports = {
        context: path.join(__dirname, 'app'),
        entry: {
            'starter': path.join(srcScriptsDir, 'languagegarden', 'starter.coffee')
        },
        output: {
            path: targetDir,
            filename: path.join('js', 'lg-[name].js'),
            chunkFilename: path.join('js', '[hash]', 'lg-chunk-[id].js'),
            namedChunkFilename: path.join('js', '[hash]', 'lg-chunk-[name].js'),
            publicPath: webpackConfig.output.publicPath || ''
        },
        module: {
            loaders: [
                {
                    test: /\.css$/,
                    loader: ExtractTextPlugin.extract('style-loader', 'css-loader')
                },
                {
                    test: /\.less$/,
                    loader: ExtractTextPlugin.extract('style-loader', 'css-loader!less-loader')
                },
                {
                    test: /\.ejs$/,
                    loader: 'ejs-loader'
                },
                {
                    test: /\.coffee$/,
                    loader: 'coffee-loader'
                },
                {
                    test: /\.(png|jpg|gif|cur|svg)$/,
                    loader: 'file-loader'
                }
            ]
        },
        plugins: [
            new webpack.DefinePlugin({
                __DEV__: developmentVersion,
                __SENTRY_PUBLIC_DSN__: JSON.stringify(sentryPublicDSN)
            }),
            //new webpack.optimize.CommonsChunkPlugin('common.js'),
            // TODO: use the css/ path when the relative file path problem
            // (url(...)) will be resolved.
            new ExtractTextPlugin('lg-[name].css'),
            new webpack.ProvidePlugin({
                _: 'underscore',
                jQuery: 'jquery',
                Backbone: 'backbone'
            }),
            new webpack.ResolverPlugin(new webpack.ResolverPlugin.DirectoryDescriptionFilePlugin('bower.json', ['main'])
            )
        ],
        resolve: {
            root: [
                bowerComponentsDir,

                path.join(bowerComponentsDir, 'bootstrap-modal', 'js'),
                path.join(bowerComponentsDir, 'bootstrap', 'js'),
                path.join(bowerComponentsDir, 'brandimint-xediatable-bootstrap', 'js'),

                path.join(bowerComponentsDir, 'backbone.localstorage'),
                path.join(bowerComponentsDir, 'backbone.bootstrap-modal', 'src'),

                path.join(bowerComponentsDir, 'jquery.cookie'),
                path.join(bowerComponentsDir, 'jquery-simplecolorpicker'),
                path.join(bowerComponentsDir, 'jquery-ui', 'ui'),

                path.join(bowerComponentsDir, 'jscrollpane', 'script'),

                path.join(bowerComponentsDir, 'swfobject-amd'),               // could be removed

            ],
            extensions: ['', '.js', '.coffee', '.json']
        }
    };
}).call(this);
