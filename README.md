# Twins.nvim

**Twins.nvim** is a simple plugin which automatically closes braces and other pairs based on the file type.
The plugin is currently in early development and isn't very smart about inserting and deleting (yet).

## Features

- automatically close braces and other pairs when left side is inserted.
- Filetype dependend 

## Not yet implemented

- dot repeat
- Treesitter support to detect if a pair should be closed.
- nested language blocks with treesitter.
- deleting pair after inserting deleting both tokens.

## Installation

To install the plugin, use your favourite plugin manager to clone the repo
and proceed by following the instructions in the [#Configuration] section.

The plugin depends on [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter/).
Currently it is technically not needed, but I plan on using it and adding it as a dependency later on would break
exisiting configurations.

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
  },
  languages = {
    -- pairs which are used for all languages
    ['*'] = {
      -- list of pairs
      'parens'
    },
    lua = {
      -- additional pairs used by lua
      'curly',
      'square'
    }
  }
}
```

## Similar (better) plugins

- [auto-pairs](https://github.com/jiangmiao/auto-pairs)
