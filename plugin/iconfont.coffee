_                = Npm.require 'lodash'
fs               = Npm.require 'fs-extra'
path             = Npm.require 'path'
temp             = Npm.require('temp').track()
md5              = Npm.require 'MD5'
svg2ttf          = Npm.require 'svg2ttf'
ttf2eot          = Npm.require 'ttf2eot'
ttf2woff         = Npm.require 'ttf2woff'
svgicons2svgfont = Npm.require 'svgicons2svgfont'
optionsFile      = path.join process.cwd(), 'iconfont.json'
cacheFilePath    = path.join process.cwd(), '.meteor/iconfont.cache'

handler = (compileStep) ->
    options = if fs.existsSync optionsFile then loadJSONFile optionsFile  else {}

    compileStep.inputPath = 'iconfont.json'

    options = _.extend
        src:                    'svgs'
        dest:                   'public/fonts/icons'
        fontFaceBaseURL:        '/fonts/icons'
        fontName:               'icons'
        fontHeight:             512
        stylesheetsDestBasePath: 'client'
        descent:                64
        normalize:              true
        classPrefix:            'icon-'
        stylesheetFilename:     null
        stylesheetTemplate:     '.meteor/local/isopacks/andrefgneves_iconfont/os/packages/andrefgneves_iconfont/plugin/stylesheet.tpl'
        types: [
            'svg'
            'ttf'
            'eot'
            'woff'
        ]
    , options

    return if not options.types or not options.types.length

    options.files = getFiles options.src

    if didInvalidateCache options
        console.log '\n[iconfont] generating'

        options.fontFaceURLS = {}
        options.types = _.map options.types, (type) ->
            return type.toLowerCase()

        generateFonts compileStep, options

didInvalidateCache = (options) ->
    didInvalidate    = false
    newCacheChecksum = generateCacheChecksum(options)

    if not fs.existsSync cacheFilePath
        didInvalidate = true
    else
        oldCacheChecksum = fs.readFileSync cacheFilePath, encoding: 'utf8'
        didInvalidate    = newCacheChecksum != oldCacheChecksum

    fs.writeFileSync cacheFilePath, newCacheChecksum if didInvalidate

    didInvalidate

generateCacheChecksum = (options) ->
    checksums        = []
    settingsChecksum = md5 fs.readFileSync(optionsFile)

    _.each options.files, (file) ->
        checksum = md5 path.basename(file) + fs.readFileSync(file)

        checksums.push checksum

    md5 settingsChecksum + JSON.stringify(checksums)

generateFonts = (compileStep, options) ->
    # Always generate the SVG font as it is required to generate the TTF,
    # which in turn is used to generate the EOT and WOFF
    generateSVGFont options.files, options, (svgFontPath) ->
        if _.intersection(options.types, ['ttf', 'eot', 'woff']).length
            generateTTFFont svgFontPath, options, (ttfFontPath) ->
                if _.contains options.types, 'eot'
                    generateEOTFont ttfFontPath, options

                if _.contains options.types, 'woff'
                    generateWoffFont ttfFontPath, options

        generateStylesheets compileStep, options

generateSVGFont = (files, options, done) ->
    codepoint = 0xE001

    options.glyphs = _.compact _.map(files, (file) ->
        matches = file.match /^(?:u([0-9a-f]{4})\-)?(.*).svg$/i

        if matches
            return {
                name:      path.basename(matches[2]).toLowerCase().replace /\s/g, '-'
                stream:    fs.createReadStream file
                codepoint: if matches[1] then parseInt(matches[1], 16) else codepoint++
            }

        false
    )

    fontStream = svgicons2svgfont options.glyphs, _.extend(options,
        log:   ->
        error: ->
    )

    tempStream = temp.createWriteStream()

    fontStream
        .pipe tempStream
        .on 'finish', ->
            if _.contains(options.types, 'svg')
                svgDestPath = path.join process.cwd(), options.dest, options.fontName + '.svg'

                fs.createFileSync svgDestPath
                fs.writeFileSync svgDestPath, fs.readFileSync(tempStream.path)

                options.fontFaceURLS.svg = path.join options.fontFaceBaseURL, options.fontName + '.svg'

            done tempStream.path if _.isFunction done

generateTTFFont = (svgFontPath, options, done) ->
    font     = svg2ttf fs.readFileSync(svgFontPath, encoding: 'utf8'), {}
    font     = new Buffer font.buffer
    tempFile = temp.openSync(options.fontName + '-ttf')

    fs.writeFileSync tempFile.path, font

    if _.contains options.types, 'ttf'
        ttfDestPath = path.join process.cwd(), options.dest, options.fontName + '.ttf'

        fs.createFileSync ttfDestPath
        fs.writeFileSync ttfDestPath, font

        options.fontFaceURLS.ttf = path.join options.fontFaceBaseURL, options.fontName + '.ttf'

    done tempFile.path if _.isFunction (done)

generateEOTFont = (ttfFontPath, options, done) ->
    ttf      = new Uint8Array fs.readFileSync(ttfFontPath)
    font     = new Buffer ttf2eot(ttf).buffer
    tempFile = temp.openSync options.fontName + '-eot'

    fs.writeFileSync tempFile.path, font

    eotDestPath = path.join process.cwd(), options.dest, options.fontName + '.eot'

    fs.createFileSync eotDestPath
    fs.writeFileSync eotDestPath, font

    options.fontFaceURLS.eot = path.join options.fontFaceBaseURL, options.fontName + '.eot'

    done tempFile.path if _.isFunction done

generateWoffFont = (ttfFontPath, options, done) ->
    ttf      = new Uint8Array fs.readFileSync(ttfFontPath)
    font     = new Buffer ttf2woff(ttf).buffer
    tempFile = temp.openSync options.fontName + '-woff'

    fs.writeFileSync tempFile.path, font

    eotDestPath = path.join process.cwd(), options.dest, options.fontName + '.woff'

    fs.createFileSync eotDestPath
    fs.writeFileSync eotDestPath, font

    options.fontFaceURLS.woff = path.join options.fontFaceBaseURL, options.fontName + '.woff'

    done tempFile.path if _.isFunction done

generateStylesheets = (compileStep, options) ->
    fontSrcs          = []
    glyphCodepointMap = {}

    classNames = _.map options.glyphs, (glyph) ->
        return '.' + options.classPrefix + glyph.name.replace /\s+/g, '-'

    _.each options.glyphs, (glyph) ->
        glyphCodepointMap[glyph.name] = glyph.codepoint.toString 16

    if _.contains options.types, 'eot'
        fontSrcs.push getFontSrcURL
            baseURL:   options.fontFaceBaseURL
            fontName:  options.fontName
            extension: '.eot'

    srcs = []

    _.each options.types, (type) ->
        switch type
            when 'svg'
                srcs.push getFontSrcURL
                    baseURL:   options.fontFaceBaseURL
                    fontName:  options.fontName
                    extension: '.svg#' + options.fontName
                    format:    'svg'

            when 'ttf'
                srcs.push getFontSrcURL
                    baseURL:   options.fontFaceBaseURL
                    fontName:  options.fontName
                    extension: '.ttf'
                    format:    'truetype'

            when 'eot'
                srcs.push getFontSrcURL
                    baseURL:   options.fontFaceBaseURL
                    fontName:  options.fontName
                    extension: '.eot?#iefix'
                    format:    'embedded-opentype'

            when 'woff'
                srcs.push getFontSrcURL
                    baseURL:   options.fontFaceBaseURL
                    fontName:  options.fontName
                    extension: '.woff'
                    format:    'woff'

    fontSrcs.push srcs.join ', '

    if not options.stylesheets
        stylesheets = {}

        options.stylesheetFilename = options.stylesheetFilename or (options.fontName + '.css')

        stylesheets[options.stylesheetFilename] = options.stylesheetTemplate
    else
        stylesheets = options.stylesheets

    for fileName, filePath of stylesheets
        templatePath = path.join process.cwd(), filePath

        if not fs.existsSync templatePath
            console.log "\n[iconfont] template file not found at #{templatePath}"
            continue

        template = fs.readFileSync templatePath, 'utf8'

        data = _.template template,
            glyphCodepointMap: glyphCodepointMap
            classPrefix:       options.classPrefix
            classNames:        classNames.join(', ')
            fontName:          options.fontName
            fontFaceBaseURL:   options.fontFaceBaseURL
            types:             options.types
            fontSrcs:          fontSrcs

        stylesheetDestPath = path.join options.stylesheetsDestBasePath, fileName

        fs.ensureFileSync stylesheetDestPath
        fs.writeFileSync stylesheetDestPath, data

        if path.extname(stylesheetDestPath) is '.css'
            compileStep.addStylesheet
                path: stylesheetDestPath
                data: data

getFontSrcURL = (options) ->
    parts = ['url("', options.baseURL, '/', options.fontName, options.extension, '")']

    if _.isString options.format and options.format.length
        parts = parts.concat [' format("', options.format, '")']

    parts.join ''

getFiles = (srcPaths) ->
    srcPaths = [srcPaths] if _.isString(srcPaths)

    matches = _.map srcPaths, (srcPath) ->
        srcPath = path.join(process.cwd(), srcPath)

        return false if not fs.existsSync srcPath

        fs
            .readdirSync srcPath
            .map (file) ->
                return path.join srcPath, file if path.extname(file) is '.svg'

                false

    _.uniq _.compact _.flatten matches

loadJSONFile = (filePath) ->
    content = fs.readFileSync(filePath)

    try
        return JSON.parse content
    catch error
        console.log 'Error: failed to parse ', filePath, ' as JSON'

        {}

Plugin.registerSourceHandler 'iconfont.json', archMatching: 'web', handler
Plugin.registerSourceHandler 'svg', archMatching: 'web', handler
