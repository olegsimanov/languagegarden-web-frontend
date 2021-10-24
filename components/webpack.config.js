(function () {
    'use strict';

    var webpack             = require('webpack');
    var path                = require('path');
    var ExtractTextPlugin   = require('extract-text-webpack-plugin');

    var srcScriptsDir       = path.join(__dirname, 'app', 'scripts');
    var targetDir           = path.join(__dirname, 'build');                // was 'dist' in case of non-development environment (please check history)
    var bowerComponentsDir  = path.join(__dirname, 'bower_components');

    module.exports = {
        context: path.join(__dirname, 'app'),
        entry: {
            'starter': path.join(srcScriptsDir, 'languagegarden', 'starter.coffee')
        },
        output: {
            path:                 targetDir,
            filename:             path.join('js', 'lg-[name].js'),
            chunkFilename:        path.join('js', '[hash]', 'lg-chunk-[id].js'),
            namedChunkFilename:   path.join('js', '[hash]', 'lg-chunk-[name].js'),
            publicPath:           '/static/'
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
                __DEV__:                'development',
                __SENTRY_PUBLIC_DSN__:  null
            }),
            new ExtractTextPlugin('lg-[name].css'),
            new webpack.ProvidePlugin({
                _:          'underscore',
                jQuery:     'jquery',
                Backbone:   'backbone'
            }),
            new webpack.ResolverPlugin(new webpack.ResolverPlugin.DirectoryDescriptionFilePlugin('bower.json', ['main'])
            )
        ],
        resolve: {
            root: [
                bowerComponentsDir,
            ],
            extensions: ['', '.js', '.coffee', '.json']
        }
    };
}).call(this);
