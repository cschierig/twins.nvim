local vim = vim
local M = {}

local default_config = {
  pairs = {
    parens = { '(', ')' },
    curly = { '{', '}' },
    square = { '[', ']' },
    squotes = { "'" },
    dquotes = { '"' },
  },
  languages = {
    ['*'] = {
      'parens',
      'dquotes',
    },
    c = {
      'parens',
      'curly',
      'square',
      'squotes',
      'dquotes',
    },
    lua = {
      'parens',
      'curly',
      'square',
      'squotes',
      'dquotes',
    },
    markdown = {
      'parens',
      'square',
      'dquotes',
      -- { '*', '*' },
    },
    rust = {
      'parens',
      'curly',
      'square',
      'squotes',
      'dquotes',
    },
  },
}

local insert_twin = function(lhs, rhs)
  local position = vim.api.nvim_win_get_cursor(0)
  local row = position[1] - 1
  local column = position[2]

  vim.api.nvim_buf_set_text(0, row, column, row, column, { rhs })
  vim.api.nvim_buf_set_text(0, row, column, row, column, { lhs })

  vim.api.nvim_win_set_cursor(0, { position[1], column + lhs:len() })
end

local setup_keybindings = function(language_pairs, twins)
  for _, pair in pairs(language_pairs) do
    local twin = twins[pair]
    vim.keymap.set('i', twin[1], function()
      insert_twin(twin[1], twin[2] or twin[1])
    end, {
      buffer = 0,
    })
  end
end

local group = vim.api.nvim_create_augroup('Twins', { clear = true })

local setup_autocommands = function(config)
  for language, twins in pairs(config.languages) do
    if language == '*' then
      vim.api.nvim_create_autocmd('FileType', {
        group = group,
        callback = function()
          setup_keybindings(twins, config.pairs)
        end,
      })
    end
    vim.api.nvim_create_autocmd('FileType', {
      pattern = language,
      group = group,
      callback = function()
        setup_keybindings(twins, config.pairs)
      end,
    })
  end
end

---@param config table
function M.setup(config)
  config = vim.tbl_deep_extend('force', default_config, config)
  setup_autocommands(config)
end

return M
