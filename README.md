# kak-jsts

This project extends JavaScript and TypeScript support of [Kakoune](https://github.com/mawww/kakoune).
It provides additional commands for linting and formatting of your files.
All formatting and linting will be done according to your local project preferences, e.g. in .eslintrc.js.

It does not provide additional language features.
For that, check the [Kakoune Language Server Protocol Client](https://github.com/ul/kak-lsp) instead.

**Make sure to check the [configuration](#configuration) below.**

## Installation

### Prerequisites

kak-jsts has two dependencies that must be available on your machine:

1. [eslint-formatter-kakoune](https://github.com/Delapouite/eslint-formatter-kakoune) (e.g. `npm i -g eslint-formatter-kakoune`)
2. [jq](https://github.com/stedolan/jq) (e.g. `brew install jq`)

eslint-formatter-kakoune is required to enable Kakoune to interpret eslint's output.

jq is required to parse eslint's output of the JSON formatter.

### With [plug.kak](https://github.com/andreyorst/plug.kak)

Add this to your `kakrc`:

```sh
plug "schemar/kak-jsts"
```

Restart Kakoune or re-source your `kakrc` and call the `plug-install` command.

### Without plugin manager

Clone this repository to your `autoload` directory, or source the `rc/jsts.kak` file
from your `kakrc`.

## Usage

kak-jsts provides three new commands:

1. `format-eslint`
2. `format-prettier`
3. `format-tslint`

`format-eslint` and `format-pretter` will format your buffer without touching the disk.
Due to a limitation in `tslint`, your buffer will be written, formatted on disk, and then reloaded.

Furthermore, kak-jsts sets Kakoune's [lint](https://github.com/mawww/kakoune/blob/master/rc/tools/lint.kak)
command to use eslint for JavaScript and TypeScript files.

All formatting and linting will be done according to your local project preferences, e.g. in `.eslintrc.js`.
Kakoune must run in the root of the project for that to work.

## Configuration

### Path to `node_modules`

kak-jsts assumes your global node modules to be installed at `/usr/local/lib/node_modules/`.
If this is not the case, you must overwrite the `lintcmd`.
Due to how [`lint.kak`](https://github.com/mawww/kakoune/blob/master/rc/tools/lint.kak) is implemented,
it doesn't allow the path to be set via a Kakoune option.

As an example, if your global node_modules path is `$HOME/.npm-global/lib/node_modules/`,
you would need to set the `lintcmd` like so:

```kak
plug "schemar/kak-jsts" config %{
    hook global WinSetOption filetype=(javascript|typescript) %{
        # Replace path below with your path to your global node_modules:
        set window lintcmd 'run() { cat "$1" | npx eslint -f ~/.npm-global/lib/node_modules/eslint-formatter-kakoune/index.js --stdin --stdin-filename "$kak_buffile";} && run '
    }
}
```

### Example Mapping

```kak
plug "schemar/kak-jsts" config %{
    hook global WinSetOption filetype=(javascript|typescript) %{
        map window user l -docstring 'lint' ': lint<ret>'
        map window user f -docstring 'format' ': format-eslint<ret>'
    }
}
```

If you use different formatters in different projects, you can source a local `kakrc` where you overwrite the formatting command, for example to be `format-prettier`.
See [IDE on the Kakoune Wiki](https://github.com/mawww/kakoune/wiki/IDE#read-local-kakrc-file) for more info about that.
