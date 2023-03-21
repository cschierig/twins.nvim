# Twins.nvim

**Twins.nvim** is a simple lua plugin which automatically closes braces and other pairs based on the file type.
The plugin is currently in early development and isn't very smart about inserting and deleting (yet).

## Features

- Automatically closes braces and other pairs when left side is inserted.
- Move past right side of pair when entering it.
- Language-dependent auto-closing pairs
- Supports treesitter injected languages

## Not yet implemented

- dot repeat
- nested languages
- Treesitter support to detect if a pair should be closed.
- multiple character pairs (`function()...end`)
- deleting pair after inserting should delete both tokens.

## Installation

To install the plugin, use your favourite plugin manager to clone the repo
and proceed by following the instructions in the [configuration](#Configuration) section.

### Dependencies

- Neovim >= 0.8.0
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter/).

### Packer.nvim
```lua
use {
  'CozyPenguin/twins.nvim',
  requires = { 'nvim-treesitter/nvim-treesitter' },
  event = 'BufEnter',
  config = function()
    require('twins').setup()
  end
}
```

### Lazy.nvim
```lua
{
  'CozyPenguin/twins.nvim',
  dependencies = { 'nvim-treesitter/nvim-treesitter' },
  event = 'BufEnter',
  config = true,
}
```

## Configuration

> **Note** Twins doesn't have proper error handling yet, so errors in the configuration may result in unhelpful stacktraces.

The configuration is a table which is passed as the first argument to the `setup()` function.
It has the following structure:
```lua
{
  pairs = {
    -- name = { 'left', 'right' }
    parens = { '(', ')' },
    curly = { '{', '}' },
    square = { '[', ']' },
    dquotes = { '"' } -- optional syntax if the left and the right tokens are the same
  },
  languages = {
    -- pairs which are used for all languages
    ['*'] = {
      -- list of pairs
      'parens'
    },
    c = {
      -- additional pairs used by c
      'curly',
      'square'
    },
    c_sharp = 'c', -- define c_sharp as an alias for c, making both languages use the same pairs
    markdown = {
      { '_', '_' } -- pairs can also be specified in the language configuration
    },
  }
}
```

The default configuration can be at the beginning of [this file](./lua/twins/init.lua).

## Similar (better) plugins

- [auto-pairs](https://github.com/jiangmiao/auto-pairs)
