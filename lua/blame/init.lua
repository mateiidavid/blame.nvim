local M = {}

local gitComm = 'git --no-pager blame '
local blameArg = '--line-porcelain -L '

local function blame_output(filename, cursor)
  local args = blameArg .. cursor .. ',+1 -- ' .. filename
  local comm = gitComm .. args
  print(comm)
end

M.blame = function()
  -- Get cursor from current window, we only care about the row
  local cursor = vim.api.nvim_win_get_cursor(0)[1]
  local filename = vim.api.nvim_buf_get_name(0)
  print('Hello', blame_output(filename, cursor))
end

return M
