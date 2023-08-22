const { name } = require('./package');

module.exports = {
  webpack: function (config, env) {
    const library = config.output.library || {}
    library.name=`${name}-[name]`
    library.type='umd'
    config.output.library = library
    config.output.chunkLoadingGlobal =`webpackJsonp_${name}`
    config.output.globalObject = 'window';

    return config
  },
  devServer: function (configFunction) {
    return function(proxy, allowedHost) {
      // Create the default config by calling configFunction with the proxy/allowedHost parameters
      const config = configFunction(proxy, allowedHost);
      config.headers = {
        'Access-Control-Allow-Origin': '*',
      };
      config.historyApiFallback = true;
      // config.hot = false;
      // config.watchContentBase = false;
      config.static.watch = false;
      config.liveReload = false;

      // Return your customised Webpack Development Server config.
      return config;
    };
  }
}

