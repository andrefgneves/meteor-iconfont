# meteor-iconfont


Generate an icon webfont from SVG files, á la [grunt-webfont](https://github.com/sapegin/grunt-webfont). No _fontforge_ support.

## Configuration

Configure the package by creating an `iconfont.json` file at the project's root and set any of the following properties:

#### src

Type: `string|array` Default: `svgs`

List of paths with the SVGs to convert.

#### dest

Type: `string` Default: `public/fonts/icons`

Path where the generated font files should be created. This sould be inside meteor's public folder.

#### fontName

Type: `string` Default: `icons`

The CSS font-family name. Also used for the the fonts filename (icons.ttf, icons.eot, etc.).

#### fontFaceBaseURL

Type: `string` Default: `/fonts/icons`

The prefix for the font-face URLs. This should be the `dest` value without `public/`.

#### classPrefix

Type: `string` Default: `icon-`

The prefix for the icons classes. Ex: `icon-`arrow-up.

#### types

Type: `array` Default: `[ 'svg', 'ttf', 'eot', 'woff' ]`

The types of fonts to generate.

#### stylesheetTemplatePath

Type: `string` Default: `packages/iconfont/plugin/stylesheet.tpl`

The path to the stylesheet template. This file must have a [Lodash's template](http://lodash.com/docs#template) compatible syntax.

#### fontHeight

Type: `number` Default: `512`

The height of the outputed fonts.

#### cssDestBasePath

Type: `string` Default: `client`

Path where the generated CSS should be outputed.


#### descent

Type: `number` Default: `64`

The font descent. Usefull to fix the font baseline.

#### normalize

Type: `boolean` Default: `true`

Normalize icons by scaling them to the `fontHeight` value.


## ToDo:

* Allow generating more that one font
* Output to other stylesheet formats (scss, less, etc.)
* Don't regenerate unless needed
* ...

## License

The MIT License, see the included License.txt file.