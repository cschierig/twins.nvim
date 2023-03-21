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

-- caches, precomputed on startup
local lang_map_lhs = {}
local lang_map_rhs = {}
local trigger_chars = {}

--- Tries to insert the corresponding pair for the given lhs.
--- @param lang string The language at the position where the text is inserted.
--- @param lhs string The character which is to be inserted.
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

--- Tries to move past the rhs.
--- @param lang string The language at the position where the text is inserted.
--- @param rhs string The character which is to be skipped.
local function try_skip_rhs(lang, rhs)
  local position = vim.api.nvim_win_get_cursor(0)
  local row = position[1] - 1
  local column = position[2]

  local next_char = vim.api.nvim_buf_get_text(0, row, column, row, column + 1, {})[1]
  local twins = lang
  repeat
    twins = lang_map_rhs[twins] or lang_map_rhs['*']
  until type(twins) == 'table'

  if next_char == rhs and twins[rhs] then
    vim.v.char = ''
    vim.api.nvim_win_set_cursor(0, { row + 1, column + 1 })
    return true
  end
  return false
end

local function on_insert()
  local insert = vim.v.char
  -- return if the character isn't a trigger character.
  if not trigger_chars[insert] then
    return
  end
  local lang = util.language_at_cursor()

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

      trigger_chars[lhs] = {}
      trigger_chars[rhs] = {}

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

--- Builds the different cache tables from the configuration.
local function setup_cache()
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
  local async
  async = vim.loop.new_async(function()
    config = vim.tbl_deep_extend('force', default_config, cfg)
    setup_cache()
    async:close()
  end)
  async:send()
  setup_autocommands()
end

return M
