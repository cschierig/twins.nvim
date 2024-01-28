local util = require('twins.util')

local M = {}

-- TODO: disallow lhs duplication
local default_config = {
  pairs = {
    backticks = { '`' },
    curly = { '{', '}' },
    dquotes = { '"' },
    parens = { '(', ')' },
    square = { '[', ']' },
    squotes = { "'" },
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
    java = 'c',
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
      { '~' },
    },
    markdown_inline = 'markdown',
    rust = {
      'parens',
      'curly',
      'square',
      'squotes',
      'dquotes',
    },
    toml = {
      'square',
      'squotes',
      'dquotes',
    },
  },
  keys = {
    tabout = true,
    delete_pair = true,
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

      -- check that the next character isn't alphanumeric
      if vim.api.nvim_buf_get_text(0, row, column, row, column + 1, {})[1]:match('%w') ~= nil then
        return
      end

      vim.api.nvim_buf_set_text(0, row, column, row, column, { rhs })
    end)
  end
end

--- Tries to move past the rhs.
--- @param lang string The language at the position where the text is inserted.
--- @param rhs string The character which is to be skipped.
--- @return boolean value true if the function skipped a rhs, false otherwise.
---@overload fun(lang: string): boolean
local function try_skip_rhs(lang, rhs)
  local position = vim.api.nvim_win_get_cursor(0)
  local row = position[1] - 1
  local column = position[2]

  local next_char = vim.api.nvim_buf_get_text(0, row, column, row, column + 1, {})[1]
  rhs = rhs or next_char

  local twins = lang
  repeat
    twins = lang_map_rhs[twins] or lang_map_rhs['*']
  until type(twins) == 'table'

  if next_char == rhs and twins[rhs] then
    vim.v.char = ''
    vim.schedule(function()
      vim.api.nvim_win_set_cursor(0, { row + 1, column + 1 })
    end)
    return true
  end
  return false
end

local function try_delete_rhs(lang)
  local position = vim.api.nvim_win_get_cursor(0)
  local row = position[1] - 1
  local column = position[2]

  local left_pos = math.max(column - 1, 0)

  local left_char = vim.api.nvim_buf_get_text(0, row, left_pos, row, column, {})[1]
  local right_char = vim.api.nvim_buf_get_text(0, row, column, row, column + 1, {})[1]

  local twins = lang
  repeat
    twins = lang_map_lhs[twins] or lang_map_rhs['*']
  until type(twins) == 'table'

  if twins[left_char] == right_char then
    return '<backspace><delete>'
  else
    return '<backspace>'
  end
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

local function setup_mappings()
  -- tabout
  if config.keys.tabout then
    vim.keymap.set('i', '<tab>', function()
      local lang = util.language_at_cursor()
      if try_skip_rhs(lang) then
        return
      else
        return '<tab>'
      end
    end, { expr = true, silent = true })
  end
  -- delete pairs
  if config.keys.delete_pair then
    vim.keymap.set('i', '<backspace>', function()
      local lang = util.language_at_cursor()
      return try_delete_rhs(lang)
    end, { expr = true, silent = true })
  end
end

function M.setup(cfg)
  local async
  config = vim.tbl_deep_extend('force', default_config, cfg)
  async = vim.loop.new_async(function()
    setup_cache()
    async:close()
  end)
  async:send()
  setup_autocommands()
  setup_mappings()
end

return M
