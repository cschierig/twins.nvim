local api = vim.api
local parsers = require('nvim-treesitter.parsers')

M = {}

function M.language_at_cursor()
  -- inspired by JoosepAlviste/nvim-ts-context-commentstring
  if not parsers.has_parser() then
    return parsers.get_buf_lang()
  end

  local cursor_pos = api.nvim_win_get_cursor(0)
  local parser = parsers.get_parser()
  local tree = parser:language_for_range { cursor_pos[1], cursor_pos[2], cursor_pos[1], cursor_pos[2] }
  return tree:lang()
end

return M
