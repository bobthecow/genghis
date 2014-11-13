var webpack = require('webpack');

module.exports = {
  module: {
    loaders: [
      {test: /\.coffee$/,   loader: 'coffee-loader'},
      {test: /\.mustache$/, loader: 'mustache'}
    ]
  },

  plugins: [
    new webpack.ResolverPlugin(
      new webpack.ResolverPlugin.DirectoryDescriptionFilePlugin('bower.json', ['main'])
    )
  ],

  resolve: {
    root: __dirname + '/client/vendor',
    extensions: ['', '.coffee', '.js']
  }
};
