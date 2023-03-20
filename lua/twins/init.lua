local vim = vim
local util = require('twins.util')

local M = {}

-- TODO: disallow lhs duplication
local default_config = {
  pairs = {
    parens = { '(', ')' },
    curly = { '{', '}' },
    square = { '[', ']' },
    squotes = { "'" },
    dquotes = { '"' },
    backticks = { '`' },
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
    c_sharp = 'c',
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
      'backticks',
      { '*' },
      { '_' },
    },
    markdown_inline = 'markdown',
    rust = {
      'parens',
      'curly',
      'square',
      'squotes',
      'dquotes',
    },
  },
}

local config = {}

--- maps twin lhs to rhs for each language
local lang_map_lhs = {}
local lang_map_rhs = {}

local function try_insert_lhs(lang, lhs)
  local twins = lang
  repeat
    twins = lang_map_lhs[twins] or lang_map_lhs['*']
  until type(twins) == 'table'
  local rhs = twins[lhs]

  if rhs then
    vim.schedule(function()
      local position = vim.api.nvim_win_get_cursor(0)
      local row = position[1] - 1
      local column = position[2]
      vim.api.nvim_buf_set_text(0, row, column, row, column, { rhs })
    end)
  end
end

local function try_skip_rhs(lang, rhs)
  local position = vim.api.nvim_win_get_cursor(0)
  local row = position[1] - 1
  local column = position[2]

  local next_char = vim.api.nvim_buf_get_text(0, row, column, row, column + 1, {})[1]
  local twins = lang
  repeat
    twins = lang_map_lhs[twins] or lang_map_lhs['*']
  until type(twins) == 'table'

  if next_char == rhs and twins[rhs] then
    vim.v.char = ''
    vim.api.nvim_win_set_cursor(0, { row + 1, column + 1 })
    return true
  end
  return false
end

local function on_insert()
  local lang = util.language_at_cursor()
  local insert = vim.v.char

  if try_skip_rhs(lang, insert) then
    return
  end
  try_insert_lhs(lang, insert)
end

local function create_lang_maps(lang)
  local lang_table_lhs = {}
  local lang_table_rhs = {}
  if lang ~= '*' then
    lang_table_lhs = vim.deepcopy(lang_map_lhs['*'])
    lang_table_rhs = vim.deepcopy(lang_map_rhs['*'])
  end

  local lang_twins = config.languages[lang]

  if type(lang_twins) == 'table' then
    for _, twin_key in pairs(config.languages[lang]) do
      local twin
      if type(twin_key) == 'table' then
        twin = twin_key
      else
        twin = config.pairs[twin_key]
      end
      local lhs = twin[1]
      local rhs = twin[2] or twin[1]
      lang_table_lhs[lhs] = rhs
      lang_table_rhs[rhs] = lhs
    end
  else
    -- use alias
    lang_table_lhs = lang_twins
    lang_table_rhs = lang_twins
  end

  lang_map_lhs[lang] = lang_table_lhs
  lang_map_rhs[lang] = lang_table_rhs
end

--- computes the lang_pairs table
local function setup_table()
  create_lang_maps('*')
  for lang, _ in pairs(config.languages) do
    create_lang_maps(lang)
  end
end

local group = vim.api.nvim_create_augroup('Twins', { clear = true })

local function setup_autocommands()
  vim.api.nvim_create_autocmd('InsertCharPre', {
    group = group,
    callback = on_insert,
  })
end

function M.setup(cfg)
  config = vim.tbl_deep_extend('force', default_config, cfg)
  setup_table()
  setup_autocommands()
end

return M
