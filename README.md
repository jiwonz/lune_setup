# lune_setup
`lune setup` command written in `luau` but for newer `luau-lsp`

## What Is It?
- `lune_setup` is a simple lune script written in luau that setups lune development environment especially with `luau-lsp`.

## Features
- Installs `typedefs` based on current lune's version and places them based on the environment variable(`HOME`) or user's home directory.
- Sets up `.luaurc` aliases to develop `lune` properly with `luau-lsp`. (Setting up `.vscode/settings.json` is now deprecated for `luau-lsp`)

## How To Use
It is generally recommended to use with `pesde`

Executing directly without setting up the dependencies:
```sh
pesde x jiwonz/lune_setup
```

Adding as a dev dependency & run the binary:
```sh
pesde add --dev jiwonz/lune_setup -t lune

pesde install

lune_setup
```

Or, you can just download the script & simply run through `lune` without `pesde`:
```sh
lune run lune_setup
```
