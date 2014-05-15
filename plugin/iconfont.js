var _ = Npm.require('lodash');
var fs = Npm.require('fs-extra');
var glob = Npm.require('multi-glob');
var path = Npm.require('path');
var temp = Npm.require('temp').track();
var svg2ttf = Npm.require('svg2ttf');
var ttf2eot = Npm.require('ttf2eot');
var ttf2woff = Npm.require('ttf2woff');
var svgicons2svgfont = Npm.require('svgicons2svgfont');

Plugin.registerSourceHandler('iconfont.json', function (compileStep) {
  if (! compileStep.archMatches('browser'))
    return;

  return handler(compileStep);
});

var handler = function (compileStep) {
  var optionsFile = path.join(process.cwd(), compileStep.inputPath);
  var options = {};

  if (fs.existsSync(optionsFile))
    options = loadJSONFile(optionsFile);

  options = _.extend({
    src: 'svgs',
    dest: 'public/fonts/icons',
    fontFaceBaseURL: '/fonts/icons',
    fontName: 'icons',
    fontHeight: 512,
    descent: 64,
    normalize: true,
    types: [
      'svg',
      'ttf',
      'eot',
      'woff'
    ],
    stylesheetTemplatePath: 'packages/iconfont/plugin/stylesheet.tpl'
  }, options);

  if (! options.types || ! options.types.length) {
    return;
  }

  options.files = getFiles(options.src);
  options.fontFaceURLS = {};
  options.types = _.map(options.types, function (type) {
    return type.toLowerCase();
  });

  generateFonts(compileStep, options);
};

var generateFonts = function (compileStep, options) {
  // Always generate the SVG font as it is required to generate the TTF,
  // which in turn is used to generate the EOT and WOFF
  generateSVGFont(options.files, options, function (svgFontPath) {
    if (_.intersection(options.types, ['ttf', 'eot', 'woff']).length) {
      generateTTFFont(svgFontPath, options, function (ttfFontPath) {
        if (_.contains(options.types, 'eot')) {
          generateEOTFont(ttfFontPath, options);
        }

        if (_.contains(options.types, 'woff')) {
          generateWoffFont(ttfFontPath, options);
        }
      });
    }

    generateStylesheet(compileStep, options);
  });
};

var generateSVGFont = function (files, options, done) {
  var codepoint = 0xE001;
  options.glyphs = _.compact(_.map(files, function (file) {
    var matches = file.match(/^(?:u([0-9a-f]{4})\-)?(.*).svg$/i);

    if (matches) {
      return {
        codepoint: (matches[1] ? parseInt(matches[1], 16) : codepoint++),
        name: path.basename(matches[2]),
        stream: fs.createReadStream(file)
      };
    }

    return false;
  }));

  var fontStream = svgicons2svgfont(options.glyphs, _.extend(options, {
    log: function () {},
    error: function () {}
  }));

  var tempStream = temp.createWriteStream();

  fontStream
    .pipe(tempStream)
    .on('finish', function () {
      if (_.contains(options.types, 'svg')) {
        var svgDestPath = path.join(process.cwd(), options.dest, options.fontName + '.svg');

        fs.createFileSync(svgDestPath);
        fs.writeFileSync(svgDestPath, fs.readFileSync(tempStream.path));

        options.fontFaceURLS.svg = path.join(options.fontFaceBaseURL, options.fontName + '.svg');
      }

      if (done && _.isFunction (done)) {
        done(tempStream.path);
      }
    });
};

var generateTTFFont = function (svgFontPath, options, done) {
  var font = svg2ttf(fs.readFileSync(svgFontPath, { encoding: 'utf8' }), {});

  font = new Buffer(font.buffer);

  var tempFile = temp.openSync(options.fontName + '-ttf');
  fs.writeFileSync(tempFile.path, font);

  if (_.contains(options.types, 'ttf')) {
    var ttfDestPath = path.join(process.cwd(), options.dest, options.fontName + '.ttf');

    fs.createFileSync(ttfDestPath);
    fs.writeFileSync(ttfDestPath, font);

    options.fontFaceURLS.ttf = path.join(options.fontFaceBaseURL, options.fontName + '.ttf');
  }

  if (done && _.isFunction (done)) {
    done(tempFile.path);
  }
};

var generateEOTFont = function (ttfFontPath, options, done) {
  var ttf = new Uint8Array(fs.readFileSync(ttfFontPath));
  var font = new Buffer(ttf2eot(ttf).buffer);

  var tempFile = temp.openSync(options.fontName + '-eot');
  fs.writeFileSync(tempFile.path, font);

  var eotDestPath = path.join(process.cwd(), options.dest, options.fontName + '.eot');

  fs.createFileSync(eotDestPath);
  fs.writeFileSync(eotDestPath, font);

  options.fontFaceURLS.eot = path.join(options.fontFaceBaseURL, options.fontName + '.eot');

  if (done && _.isFunction (done)) {
    done(tempFile.path);
  }
};

var generateWoffFont = function (ttfFontPath, options, done) {
  var ttf = new Uint8Array(fs.readFileSync(ttfFontPath));
  var font = new Buffer(ttf2woff(ttf).buffer);

  var tempFile = temp.openSync(options.fontName + '-woff');
  fs.writeFileSync(tempFile.path, font);

  var eotDestPath = path.join(process.cwd(), options.dest, options.fontName + '.woff');

  fs.createFileSync(eotDestPath);
  fs.writeFileSync(eotDestPath, font);

  options.fontFaceURLS.woff = path.join(options.fontFaceBaseURL, options.fontName + '.woff');

  if (done && _.isFunction (done)) {
    done(tempFile.path);
  }
};

var generateStylesheet = function (compileStep, options) {
  var template = fs.readFileSync(path.join(process.cwd(), options.stylesheetTemplatePath), 'utf8');
  var glyphCodepointMap = {};
  var fontSrcs = [];

  _.each(options.glyphs, function (glyph) {
    glyphCodepointMap[glyph.name] = glyph.codepoint.toString(16);
  });

  if (_.contains(options.types, 'eot')) {
    fontSrcs.push(getFontSrcURL({
      baseURL: options.fontFaceBaseURL,
      fontName: options.fontName,
      extension: '.eot'
    }));
  }

  var srcs = [];
  _.each(options.types, function (type) {
    if (type === 'svg') {
      srcs.push(getFontSrcURL({
        baseURL: options.fontFaceBaseURL,
        fontName: options.fontName,
        extension: '.svg#' + options.fontName,
        format: 'svg'
      }));
    } else if (type === 'ttf') {
      srcs.push(getFontSrcURL({
        baseURL: options.fontFaceBaseURL,
        fontName: options.fontName,
        extension: '.ttf',
        format: 'truetype'
      }));
    } else if (type === 'eot') {
      srcs.push(getFontSrcURL({
        baseURL: options.fontFaceBaseURL,
        fontName: options.fontName,
        extension: '.eot?#iefix',
        format: 'embedded-opentype'
      }));
    } else if (type === 'woff') {
      srcs.push(getFontSrcURL({
        baseURL: options.fontFaceBaseURL,
        fontName: options.fontName,
        extension: '.woff',
        format: 'woff'
      }));
    }
  });
  fontSrcs.push(srcs.join(', '));

  var data = _.template(template, {
    glyphCodepointMap: glyphCodepointMap,
    fontName: options.fontName,
    fontFaceBaseURL: options.fontFaceBaseURL,
    types: options.types,
    fontSrcs: fontSrcs
  });

  compileStep.addStylesheet({
    path: path.join('client', options.fontName) + '.css',
    data: data
  });
};

var getFontSrcURL = function (o) {
  var parts = ['url("', o.baseURL, '/', o.fontName, o.extension, '")'];

  if (_.isString(o.format) && o.format.length) {
    parts = parts.concat([' format("', o.format, '")']);
  }

  return parts.join('');
};

var getFiles = function (srcPaths) {
  if (_.isString(srcPaths))
    srcPaths = [srcPaths];

  var matches = _.map(srcPaths, function (srcPath) {
    srcPath = path.join(process.cwd(), srcPath);

    if (! fs.existsSync(srcPath))
      return false;

    return fs.readdirSync(srcPath)
      .map(function (file) {
        if (path.extname(file) === '.svg')
          return path.join(srcPath, file);

        return false;
      });
  });

  return _.uniq(_.compact(_.flatten(matches)));
};

var loadJSONFile = function (filePath) {
  var content = fs.readFileSync(filePath);

  try {
    return JSON.parse(content);
  }
  catch (e) {
    console.log('Error: failed to parse ', filePath, ' as JSON');

    return {};
  }
};
