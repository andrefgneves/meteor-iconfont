Package.describe({
  summary: 'Generate an icon font from SVG files',
  version: '0.1.0'
});

Package._transitional_registerBuildPlugin({
  name: 'iconfont',
  use: [],
  sources: [
    'plugin/iconfont.js'
  ],
  npmDependencies: {
    'svg2ttf': '1.1.2',
    'svgicons2svgfont': '0.0.11',
    'ttf2eot': '1.3.0',
    'ttf2woff': '1.2.0',
    'lodash': '2.4.1',
    'multi-glob': '0.4.0',
    'temp': '0.7.0',
    'fs-extra': '0.8.1'
  }
});

Package.on_test(function (api) {
  api.use('iconfont');
  api.use('tinytest');

  api.add_files('iconfont_tests.js');
});

