# meteor-iconfont


Generate an icon webfont from SVG files, á la [grunt-webfont](https://github.com/sapegin/grunt-webfont). No _fontforge_ support.

## Options

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

#### fontHeight

Type: `number` Default: `512`

The height of the outputed fonts.

#### stylesheetDestBasePath

Type: `string` Default: `client`

Path where the generated stylesheet should be outputed to.

#### stylesheetFilename

Type: `string` Default: the fontName value plus `.css`

The filename of the genetated stylesheet.

#### stylesheetTemplate

Type: `string` Default: path to a bundled template file

The path to a Lodash template

#### stylesheets

Type: `object` Default: null

An object that defined which files to generate and with what templates. If specified, `stylesheetFilename` and `stylesheetTemplate` are ignored.

Example for a possible usecase where you want the icons `content` value to be specified in a SASS map, and to access those variables in the icons selectors:

```
{
	'_icon-classes.scss': 'private/icons-templatates/classes.tpl',
	'_icon-variables.scss': 'private/icons-templatates/variables.tpl'
}
```

This would create `_icon-classes.scss` and `_icon-variables.scss` at `stylesheetDestBasePath` with the contents of the respective compiled template.


`_icon-variables.scss`

```
$icons: (
  my-icon '\e001',
  my-other-icon '\e002',
);
```

`_icon-classes.scss`

```
.my-icon {
	content: map-get($icons, my-icon);
}

.my-other-icon {
	content: map-get($icons, my-other-icon);
}
```

`some-file.scss`

```
.thing:after {
	font-family: icons;
	content: map-get($icons, my-icon);
}
```

#### descent

Type: `number` Default: `64`

The font descent. Usefull to fix the font baseline.

#### normalize

Type: `boolean` Default: `true`

Normalize icons by scaling them to the `fontHeight` value.


## To do:

* [ ] Allow generating more that one font
* [x] Output to other stylesheet formats (scss, less, etc.)
* [x] Don't regenerate unless needed

## License

The MIT License, see the included License.txt file.
